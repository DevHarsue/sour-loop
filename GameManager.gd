extends Node

@export var player_scene: PackedScene
@export var ghost_scene: PackedScene
@export var spawn_point: Marker2D
@export var ghost_container: Node
@export var timer_label: Label


@export var loop_duration: float = 10.0
var current_time: float = 0.0
var recordings_history: Array = [] # Holds Array[Dictionary] segments
var _player: CharacterBody2D
# var _ghost_counter: int = 0

func _ready() -> void:
	start_new_loop()

func _process(delta: float) -> void:
	if _player == null:
		return
	current_time += delta
	update_timer_label()
	if current_time >= loop_duration:
		reset_loop()

func update_timer_label() -> void:
	if timer_label:
		timer_label.text = "Tiempo: %.2f / %.2f" % [current_time, loop_duration]

func reset_loop() -> void:
	if _player:
		var latest_recording: Array[Dictionary] = _player.get_recording()
		if latest_recording.is_empty() == false:
			recordings_history.append(latest_recording)
			if recordings_history.size() > 3:
				recordings_history.pop_front()
		_player.queue_free()
	_player = spawn_player()
	spawn_ghosts()
	current_time = 0.0
	update_timer_label()

	

func spawn_player() -> CharacterBody2D:
	if player_scene == null or spawn_point == null:
		return null
	var new_player := player_scene.instantiate()
	var player_body := new_player as CharacterBody2D
	if player_body == null:
		if is_instance_valid(new_player):
			new_player.queue_free()
		return null
	player_body.global_position = spawn_point.global_position
	add_child(player_body)
	return player_body

func spawn_ghosts() -> void:
	if ghost_container == null or ghost_scene == null:
		return
	# Remove any ghosts from the previous loop before spawning new replays.
	for child in ghost_container.get_children():
		child.queue_free()
	for i in range(recordings_history.size()):
		var recording = recordings_history[i]
		var new_ghost := ghost_scene.instantiate()
		var ghost_body := new_ghost as CharacterBody2D
		if ghost_body == null:
			if is_instance_valid(new_ghost):
				new_ghost.queue_free()
			continue
		ghost_container.add_child(ghost_body)
		ghost_body.start_replay(recording as Array[Dictionary], i + 1)

func start_new_loop() -> void:
	recordings_history.clear()
	if ghost_container:
		for child in ghost_container.get_children():
			child.queue_free()
	_player = spawn_player()
	current_time = 0.0
	update_timer_label()
