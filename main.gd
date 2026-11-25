extends Node2D

## Flight scene controller. Builds the entered system from its generated
## data -- star at the origin, up to 4 planets orbiting on calendar time,
## the black hole beyond the outermost orbit -- and provides the way back
## to the star map. Every body pulls the ship via the gravity_sources group.

const STAR_MAP_SCENE := "res://star_map.tscn"
const GravitySourceScene := preload("res://gravity_source.tscn")
const BlackHoleScene := preload("res://black_hole.tscn")
const ORBIT_RING_COLOUR := Color(1.0, 1.0, 1.0, 0.12)

@onready var ship: CharacterBody2D = $Ship

var system_index: int = -1
var system: StarSystem
var star_body: GravitySource
var planet_bodies: Array[OrbitingBody] = []
## null when the system has no black hole.
var black_hole: Area2D

func _ready() -> void:
	var galaxy: Galaxy = GalaxyState.galaxy
	system_index = NavState.consume_pending_system() if NavState.has_pending_system() else galaxy.home_index
	system = galaxy.systems[system_index]
	_build_system()

	ship.global_position = SystemLayout.entry_point(system)
	ship.velocity = SystemLayout.entry_velocity(system)
	ship.get_node("Camera2D").zoom = Vector2.ONE * SystemLayout.FLIGHT_CAMERA_ZOOM
	_print_system()

func _build_system() -> void:
	star_body = GravitySourceScene.instantiate()
	_configure_source(star_body, system.star)
	star_body.name = "Star"
	add_child(star_body)

	for i in range(system.planets.size()):
		var planet := OrbitingBody.new()
		planet.system = system
		planet.index = i
		_configure_source(planet, system.planets[i])
		planet.name = "Planet%d" % (i + 1)
		add_child(planet)
		planet_bodies.append(planet)

	if system.has_black_hole():
		black_hole = BlackHoleScene.instantiate()
		black_hole.name = "BlackHole"
		black_hole.position = SystemLayout.black_hole_position(system)
		black_hole.trigger_radius = SystemLayout.draw_radius(system.black_hole)
		black_hole.mass = SystemLayout.flight_mass(system.black_hole)
		# a placeholder same-system jump until Issue #16's routing
		black_hole.destination = SystemLayout.entry_point(system)
		add_child(black_hole)

	# bodies before the ship, so the ship draws on top
	move_child(ship, -1)

func _configure_source(source: GravitySource, body: CelestialBody) -> void:
	source.mass = SystemLayout.flight_mass(body)
	source.radius = SystemLayout.draw_radius(body)
	source.colour = SystemLayout.body_colour(body)

func _draw() -> void:
	for i in range(system.planets.size()):
		draw_arc(Vector2.ZERO, SystemLayout.orbit_radius(i), 0.0, TAU, 96, ORBIT_RING_COLOUR, 1.0)

func _print_system() -> void:
	print("main: entered %s (system %d) -- star %s %s, %d planet(s), black hole: %s" % [
		system.name, system_index, system.star.spectral_class,
		CelestialBody.BodyType.keys()[system.star.get_body_type()],
		system.planets.size(), "yes" if black_hole != null else "no",
	])
	for i in range(system.planets.size()):
		print("  planet %d: %s, orbit r=%.0f, period=%.1fs" % [
			i + 1, CelestialBody.BodyType.keys()[system.planets[i].get_body_type()],
			SystemLayout.orbit_radius(i), SystemLayout.orbit_period(i),
		])
	if black_hole != null:
		print("  black hole at r=%.0f" % SystemLayout.black_hole_distance(system))

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file(STAR_MAP_SCENE)
