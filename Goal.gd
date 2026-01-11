extends Area2D

signal level_won

@export var next_level_scene: PackedScene
@export var end_scene: PackedScene

func _ready() -> void:
	add_to_group("goals")
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body: Node) -> void:
	if not _is_player(body):
		return
	print("NIVEL COMPLETADO")
	emit_signal("level_won")
	if next_level_scene:
		get_tree().change_scene_to_packed(next_level_scene)
	elif end_scene:
		get_tree().change_scene_to_packed(end_scene)
	else:
		print("Juego terminado: no hay siguiente nivel asignado.")

func _is_player(body: Node) -> bool:
	if body == null:
		return false
	return body.has_method("collect_fruit") or body.has_method("has_fruit")

