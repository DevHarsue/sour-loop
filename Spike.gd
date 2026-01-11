extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	set_physics_process(false)
	set_process(true)

func _on_body_entered(body: Node) -> void:
	if body == null:
		return
	if _is_ghost(body):
		if is_instance_valid(body):
			body.queue_free()
		return
	if _is_player(body):
		var manager := _get_game_manager()
		if manager:
			if manager.has_method("reset_loop"):
				manager.reset_loop()
			elif manager.has_method("restart_loop"):
				manager.restart_loop(true)
			elif manager.has_method("start_new_loop"):
				manager.start_new_loop()
		return
	if body is CharacterBody2D and body.has_method("queue_free"):
		body.queue_free()

func _get_game_manager() -> Node:
	var managers := get_tree().get_nodes_in_group("game_manager")
	if managers.is_empty():
		return null
	return managers[0]

func _is_player(body: Node) -> bool:
	if body == null:
		return false
	if body.is_in_group("player"):
		return true
	return body.has_method("collect_fruit")

func _is_ghost(body: Node) -> bool:
	if body == null:
		return false
	if body.is_in_group("ghosts"):
		return true
	return body.has_method("prepare_replay")

func _process(delta: float) -> void:
	var sprite := get_node_or_null("AnimatedSprite2D")
	if sprite == null:
		return
	sprite.rotation += deg_to_rad(180.0) * delta
