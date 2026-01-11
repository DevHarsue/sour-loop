extends Area2D

@export var door: Node
@export var pressed_animation: StringName = &"pressed"
@export var idle_animation: StringName = &"idle"

var _tracked_bodies: Dictionary = {}

@onready var _animation_player: AnimationPlayer = get_node_or_null("AnimationPlayer")
@onready var _animated_sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
	if _is_valid_actor(body) == false:
		return
	var id := body.get_instance_id()
	if _tracked_bodies.has(id):
		return
	_tracked_bodies[id] = body
	if door and door.has_method("open"):
		door.open()
	_play_animation(true)

func _on_body_exited(body: Node) -> void:
	if _is_valid_actor(body) == false:
		return
	var id := body.get_instance_id()
	_tracked_bodies.erase(id)
	if _tracked_bodies.is_empty():
		if door and door.has_method("close"):
			door.close()
		_play_animation(false)

func _is_valid_actor(body: Node) -> bool:
	return body is CharacterBody2D

func _play_animation(pressed: bool) -> void:
	if _animation_player:
		var animation_name := pressed_animation if pressed else idle_animation
		if _animation_player.has_animation(animation_name):
			_animation_player.play(animation_name)
		elif pressed == false and _animation_player.has_animation(idle_animation):
			_animation_player.play(idle_animation)
		return
	if _animated_sprite:
		var frames := _animated_sprite.sprite_frames
		if frames == null:
			return
		var anim := pressed_animation if pressed else idle_animation
		if frames.has_animation(anim):
			_animated_sprite.play(anim)
		elif pressed == false and frames.has_animation(idle_animation):
			_animated_sprite.play(idle_animation)
