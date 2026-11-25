class_name Galaxy
extends Resource

## The whole generated map. Built by GalaxyGenerator, kept alive by the
## GalaxyState autoload.

@export var seed: int = 0
@export var systems: Array[StarSystem] = []
## Index into systems of the one home system.
@export var home_index: int = -1

func get_home() -> StarSystem:
	if home_index < 0 or home_index >= systems.size():
		return null
	return systems[home_index]

## Plain-data form: two galaxies are identical when these are equal.
func to_dict() -> Dictionary:
	var system_dicts: Array = []
	for system in systems:
		system_dicts.append(system.to_dict())
	return {
		"seed": seed,
		"home_index": home_index,
		"systems": system_dicts,
	}

## Stable text form (sorted keys) -- the easy thing to compare or diff.
func to_json() -> String:
	return JSON.stringify(to_dict(), "", true)
