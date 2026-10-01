extends Node

## Carries the chosen destination across the star-map -> flight scene swap.
## change_scene_to_file() throws away the outgoing scene entirely, so an
## autoload is the only thing that survives the transition.

var pending_spawn_position: Vector2 = Vector2.ZERO
var has_pending_spawn: bool = false

func set_pending_spawn(spawn_position: Vector2) -> void:
	pending_spawn_position = spawn_position
	has_pending_spawn = true

func consume_pending_spawn() -> Vector2:
	has_pending_spawn = false
	return pending_spawn_position
