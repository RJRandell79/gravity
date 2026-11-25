extends Node

## Carries the chosen system across the star-map -> flight scene swap.
## change_scene_to_file() throws away the outgoing scene entirely, so an
## autoload is the only thing that survives the transition.

const NO_PENDING_SYSTEM := -1

## Index into GalaxyState.galaxy.systems, or NO_PENDING_SYSTEM.
var pending_system_index: int = NO_PENDING_SYSTEM

func set_pending_system(index: int) -> void:
	pending_system_index = index

func has_pending_system() -> bool:
	return pending_system_index != NO_PENDING_SYSTEM

func consume_pending_system() -> int:
	var index := pending_system_index
	pending_system_index = NO_PENDING_SYSTEM
	return index
