class_name OrbitingBody
extends GravitySource

## A planet on fixed orbit tracks. Its position is recalculated from
## TimeSystem.calendar_time every physics frame, never accumulated, so a
## calendar-time skip moves it straight to the right place. Planets don't
## pull on each other or on the star; they only pull the ship.

var system: StarSystem
var index: int = 0

## Looked up at runtime rather than named as the TimeSystem global: this is
## a class_name script, so it can be compiled (e.g. by a headless test that
## references the class) before autoload names exist.
var _time_system: Node

func _ready() -> void:
	super()
	_time_system = get_node("/root/TimeSystem")
	# move before the ship reads get_pull(), so the drawn position and the
	# pull agree within each frame
	process_physics_priority = -1
	update_position(_time_system.calendar_time)

func _physics_process(_delta: float) -> void:
	update_position(_time_system.calendar_time)

func update_position(calendar_time: float) -> void:
	position = SystemLayout.planet_position(system, index, calendar_time)
