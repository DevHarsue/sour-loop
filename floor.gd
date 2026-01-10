@tool
extends StaticBody2D

@export_range(16.0, 2048.0, 1.0, "or_greater") var width: float = 512.0
@export_range(8.0, 256.0, 1.0, "or_greater") var thickness: float = 32.0

var _cached_width: float = width
var _cached_thickness: float = thickness

func _ready() -> void:
	_cached_width = max(width, 1.0)
	width = _cached_width
	_cached_thickness = max(thickness, 1.0)
	thickness = _cached_thickness
	_update_geometry()
	if Engine.is_editor_hint():
		set_process(true)

func _process(_delta: float) -> void:
	var needs_update := false
	if not is_equal_approx(width, _cached_width):
		_cached_width = max(width, 1.0)
		width = _cached_width
		needs_update = true
	if not is_equal_approx(thickness, _cached_thickness):
		_cached_thickness = max(thickness, 1.0)
		thickness = _cached_thickness
		needs_update = true
	if needs_update:
		_update_geometry()
	if not Engine.is_editor_hint():
		set_process(false)

func _update_geometry() -> void:
	if not is_inside_tree():
		return
	var collision_shape: CollisionShape2D = $CollisionShape2D
	if collision_shape == null:
		return
	var shape := collision_shape.shape
	if shape == null:
		shape = RectangleShape2D.new()
		collision_shape.shape = shape
	shape.size = Vector2(_cached_width, _cached_thickness)
	collision_shape.position = Vector2(0.0, _cached_thickness * 0.5)
	var polygon: Polygon2D = $Polygon2D
	if polygon:
		polygon.polygon = PackedVector2Array([
			Vector2(-_cached_width * 0.5, 0.0),
			Vector2(_cached_width * 0.5, 0.0),
			Vector2(_cached_width * 0.5, _cached_thickness),
			Vector2(-_cached_width * 0.5, _cached_thickness)
		])
