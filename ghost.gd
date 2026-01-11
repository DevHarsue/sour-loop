extends CharacterBody2D

signal replay_finished

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
@onready var _sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")

func prepare_replay(recording_data: Array[Dictionary], _ghost_number: int) -> void:
	_replay_data = recording_data.duplicate() as Array[Dictionary]
	_frame_index = 0
	_is_replaying = false
	velocity = Vector2.ZERO
	_coyote_timer = 0.0
	if _replay_data.size() > 0:
		var first_frame: Dictionary = _replay_data[0]
		if first_frame.has("global_position"):
			var maybe_position: Variant = first_frame["global_position"]
			if maybe_position is Vector2:
				global_position = maybe_position
		var first_velocity := _extract_velocity(first_frame, velocity)
		velocity = first_velocity
		_update_animation(first_frame, first_velocity)
	else:
		queue_free()

func begin_replay() -> void:
	if _replay_data.is_empty():
		queue_free()
		return
	_is_replaying = true
	_frame_index = 0

func _physics_process(delta: float) -> void:
	if not _is_replaying:
		return
	if _frame_index >= _replay_data.size():
		_end_replay()
		return
	var frame: Dictionary = _replay_data[_frame_index]
	_process_replay_frame(frame, delta)
	_frame_index += 1


func _process_replay_frame(frame: Dictionary, _delta: float) -> void:
	if frame.has("global_position"):
		var maybe_position: Variant = frame["global_position"]
		if maybe_position is Vector2:
			global_position = maybe_position
	var frame_velocity := _extract_velocity(frame, velocity)
	velocity = frame_velocity
	_update_animation(frame, frame_velocity)

func _end_replay() -> void:
	if _is_replaying:
		_is_replaying = false
		emit_signal("replay_finished")
	queue_free()

func _update_animation(frame: Dictionary, frame_velocity: Vector2) -> void:
	if _sprite == null:
		return
	var vx: float = frame_velocity.x
	if vx < -1.0:
		_sprite.flip_h = true
	elif vx > 1.0:
		_sprite.flip_h = false
	var on_floor := bool(frame.get("on_floor", false))
	var target_anim := "jump"
	if on_floor:
		var vx_abs := absf(vx)
		if vx_abs <= 1.0:
			target_anim = "idle"
		else:
			target_anim = "run"
	if _sprite.animation != target_anim:
		_sprite.play(target_anim)

func _extract_velocity(frame: Dictionary, fallback: Vector2) -> Vector2:
	var value = frame.get("velocity", null)
	if value is Vector2:
		return value
	return fallback
