extends Node

## Holds the one generated galaxy for the whole session. The star map is
## rebuilt every time it's entered (change_scene_to_file frees the old one),
## so the galaxy can't live there -- an autoload is what survives, same
## reason NavState is one.

## Fixed for now. Seeds wrap into 0..65535 (GalaxyGenerator.SEED_COUNT).
const GALAXY_SEED := 1990

var galaxy: Galaxy

func _ready() -> void:
	galaxy = GalaxyGenerator.generate(GALAXY_SEED)
	print("galaxy_state: generated seed %d -- %d systems, home %s" % [galaxy.seed, galaxy.systems.size(), galaxy.get_home().name])
