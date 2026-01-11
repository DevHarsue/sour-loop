extends Area2D

@export var stone_head: Node
@export var pressed_animation: StringName = &"pressed"
@export var idle_animation: StringName = &"idle"

var _press_count: int = 0
var _should_hold_pressed: bool = false

@onready var _animation_player: AnimationPlayer = get_node_or_null("AnimationPlayer")
@onready var _animated_sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if _animation_player and _animation_player.is_connected("animation_finished", Callable(self, "_on_animation_player_finished")) == false:
		_animation_player.animation_finished.connect(Callable(self, "_on_animation_player_finished"))
	if _animated_sprite and _animated_sprite.is_connected("animation_finished", Callable(self, "_on_sprite_animation_finished")) == false:
		_animated_sprite.animation_finished.connect(Callable(self, "_on_sprite_animation_finished"))
	_update_animation()

func _on_body_entered(body: Node) -> void:
	if _is_valid_actor(body) == false:
		return
	_press_count += 1
	if stone_head and stone_head.has_method("go_to_sleep"):
		stone_head.go_to_sleep()
	_update_animation()

func _on_body_exited(body: Node) -> void:
	if _is_valid_actor(body) == false:
		return
	_press_count = max(_press_count - 1, 0)
	if _press_count == 0 and stone_head and stone_head.has_method("wake_up"):
		stone_head.wake_up()
	_update_animation()

func _is_valid_actor(body: Node) -> bool:
	return body is CharacterBody2D

func _update_animation() -> void:
	var pressed := _press_count > 0
	if _animation_player:
		var anim := pressed_animation if pressed else idle_animation
		if _animation_player.has_animation(anim):
			_should_hold_pressed = pressed
			if pressed:
				if _animation_player.current_animation != anim or _animation_player.is_playing() == false:
					_animation_player.play(anim)
			else:
				_animation_player.play(anim)
				var animation := _animation_player.get_animation(anim)
				if animation:
					_animation_player.seek(animation.length, true)
					_animation_player.stop()
		return
	if _animated_sprite and _animated_sprite.sprite_frames:
		var frames := _animated_sprite.sprite_frames
		if pressed:
			if frames.has_animation(pressed_animation):
				frames.set_animation_loop(pressed_animation, false)
				_should_hold_pressed = true
				_animated_sprite.frame = 0
				_animated_sprite.frame_progress = 0.0
				_animated_sprite.play(pressed_animation)
		else:
			if frames.has_animation(idle_animation):
				frames.set_animation_loop(idle_animation, false)
				_should_hold_pressed = false
				_animated_sprite.play(idle_animation)
				_hold_sprite_frame(idle_animation, false)

func _on_sprite_animation_finished() -> void:
	if _animated_sprite == null or _animated_sprite.sprite_frames == null:
		return
	if _should_hold_pressed:
		_hold_sprite_frame(pressed_animation, true)
	else:
		_hold_sprite_frame(idle_animation, false)

func _on_animation_player_finished(anim_name: StringName) -> void:
	if _animation_player == null:
		return
	if _should_hold_pressed and anim_name == pressed_animation:
		var animation := _animation_player.get_animation(anim_name)
		if animation:
			_animation_player.seek(animation.length, true)
			_animation_player.stop()

func _hold_sprite_frame(animation_name: StringName, pressed: bool) -> void:
	if _animated_sprite == null:
		return
	var frames := _animated_sprite.sprite_frames
	if frames == null or frames.has_animation(animation_name) == false:
		return
	_animated_sprite.animation = animation_name
	var frame_index: int = maxi(frames.get_frame_count(animation_name) - 1, 0)
	_animated_sprite.frame = frame_index
	_animated_sprite.stop()
