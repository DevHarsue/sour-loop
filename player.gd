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

var _coyote_timer: float = 0.0


func _physics_process(delta: float) -> void:
	var on_floor := is_on_floor()
	if on_floor:
		_coyote_timer = coyote_time
	else:
		_coyote_timer = max(_coyote_timer - delta, 0.0)

	velocity.y = min(velocity.y + gravity * delta, max_fall_speed)
	if on_floor and velocity.y > 0.0:
		velocity.y = 0.0

	if Input.is_action_just_pressed("ui_accept") and _coyote_timer > 0.0:
		velocity.y = jump_velocity
		_coyote_timer = 0.0

	var input_axis := Input.get_axis("ui_left", "ui_right")
	if input_axis != 0.0:
		var accel := ground_acceleration if on_floor else air_acceleration
		var target_speed := input_axis * max_run_speed
		velocity.x = move_toward(velocity.x, target_speed, accel * delta)
	else:
		var damping := ground_friction if on_floor else air_friction
		velocity.x = move_toward(velocity.x, 0.0, damping * delta)

	move_and_slide()
