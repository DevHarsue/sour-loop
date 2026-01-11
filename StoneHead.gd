extends Area2D

@export var drop_speed: float = 1200.0
@export var return_speed: float = 400.0
@export var return_delay: float = 0.6
@export var max_drop_distance: float = 1024.0
@export var detection_half_width: float = 24.0
@export var player_node: CharacterBody2D
@export var awake_animation: StringName = &"angry"
@export var sleep_animation: StringName = &"idle"

var is_sleeping: bool = false

var _original_position: Vector2
var _drop_target_y: float
var _is_dropping: bool = false
var _is_returning: bool = false
var _drop_hit_player: bool = false
var _has_triggered_reset: bool = false
var _player_reference: CharacterBody2D = null

@onready var _animation_player: AnimationPlayer = get_node_or_null("AnimationPlayer")
@onready var _animated_sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")
@onready var _return_timer: Timer = _create_return_timer()

func _ready() -> void:
	_original_position = global_position
	if player_node:
		_player_reference = player_node
	set_monitoring(true)
	set_monitorable(true)
	collision_mask = 0xFFFFFFFF
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_return_timer.timeout.connect(_on_return_timeout)
	set_physics_process(true)
	set_process(true)
	wake_up()

func _physics_process(_delta: float) -> void:
	if is_sleeping:
		return
	var player := _get_player()
	if player == null:
		return
	var horizontal_overlap := absf(player.global_position.x - global_position.x) <= detection_half_width
	var player_below_origin := player.global_position.y >= _original_position.y
	if horizontal_overlap and player_below_origin and _is_dropping == false and _is_returning == false:
		_start_drop()

func _process(delta: float) -> void:
	if _is_dropping:
		var new_y := move_toward(global_position.y, _drop_target_y, drop_speed * delta)
		global_position.y = new_y
		if _check_player_overlap():
			return
		if absf(global_position.y - _drop_target_y) <= 1.0:
			global_position.y = _drop_target_y
			_is_dropping = false
			if _drop_hit_player:
				_drop_hit_player = false
				_handle_player_hit()
			else:
				if _check_player_overlap():
					return
				if _return_timer.is_stopped():
					_return_timer.start(return_delay)
	elif _is_returning:
		var new_y := move_toward(global_position.y, _original_position.y, return_speed * delta)
		global_position.y = new_y
		if absf(global_position.y - _original_position.y) <= 1.0:
			_is_returning = false
			global_position = _original_position

func _on_body_entered(body: Node) -> void:
	if _is_player(body):
		_player_reference = body
		if _is_dropping:
			_handle_player_hit()

func _on_body_exited(body: Node) -> void:
	if body == _player_reference and body != player_node:
		_player_reference = null

func go_to_sleep() -> void:
	is_sleeping = true
	_drop_hit_player = false
	_has_triggered_reset = false
	_play_animation_hold_last(sleep_animation)
	_stop_drop_and_return(true)

func wake_up() -> void:
	is_sleeping = false
	_drop_hit_player = false
	_has_triggered_reset = false
	_play_animation_loop(awake_animation)

func _start_drop() -> void:
	if _is_returning:
		_is_returning = false
	_return_timer.stop()
	var drop_info: Dictionary = _calculate_drop_target()
	_drop_target_y = float(drop_info.get("target_y", global_position.y))
	_drop_hit_player = bool(drop_info.get("hit_player", false))
	_has_triggered_reset = false
	_is_dropping = true

func _stop_drop_and_return(force_reset: bool) -> void:
	_is_dropping = false
	_is_returning = false
	_return_timer.stop()
	_drop_hit_player = false
	_has_triggered_reset = false
	if force_reset:
		global_position = _original_position

func _on_return_timeout() -> void:
	_is_returning = true

func _create_return_timer() -> Timer:
	var timer := Timer.new()
	timer.one_shot = true
	add_child(timer)
	return timer

func _play_animation_loop(name: StringName) -> void:
	if _animation_player and _animation_player.has_animation(name):
		_animation_player.play(name)
		return
	if _animated_sprite and _animated_sprite.sprite_frames and _animated_sprite.sprite_frames.has_animation(name):
		_animated_sprite.sprite_frames.set_animation_loop(name, true)
		_animated_sprite.play(name)

func _play_animation_hold_last(name: StringName) -> void:
	if _animation_player and _animation_player.has_animation(name):
		var anim := _animation_player.get_animation(name)
		if anim:
			_animation_player.play(name)
			_animation_player.seek(anim.length, true)
			_animation_player.stop()
		return
	if _animated_sprite and _animated_sprite.sprite_frames and _animated_sprite.sprite_frames.has_animation(name):
		var frames := _animated_sprite.sprite_frames
		frames.set_animation_loop(name, false)
		_animated_sprite.play(name)
		var total_frames: int = frames.get_frame_count(name)
		var last_frame: int = max(total_frames - 1, 0)
		_animated_sprite.frame = last_frame
		_animated_sprite.stop()

