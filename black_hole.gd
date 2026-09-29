extends Area2D

## Static black hole. A body entering trigger_radius fires jump_triggered
## and is teleported to destination. No time cost yet (see #5).

signal jump_triggered(body: Node2D)

@export var trigger_radius: float = 40.0
@export var destination: Vector2 = Vector2.ZERO

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	(collision_shape.shape as CircleShape2D).radius = trigger_radius
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	jump_triggered.emit(body)
	body.global_position = destination

func _draw() -> void:
	draw_circle(Vector2.ZERO, trigger_radius, Color(0.05, 0.02, 0.1))
	draw_arc(Vector2.ZERO, trigger_radius, 0.0, TAU, 48, Color(0.6, 0.3, 0.9), 2.0)
