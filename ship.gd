extends CharacterBody2D

@export var thrust_power: float = 400.0
@export var rotation_speed: float = 3.0

func _physics_process(delta: float) -> void:
	if Input.is_action_pressed("ui_left"):
		rotation -= rotation_speed * delta
	if Input.is_action_pressed("ui_right"):
		rotation += rotation_speed * delta
	if Input.is_action_pressed("ui_up"):
		velocity += Vector2.UP.rotated(rotation) * thrust_power * delta

	for source in get_tree().get_nodes_in_group("gravity_sources"):
		velocity += source.get_pull(global_position) * delta

	move_and_slide()

func _draw() -> void:
	var points := PackedVector2Array([Vector2(0, -16), Vector2(12, 14), Vector2(-12, 14)])
	draw_colored_polygon(points, Color(0.6, 0.85, 1.0))
