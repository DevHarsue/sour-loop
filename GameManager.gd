extends Node

enum GameState { WAITING_FOR_FRUIT, RECORDING_ACTION }

@export var ghost_scene: PackedScene
@export var spawn_point: Marker2D
@export var ghost_container: Node
@export var timer_label: Label
@export var restart_button: Button
@export var fruit_scene: PackedScene
@export var fruit_spawn_point: Node2D
@export var existing_player: CharacterBody2D

@export var loop_duration: float = 5.0

const MAX_GHOSTS := 1

var current_time: float = 0.0
var recordings_history: Array = [] # Holds Array[Dictionary] segments
var _player: CharacterBody2D
var _state: GameState = GameState.WAITING_FOR_FRUIT
var _loop_start_position: Vector2 = Vector2.ZERO
var _has_loop_start_position: bool = false
var _active_fruit: Area2D
var _fruit_activation_pending: bool = false

func _ready() -> void:
	add_to_group("game_manager")
	_ensure_player_reference()
	start_new_loop()
	setup_restart_button()

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("restart") or Input.is_action_just_pressed("restart"):
		start_new_loop()
		return
	if _state != GameState.RECORDING_ACTION:
		return
	if _player == null:
		return
	current_time += delta
	update_timer_label()
	if current_time >= loop_duration:
		restart_loop()

func update_timer_label() -> void:
	if timer_label:
		timer_label.text = "Time: %.2f / %.2f" % [current_time, loop_duration]

func trigger_loop_start(start_position: Vector2) -> void:
	if _state == GameState.RECORDING_ACTION:
		return
	_ensure_player_reference()
	if _player == null:
		return
	_loop_start_position = start_position
	_has_loop_start_position = true
	_state = GameState.RECORDING_ACTION
	current_time = 0.0
	update_timer_label()
	_player.global_position = start_position
	_player.velocity = Vector2.ZERO
	if _player.has_method("start_new_recording"):
		_player.start_new_recording()
	_ensure_fruit_hidden()
	_begin_ghost_replays()

func restart_loop(clear_recordings: bool = false) -> void:
	_ensure_player_reference()
	if _player == null:
		return
	if AudioManager:
		AudioManager.play_reset_sfx()
	var latest_recording: Array[Dictionary] = _player.get_recording()
	var created_ghost := false
	if _state == GameState.RECORDING_ACTION:
		var has_power := false
		if _player.has_method("enable_ghost_power"):
			has_power = bool(_player.get("has_ghost_power"))
		if has_power and latest_recording.is_empty() == false:
			recordings_history.append(latest_recording)
			created_ghost = true
			if recordings_history.size() > MAX_GHOSTS:
				recordings_history.pop_front()
		_log_loop_feedback(created_ghost)
	_state = GameState.WAITING_FOR_FRUIT
	current_time = 0.0
	update_timer_label()
	_restart_player_fruit_state()
	var target_position := _determine_start_position()
	if _player:
		_prepare_player_for_loop(_player, target_position)
		if _player.has_method("start_new_recording"):
			_player.start_new_recording()
	if clear_recordings:
		recordings_history.clear()
		_clear_ghosts()
	else:
		spawn_ghosts()
	_respawn_fruit(false, recordings_history.is_empty())
	connect_level_signals()

func set_player(player_body: CharacterBody2D) -> void:
	existing_player = player_body
	_player = player_body
	_ensure_player_reference()

func _ensure_player_reference() -> void:
	if is_instance_valid(_player):
		return
	if is_instance_valid(existing_player):
		_player = existing_player
		return
	var found := _find_existing_player()
	if found:
		existing_player = found
		_player = found

func _prepare_player_for_loop(player_body: CharacterBody2D, target_position: Vector2) -> void:
	player_body.global_position = target_position
	player_body.velocity = Vector2.ZERO
	player_body.has_ghost_power = false
	if player_body.has_method("reset_fruit"):
		player_body.call_deferred("reset_fruit")

func _find_existing_player() -> CharacterBody2D:
	var players := get_tree().get_nodes_in_group("player")
	for node in players:
		var body := node as CharacterBody2D
		if body:
			return body
	var scene_root := get_tree().current_scene
	if scene_root:
		var found := scene_root.find_child("Player", true, false)
		var body := found as CharacterBody2D
		if body:
			return body
	return null

func _ensure_fruit_hidden() -> void:
	_fruit_activation_pending = false
	_update_active_fruit_reference()
	if not is_instance_valid(_active_fruit):
		return
	var canvas := _active_fruit as CanvasItem
	if canvas:
		canvas.hide()
	_active_fruit.set_deferred("monitoring", false)
	_active_fruit.set_deferred("monitorable", false)
	var collision := _active_fruit.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision:
		collision.set_deferred("disabled", true)

func _activate_fruit_with_delay(delay: float) -> void:
	_update_active_fruit_reference()
	if not is_instance_valid(_active_fruit):
		return
	if delay <= 0.0:
		_activate_fruit_now(true)
		return
	_fruit_activation_pending = true
	var timer := get_tree().create_timer(delay)
	timer.timeout.connect(Callable(self, "_on_fruit_activation_timeout"))

func _on_fruit_activation_timeout() -> void:
	_activate_fruit_now()

