extends Control

@export var restart_scene: PackedScene
@export var restart_button_path: NodePath = NodePath("CenterContainer/VBoxContainer/RestartButton")

func _ready() -> void:
	_wire_button()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_attempt_restart()

func _wire_button() -> void:
	if restart_button_path.is_empty():
		return
	var restart_button := get_node_or_null(restart_button_path)
	if restart_button is Button:
		restart_button.pressed.connect(_on_restart_pressed)
		restart_button.grab_focus()

func _on_restart_pressed() -> void:
	_attempt_restart()

func _attempt_restart() -> void:
	if restart_scene:
		get_tree().change_scene_to_packed(restart_scene)
	else:
		push_warning("Restart scene not assigned on EndScreen.")
