class_name GravitySource
extends Node2D

## Default from the one tuning table (a sun); the flight scene sets it per body.
@export var mass: float = SystemLayout.FLIGHT_MASS[CelestialBody.BodyType.SUN]
## Draw size, and the softening distance that stops the pull blowing up
## near the centre.
@export var radius: float = 24.0
@export var colour: Color = Color(1.0, 0.7, 0.2)

func _ready() -> void:
	add_to_group("gravity_sources")

func get_pull(from_position: Vector2) -> Vector2:
	var offset := global_position - from_position
	var distance: float = max(offset.length(), radius)
	var strength: float = mass / (distance * distance)
	return offset.normalized() * strength

func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, colour)
