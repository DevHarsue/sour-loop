extends Area2D

signal fruit_collected

var _collected: bool = false
var _initial_sprite_modulate: Color = Color.WHITE

@onready var _collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D")
@onready var _sprite: Sprite2D = get_node_or_null("Sprite2D")
@onready var _pickup_sound: AudioStreamPlayer = get_node_or_null("PickupSound")

func _enter_tree() -> void:
	add_to_group("fruits")

func _ready() -> void:
	if _sprite:
		_initial_sprite_modulate = _sprite.modulate
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body: Node) -> void:
	if _collected:
		return
	if body == null or body.has_method("collect_fruit") == false:
		return
	body.collect_fruit()
	if body.has_method("enable_ghost_power"):
		body.enable_ghost_power()
	if AudioManager:
		AudioManager.play_power_up_sfx()
	_collected = true
	_play_pickup_effect()
	_disable_pickup()
	var manager := _get_game_manager()
	if manager:
		manager.trigger_loop_start(global_position)
	emit_signal("fruit_collected")

func reset_fruit() -> void:
	_collected = false
	visible = true
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)
	if _collision_shape:
		_collision_shape.set_deferred("disabled", false)
	if _sprite:
		_sprite.show()
		_sprite.modulate = _initial_sprite_modulate

func _disable_pickup() -> void:
	visible = false
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	if _collision_shape:
		_collision_shape.set_deferred("disabled", true)
	if _sprite:
		_sprite.hide()

func _play_pickup_effect() -> void:
	if _pickup_sound:
		_pickup_sound.play()
	elif _sprite:
		_sprite.modulate = Color(1.0, 1.0, 0.4)

func _get_game_manager() -> Node:
	var managers := get_tree().get_nodes_in_group("game_manager")
	if managers.is_empty():
		return null
	return managers[0]
