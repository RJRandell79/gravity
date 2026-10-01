extends Node2D

## Flight scene controller. Consumes a pending spawn position handed off
## by the star map (if any) and provides the way back to it.

const STAR_MAP_SCENE := "res://star_map.tscn"

@onready var ship: CharacterBody2D = $Ship

func _ready() -> void:
	if NavState.has_pending_spawn:
		ship.global_position = NavState.consume_pending_spawn()
		print("main: ship spawned at %s (from star map)" % [ship.global_position])

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file(STAR_MAP_SCENE)