func _is_player(body: Node) -> bool:
	if body == null:
		return false
	if body.is_in_group("player"):
		return true
	return body.has_method("collect_fruit")

func _handle_player_hit() -> void:
	if _has_triggered_reset:
		return
	_has_triggered_reset = true
	_is_dropping = false
	_is_returning = false
	_return_timer.stop()
	_drop_hit_player = false
	_restart_loop_from_manager()
	_return_timer.start(return_delay)

func _check_player_overlap() -> bool:
	if monitoring == false:
		return false
	var bodies := get_overlapping_bodies()
	if bodies.is_empty():
		return false
	for body in bodies:
		if _is_player(body):
			_player_reference = body
			_handle_player_hit()
			return true
	return false

func _get_player() -> CharacterBody2D:
	if is_instance_valid(_player_reference):
		return _player_reference
	if player_node and is_instance_valid(player_node):
		_player_reference = player_node
		return player_node
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		var scene_root := get_tree().current_scene
		if scene_root:
			var found := scene_root.find_child("Player", true, false)
			var character := found as CharacterBody2D
			if character:
				_player_reference = character
				return character
		return null
	for node in players:
		var character := node as CharacterBody2D
		if character:
			_player_reference = character
			return character
	return null

func _get_game_manager() -> Node:
	var managers := get_tree().get_nodes_in_group("game_manager")
	if managers.is_empty():
		return null
	return managers[0]

func _restart_loop_from_manager() -> void:
	var manager := _get_game_manager()
	if manager == null:
		return
	if manager.has_method("reset_loop"):
		manager.reset_loop()
	elif manager.has_method("restart_loop"):
		manager.restart_loop(true)
	elif manager.has_method("start_new_loop"):
		manager.start_new_loop()

func _calculate_drop_target() -> Dictionary:
	var collider_bottom := _get_collider_bottom_offset()
	var visual_bottom := _get_visual_bottom_offset()
	var ray_offset: float = collider_bottom
	if ray_offset <= 0.0:
		ray_offset = visual_bottom
	var bottom_offset: float = max(collider_bottom, visual_bottom)
	var from := global_position + Vector2(0.0, ray_offset)
	var to := from + Vector2(0.0, max_drop_distance)
	var space_state := get_world_2d().direct_space_state
	var target_y: float = max(_original_position.y, global_position.y + max_drop_distance)
	var hit_player: bool = false
	if space_state:
		var params := PhysicsRayQueryParameters2D.create(from, to)
		params.exclude = [get_rid()]
		params.collide_with_bodies = true
		params.collide_with_areas = false
		params.collision_mask = 0xFFFFFFFF
		var result: Dictionary = space_state.intersect_ray(params)
		if result.is_empty() == false:
			var hit_pos_value: Variant = result.get("position")
			if hit_pos_value is Vector2:
				var hit_pos: Vector2 = hit_pos_value
				target_y = max(_original_position.y, hit_pos.y - bottom_offset)
			var collider_value: Variant = result.get("collider")
			var player := _get_player()
			if collider_value != null and player != null and collider_value == player:
				hit_player = true
	return {
		"target_y": target_y,
		"hit_player": hit_player
	}


func _get_collider_bottom_offset() -> float:
	var collider := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collider == null or collider.shape == null:
		return 0.0
	var scale_y := absf(collider.scale.y)
	var offset := collider.position.y * collider.scale.y
	var half_height := 0.0
	var shape := collider.shape
	if shape is RectangleShape2D:
		half_height = (shape.size.y * 0.5) * scale_y
	elif shape is CapsuleShape2D:
		half_height = ((shape.height * 0.5) + shape.radius) * scale_y
	elif shape is CircleShape2D:
		half_height = shape.radius * scale_y
	return offset + half_height


func _get_visual_bottom_offset() -> float:
	if _animated_sprite == null:
		return 0.0
	var frames := _animated_sprite.sprite_frames
	if frames == null:
		return _animated_sprite.position.y
	# Use the tallest frame to align the visual bottom with the ground when dropping.
	var max_height := 0.0
	for animation_name: StringName in frames.get_animation_names():
		var frame_count := frames.get_frame_count(animation_name)
		for frame_index: int in range(frame_count):
			var texture := frames.get_frame_texture(animation_name, frame_index)
			if texture:
				var size := texture.get_size()
				if size.y > max_height:
					max_height = size.y
	if max_height <= 0.0:
		return _animated_sprite.position.y
	var base_offset := _animated_sprite.offset.y
	if _animated_sprite.centered:
		base_offset += max_height * 0.5
	else:
		base_offset += max_height
	var scale_y := absf(_animated_sprite.scale.y)
	return _animated_sprite.position.y + base_offset * scale_y
