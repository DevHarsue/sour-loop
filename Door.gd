extends StaticBody2D

@export var open_animation: StringName = &"open"
@export var closed_animation: StringName = &"closed"

var _is_open: bool = false
var _collision_shapes: Array = []
var _initial_collision_layer: int = 0
var _initial_collision_mask: int = 0

@onready var _animation_player: AnimationPlayer = get_node_or_null("AnimationPlayer")
@onready var _animated_sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")

func _ready() -> void:
	_gather_collision_shapes()
	_initial_collision_layer = collision_layer
	_initial_collision_mask = collision_mask
	_is_open = true
	close()

func open() -> void:
	if _is_open:
		return
	_is_open = true
	_set_collision_enabled(false)
	_play_animation(open_animation)

func close() -> void:
	if _is_open:
		_is_open = false
	else:
		# Ensure the closed state is applied even if we were already closed.
		pass
	_set_collision_enabled(true)
	_play_animation(closed_animation)

func _gather_collision_shapes() -> void:
	_collision_shapes.clear()
	var queue: Array = [self]
	while queue.is_empty() == false:
		var current: Node = queue.pop_front()
		for child in current.get_children():
			queue.push_back(child)
			if child is CollisionShape2D or child is CollisionPolygon2D:
				_collision_shapes.append(child)

func _set_collision_enabled(enabled: bool) -> void:
	for shape in _collision_shapes:
		if shape is CollisionShape2D:
			(shape as CollisionShape2D).disabled = not enabled
		elif shape is CollisionPolygon2D:
			(shape as CollisionPolygon2D).disabled = not enabled
	if enabled:
		set_deferred("collision_layer", _initial_collision_layer)
		set_deferred("collision_mask", _initial_collision_mask)
	else:
		set_deferred("collision_layer", 0)
		set_deferred("collision_mask", 0)

func _play_animation(name: StringName) -> void:
	if _animation_player and _animation_player.has_animation(name):
		_animation_player.play(name)
		return
	if _animated_sprite and _animated_sprite.sprite_frames:
		var frames := _animated_sprite.sprite_frames
		if frames.has_animation(name):
			_animated_sprite.play(name)
		elif name == closed_animation:
			_animated_sprite.stop()
