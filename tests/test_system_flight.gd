extends SceneTree

## Headless test of the multi-body system flight scene (Issue #15):
## godot --headless --path . -s tests/test_system_flight.gd
## Clocks are frozen (TimeSystem disabled) and calendar_time is set by hand,
## so every position check is exact.

const MAIN_SCENE := "res://main.tscn"

var failures := 0
var time_system: Node
var nav: Node
var galaxy: Galaxy

func _initialize() -> void:
	# autoloads (TimeSystem, NavState, GalaxyState) only run _ready after _initialize
	await process_frame
	time_system = root.get_node("TimeSystem")
	nav = root.get_node("NavState")
	galaxy = root.get_node("GalaxyState").galaxy
	time_system.process_mode = Node.PROCESS_MODE_DISABLED
	time_system.calendar_time = 0.0

	_check_layout_maths()
	_check_masses()

	var cases := {
		"home": galaxy.home_index,
		"no planets": _find_system(func(s: StarSystem): return s.planets.is_empty()),
		"4 planets": _find_system(func(s: StarSystem): return s.planets.size() == 4 and s.has_black_hole()),
		"no black hole": _find_system(func(s: StarSystem): return not s.has_black_hole()),
	}
	for label in cases:
		var index: int = cases[label]
		_check("galaxy has a %s system" % label, index >= 0, true)
		if index >= 0:
			await _check_system(label, index)

	await _check_jump(galaxy.home_index)
	await _check_default_is_home()

	print("RESULT: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(1 if failures > 0 else 0)

func _check_layout_maths() -> void:
	var periods_grow := true
	var slower_outward := true
	var probe := galaxy.get_home()
	var prev_period := 0.0
	var prev_sweep := INF
	for i in range(GalaxyGenerator.MAX_PLANETS):
		var period := SystemLayout.orbit_period(i)
		if period <= prev_period:
			periods_grow = false
		prev_period = period
		# angle swept in a short calendar-time step (well under one orbit)
		var sweep := wrapf(SystemLayout.planet_angle(probe, i, 3.0) - SystemLayout.planet_angle(probe, i, 0.0), 0.0, TAU)
		if sweep >= prev_sweep:
			slower_outward = false
		prev_sweep = sweep
	_check("orbit periods grow outward", periods_grow, true)
	_check("outer planets sweep less angle in the same time", slower_outward, true)
	_check("innermost period is the tunable constant", SystemLayout.orbit_period(0), SystemLayout.INNER_ORBIT_PERIOD)
	# one full period later the planet is back where it was
	var back := SystemLayout.planet_position(probe, 0, 7.0).distance_to(SystemLayout.planet_position(probe, 0, 7.0 + SystemLayout.orbit_period(0)))
	_check("a planet returns to the same spot after one period", back < 0.01, true)

func _check_masses() -> void:
	var m := SystemLayout.FLIGHT_MASS
	var star_mass: float = m[CelestialBody.BodyType.SUN]
	var hole_mass: float = m[CelestialBody.BodyType.BLACK_HOLE]
	var planet_max := 0.0
	for type in [CelestialBody.BodyType.GAS_GIANT, CelestialBody.BodyType.NEUTRONIUM_PLANET, CelestialBody.BodyType.ROCKY_PLANET, CelestialBody.BodyType.TERRAN_PLANET]:
		planet_max = max(planet_max, m[type])
	_check("flight mass: star > black hole", star_mass > hole_mass, true)
	_check("flight mass: black hole > every planet type", hole_mass > planet_max, true)

func _check_system(label: String, index: int) -> void:
	var sys: StarSystem = galaxy.systems[index]
	var t0 := 123.4
	time_system.calendar_time = t0
	var scene := _enter(index)

	var expect_hole := 1 if sys.has_black_hole() else 0
	_check("%s: entered the requested system" % label, scene.system, sys)
	_check("%s: one orbiting body per planet" % label, scene.planet_bodies.size(), sys.planets.size())
	_check("%s: black hole present iff the data has one" % label, scene.black_hole != null, sys.has_black_hole())
	_check("%s: gravity_sources = star + planets + black hole" % label,
		get_nodes_in_group("gravity_sources").size(), 1 + sys.planets.size() + expect_hole)
	_check("%s: star at the centre" % label, scene.star_body.position, Vector2.ZERO)
	_check("%s: star mass from its body type" % label, scene.star_body.mass, SystemLayout.flight_mass(sys.star))

	# positions come straight from calendar time
	_check("%s: planets placed for calendar time on entry" % label, _planets_match(scene, sys, t0), true)
	await physics_frame
	_check("%s: planets unchanged while calendar time is frozen" % label, _planets_match(scene, sys, t0), true)
	var t1 := t0 + 537.25
	time_system.calendar_time = t1
	await physics_frame
	_check("%s: after a calendar-time skip, planets are where the formula says" % label, _planets_match(scene, sys, t1), true)

	# leaving and re-entering at the same time gives the same layout
	var before: Array[Vector2] = []
	for planet in scene.planet_bodies:
		before.append(planet.position)
	scene.free()
	scene = _enter(index)
	var same := true
	for i in range(before.size()):
		if not scene.planet_bodies[i].position.is_equal_approx(before[i]):
			same = false
	_check("%s: re-entering gives identical planet positions" % label, same, true)

	# every body pulls, and a moving planet's pull changes as it moves
	var probe := Vector2(37.0, -51.0)
	var total := Vector2.ZERO
	var all_pull := true
	for source in get_nodes_in_group("gravity_sources"):
		var pull: Vector2 = source.get_pull(probe)
		if pull.length() <= 0.0:
			all_pull = false
		total += pull
	_check("%s: every body pulls on a point in the system" % label, all_pull, true)
	if not scene.planet_bodies.is_empty():
		var planet: OrbitingBody = scene.planet_bodies[0]
		var pull_a := planet.get_pull(probe)
		planet.update_position(t1 + SystemLayout.orbit_period(0) * 0.25)
		var pull_b := planet.get_pull(probe)
		_check("%s: a planet's pull changes as it orbits" % label, pull_a.is_equal_approx(pull_b), false)

	if scene.black_hole != null:
		var outer := SystemLayout.outermost_radius(sys)
		var biggest_planet := 0.0
		for planet in scene.planet_bodies:
			biggest_planet = max(biggest_planet, planet.radius)
		var clearance: float = scene.black_hole.position.length() - scene.black_hole.trigger_radius - (outer + biggest_planet)
		_check("%s: black hole sits beyond the outermost orbit" % label, clearance > 0.0, true)
		_check("%s: black hole mass is the black hole flight mass" % label, scene.black_hole.mass, SystemLayout.flight_mass(sys.black_hole))

	# ship arrives at the entry point, with the camera zoomed out
	_check("%s: ship spawned at the entry point" % label, scene.ship.global_position, SystemLayout.entry_point(sys))
	_check("%s: ship camera zoom set" % label, scene.ship.get_node("Camera2D").zoom, Vector2.ONE * SystemLayout.FLIGHT_CAMERA_ZOOM)
	scene.free()

func _check_jump(index: int) -> void:
	var sys: StarSystem = galaxy.systems[index]
	time_system.calendar_time = 10.0
	var ship_time_before: float = time_system.ship_time
	var scene := _enter(index)
	var jumps := [0]
	scene.black_hole.jump_triggered.connect(func(_body): jumps[0] += 1)
	scene.ship.velocity = Vector2.ZERO
	scene.ship.global_position = scene.black_hole.global_position
	for i in range(4):
		await physics_frame
	_check("jump: fired exactly once", jumps[0], 1)
	_check("jump: calendar time advanced by exactly the cost", time_system.calendar_time, 10.0 + scene.black_hole.calendar_time_cost)
	_check("jump: ship time untouched", time_system.ship_time, ship_time_before)
	# ship has flown a few frames under gravity since landing
	_check("jump: ship teleported to the system's entry point",
		scene.ship.global_position.distance_to(SystemLayout.entry_point(sys)) < 30.0, true)
	_check("jump: planets moved on to the new calendar time",
		_planets_match(scene, sys, time_system.calendar_time), true)
	scene.free()

func _check_default_is_home() -> void:
	nav.consume_pending_system()
	var scene: Node2D = load(MAIN_SCENE).instantiate()
	root.add_child(scene)
	_check("nothing pending: flight scene builds the home system", scene.system, galaxy.get_home())
	scene.free()
	await process_frame

func _enter(index: int) -> Node2D:
	nav.set_pending_system(index)
	var scene: Node2D = load(MAIN_SCENE).instantiate()
	root.add_child(scene)
	_check("pending system consumed on entry", nav.has_pending_system(), false)
	return scene

func _planets_match(scene: Node2D, sys: StarSystem, t: float) -> bool:
	for i in range(scene.planet_bodies.size()):
		if not scene.planet_bodies[i].position.is_equal_approx(SystemLayout.planet_position(sys, i, t)):
			return false
	return true

func _find_system(predicate: Callable) -> int:
	for i in range(galaxy.systems.size()):
		if predicate.call(galaxy.systems[i]):
			return i
	return -1

func _check(label: String, got, expected) -> void:
	var ok: bool = got == expected
	if not ok:
		failures += 1
	print("%s %s: got=%s expected=%s" % ["ok  " if ok else "FAIL", label, got, expected])
