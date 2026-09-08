extends Node2D

@export var mass: float = 4_000_000.0
@export var radius: float = 24.0

func _ready() -> void:
	add_to_group("gravity_sources")

func get_pull(from_position: Vector2) -> Vector2:
	var offset := global_position - from_position
	var distance: float = max(offset.length(), radius)
	var strength: float = mass / (distance * distance)
	return offset.normalized() * strength

func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, Color(1.0, 0.7, 0.2))