func _activate_fruit_now(force: bool = false) -> void:
	_update_active_fruit_reference()
	if not is_instance_valid(_active_fruit):
		_fruit_activation_pending = false
		return
	if not force and _fruit_activation_pending == false:
		return
	_fruit_activation_pending = false
	if _active_fruit.has_method("reset_fruit"):
		_active_fruit.reset_fruit()
	else:
		var canvas := _active_fruit as CanvasItem
		if canvas:
			canvas.show()
		_active_fruit.set_deferred("monitoring", true)
		_active_fruit.set_deferred("monitorable", true)
		var collision := _active_fruit.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if collision:
			collision.set_deferred("disabled", false)

func _on_ghost_finished() -> void:
	_activate_fruit_with_delay(0.5)

func _update_active_fruit_reference() -> void:
	if is_instance_valid(_active_fruit):
		return
	var fruits := get_tree().get_nodes_in_group("fruits")
	for fruit in fruits:
		if is_instance_valid(fruit):
			var candidate := fruit as Area2D
			if candidate:
				_active_fruit = candidate
				return
	_active_fruit = null

func spawn_ghosts() -> void:
	if ghost_container == null or ghost_scene == null:
		return
	_clear_ghosts()
	var last_ghost: CharacterBody2D = null
	for i in range(recordings_history.size()):
		var recording = recordings_history[i]
		var new_ghost := ghost_scene.instantiate()
		var ghost_body := new_ghost as CharacterBody2D
		if ghost_body == null:
			if is_instance_valid(new_ghost):
				new_ghost.queue_free()
			continue
		ghost_container.add_child(ghost_body)
		if ghost_body.has_method("prepare_replay"):
			ghost_body.prepare_replay(recording as Array[Dictionary], i + 1)
		last_ghost = ghost_body
		if ghost_body.has_method("begin_replay"):
			ghost_body.call_deferred("begin_replay")
	if last_ghost and last_ghost.has_signal("replay_finished"):
		var callable := Callable(self, "_on_ghost_finished")
		if last_ghost.is_connected("replay_finished", callable) == false:
			last_ghost.connect("replay_finished", callable)

func start_new_loop() -> void:
	recordings_history.clear()
	_clear_ghosts()
	_has_loop_start_position = false
	_loop_start_position = Vector2.ZERO
	if AudioManager:
		AudioManager.play_reset_sfx()
	_respawn_fruit(true, true)
	_ensure_player_reference()
	if _player == null:
		push_warning("GameManager: No player assigned. Assign one via existing_player export or set_player().")
		return
	var target_position := _determine_start_position()
	_prepare_player_for_loop(_player, target_position)
	_state = GameState.WAITING_FOR_FRUIT
	_loop_start_position = target_position
	current_time = 0.0
	update_timer_label()
	connect_level_signals()

func setup_restart_button() -> void:
	if restart_button == null:
		return
	var restart_callable := Callable(self, "_on_restart_pressed")
	if restart_button.is_connected("pressed", restart_callable) == false:
		restart_button.connect("pressed", restart_callable)

func _on_restart_pressed() -> void:
	start_new_loop()

func _clear_ghosts() -> void:
	if ghost_container == null:
		return
	for ghost in ghost_container.get_children():
		if is_instance_valid(ghost):
			ghost.queue_free()

func _begin_ghost_replays() -> void:
	if ghost_container == null:
		return
	for ghost in ghost_container.get_children():
		if is_instance_valid(ghost) and ghost.has_method("begin_replay"):
			ghost.begin_replay()

func _restart_player_fruit_state() -> void:
	if _player and _player.has_method("reset_fruit"):
		_player.reset_fruit()

func _respawn_fruit(force: bool = false, reactivate: bool = false) -> void:
	var fruits := get_tree().get_nodes_in_group("fruits")
	var target_position := _compute_fruit_spawn_position()
	if force:
		for fruit in fruits:
			if is_instance_valid(fruit):
				fruit.queue_free()
		fruits = []
		_active_fruit = null
	var fruit_node: Area2D = null
	for fruit in fruits:
		if is_instance_valid(fruit):
			fruit_node = fruit as Area2D
			break
	if fruit_node == null:
		if fruit_scene == null:
			return
		var new_fruit := fruit_scene.instantiate()
		add_child(new_fruit)
		fruit_node = new_fruit as Area2D
	if fruit_node == null:
		return
	_active_fruit = fruit_node
	var fruit_node2d := fruit_node as Node2D
	if fruit_node2d:
		fruit_node2d.global_position = target_position
	if reactivate:
		_activate_fruit_now(true)
	else:
		_ensure_fruit_hidden()

func connect_level_signals() -> void:
	var goal_callable := Callable(self, "_on_level_won")
	for goal in get_tree().get_nodes_in_group("goals"):
		if goal.is_connected("level_won", goal_callable) == false:
			goal.connect("level_won", goal_callable)

func _on_level_won() -> void:
	# TODO: trigger level completion flow.
	print("Nivel ganado. Preparando siguiente etapa...")

func _log_loop_feedback(created_ghost: bool) -> void:
	if created_ghost:
		print("¡ECO CREADO!")
	else:
		print("Intento fallido: Sin fruta")

func _determine_start_position() -> Vector2:
	if _has_loop_start_position:
		return _loop_start_position
	if spawn_point:
		return spawn_point.global_position
	if fruit_spawn_point:
		return fruit_spawn_point.global_position
	if _player:
		return _player.global_position
	return Vector2.ZERO

func _compute_fruit_spawn_position() -> Vector2:
	if fruit_spawn_point:
		return fruit_spawn_point.global_position
	if _has_loop_start_position:
		return _loop_start_position
	if spawn_point:
		return spawn_point.global_position
	return Vector2.ZERO
