extends Area2D

## Static black hole. A body entering trigger_radius fires jump_triggered,
## is teleported to destination, and the jump advances calendar_time only --
## the crew travels in zero ship-time.

signal jump_triggered(body: Node2D)

@export var trigger_radius: float = 40.0
@export var destination: Vector2 = Vector2.ZERO
@export var calendar_time_cost: float = 50.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	(collision_shape.shape as CircleShape2D).radius = trigger_radius
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	jump_triggered.emit(body)
	body.global_position = destination
	TimeSystem.calendar_time += calendar_time_cost
	print("jump: calendar_time += %.1f -- ship_time=%.1f calendar_time=%.1f gap=%.1f" % [
		calendar_time_cost, TimeSystem.ship_time, TimeSystem.calendar_time,
		TimeSystem.calendar_time - TimeSystem.ship_time
	])

func _draw() -> void:
	draw_circle(Vector2.ZERO, trigger_radius, Color(0.05, 0.02, 0.1))
	draw_arc(Vector2.ZERO, trigger_radius, 0.0, TAU, 48, Color(0.6, 0.3, 0.9), 2.0)
