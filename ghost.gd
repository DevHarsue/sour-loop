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

var _replay_data: Array[Dictionary] = []
var _frame_index: int = 0
var _is_replaying: bool = false
var _coyote_timer: float = 0.0

func start_replay(recording_data: Array[Dictionary], ghost_number: int) -> void:
	_replay_data = recording_data.duplicate() as Array[Dictionary]
	$Label.text = str(ghost_number)
	_frame_index = 0
	_is_replaying = _replay_data.size() > 0
	velocity = Vector2.ZERO
	_coyote_timer = 0.0
	if _is_replaying and _replay_data.size() > 0:
		var first_frame: Dictionary = _replay_data[0]
		if first_frame.has("global_position"):
			global_position = first_frame["global_position"]
		if first_frame.has("scale_x"):
			scale.x = first_frame["scale_x"]
		_frame_index = 0

func _physics_process(delta: float) -> void:
	if not _is_replaying:
		return
	if _frame_index >= _replay_data.size():
		_is_replaying = false
		queue_free()
		return
	var frame: Dictionary = _replay_data[_frame_index]
	_process_replay_frame(frame, delta)
	_frame_index += 1


func _process_replay_frame(frame: Dictionary, delta: float) -> void:
	var on_floor := is_on_floor()
	if on_floor:
		_coyote_timer = coyote_time
	else:
		_coyote_timer = max(_coyote_timer - delta, 0.0)

	velocity.y = min(velocity.y + gravity * delta, max_fall_speed)
	if on_floor and velocity.y > 0.0:
		velocity.y = 0.0

	var jump_pressed: bool = bool(frame.get("jump_pressed", false))
	if jump_pressed and _coyote_timer > 0.0:
		velocity.y = jump_velocity
		_coyote_timer = 0.0

	var input_axis: float = float(frame.get("input_axis", 0.0))
	if input_axis != 0.0:
		var accel := ground_acceleration if on_floor else air_acceleration
		var target_speed := input_axis * max_run_speed
		velocity.x = move_toward(velocity.x, target_speed, accel * delta)
	else:
		var damping := ground_friction if on_floor else air_friction
		velocity.x = move_toward(velocity.x, 0.0, damping * delta)

	move_and_slide()

	if frame.has("scale_x"):
		scale.x = frame["scale_x"]
