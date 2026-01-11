extends CharacterBody2D

@export var gravity: float = 1600.0
@export var max_fall_speed: float = 1200.0
@export var jump_velocity: float = -520.0
@export var max_run_speed: float = 280.0
@export var ground_acceleration: float = 2200.0
@export var air_acceleration: float = 1400.0
@export var ground_friction: float = 2200.0
@export var air_friction: float = 400.0
@export var coyote_time: float = 0.12

var _has_fruit: bool = false
var has_ghost_power: bool = false
var _coyote_timer: float = 0.0
var current_recording: Array[Dictionary] = []
@onready var _sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")

func collect_fruit() -> void:
	_has_fruit = true

func has_fruit() -> bool:
	return _has_fruit

func reset_fruit() -> void:
	_has_fruit = false
	# restart ghost power visuals when fruit status clears.
	has_ghost_power = false
	if _sprite:
		_sprite.modulate = Color.WHITE

func enable_ghost_power() -> void:
	has_ghost_power = true
	if _sprite:
		_sprite.modulate = Color(0.4, 0.7, 1.0)

func start_new_recording() -> void:
	current_recording.clear()
	current_recording.append(_create_frame_snapshot(0.0, false, is_on_floor()))

func _physics_process(delta: float) -> void:
	var on_floor := is_on_floor()
	if on_floor:
		_coyote_timer = coyote_time
	else:
		_coyote_timer = max(_coyote_timer - delta, 0.0)

	velocity.y = min(velocity.y + gravity * delta, max_fall_speed)
	if on_floor and velocity.y > 0.0:
		velocity.y = 0.0

	var jump_pressed := Input.is_action_just_pressed("ui_accept")
	if jump_pressed and _coyote_timer > 0.0:
		velocity.y = jump_velocity
		_coyote_timer = 0.0
		if AudioManager:
			AudioManager.play_jump_sfx()

	var input_axis := Input.get_axis("ui_left", "ui_right")
	if input_axis != 0.0:
		var accel := ground_acceleration if on_floor else air_acceleration
		var target_speed := input_axis * max_run_speed
		velocity.x = move_toward(velocity.x, target_speed, accel * delta)
	else:
		var damping := ground_friction if on_floor else air_friction
		velocity.x = move_toward(velocity.x, 0.0, damping * delta)

	move_and_slide()
	var on_floor_after := is_on_floor()
	_update_animation(on_floor_after)
	current_recording.append(_create_frame_snapshot(input_axis, jump_pressed, on_floor_after))


func get_recording() -> Array[Dictionary]:
	var recording_copy: Array[Dictionary] = current_recording.duplicate() as Array[Dictionary]
	current_recording.clear()
	return recording_copy

func _create_frame_snapshot(input_axis: float, jump_pressed: bool, on_floor: bool) -> Dictionary:
	return {
		"global_position": global_position,
		"scale_x": scale.x,
		"input_axis": input_axis,
		"jump_pressed": jump_pressed,
		"velocity": velocity,
		"on_floor": on_floor
	}

func _update_animation(on_floor: bool) -> void:
	if _sprite == null:
		return
	if velocity.x < -1.0:
		_sprite.flip_h = true
	elif velocity.x > 1.0:
		_sprite.flip_h = false

	var target_anim := "jump"
	if on_floor:
		if absf(velocity.x) <= 1.0:
			target_anim = "idle"
		else:
			target_anim = "run"

	if _sprite.animation != target_anim:
		_sprite.play(target_anim)
