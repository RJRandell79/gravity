extends SceneTree

## Headless: godot --headless --path . -s tests/test_galaxy_generation.gd

const CB := preload("res://celestial_body.gd")
const Generator := preload("res://galaxy_generator.gd")
const Catalogue := preload("res://star_catalogue.gd")
const SS := preload("res://star_system.gd")

const SEED := 1990
const OTHER_SEED := 1991
const AVERAGING_SEEDS := 20
const SPACING_SEEDS := 5
const BLACK_HOLE_TOLERANCE := 0.04

var failures := 0

func _initialize() -> void:
	# the catalogue the generator draws from
	var catalogue_names := {}
	for i in range(Catalogue.size()):
		catalogue_names[Catalogue.star_name(i)] = true
	_check("catalogue has enough stars", Catalogue.size() >= Generator.SYSTEM_COUNT, true)
	_check("catalogue names are unique", catalogue_names.size(), Catalogue.size())
	var catalogue_ok := true
	for i in range(Catalogue.size()):
		var letter: String = Catalogue.spectral_class(i).substr(0, 1)
		if not CB.SPECTRAL_COLOURS.has(letter) or not Generator.STAR_DIAMETER_KM.has(letter):
			catalogue_ok = false
			print("FAIL catalogue row %d (%s) has class '%s'" % [i, Catalogue.star_name(i), Catalogue.spectral_class(i)])
	_check("every catalogue class is a known spectral letter", catalogue_ok, true)

	# determinism: same seed, same galaxy -- and a different one for another seed
	var a: Galaxy = Generator.generate(SEED)
	var b: Galaxy = Generator.generate(SEED)
	var c: Galaxy = Generator.generate(OTHER_SEED)
	_check("same seed gives an identical galaxy", a.to_json() == b.to_json(), true)
	_check("same seed gives identical to_dict", a.to_dict() == b.to_dict(), true)
	_check("different seed gives a different galaxy", a.to_json() != c.to_json(), true)
	_check("seed is recorded", a.seed, SEED)
	_check("seeds wrap into 0..65535", Generator.generate(SEED + Generator.SEED_COUNT).to_json(), a.to_json())
	# generating other galaxies in between must not disturb a later run
	var d: Galaxy = Generator.generate(SEED)
	_check("generation is independent of earlier runs", a.to_json() == d.to_json(), true)

	_check_galaxy(a, "seed %d" % SEED)
	for s in range(SPACING_SEEDS):
		_check_galaxy(Generator.generate(s), "seed %d" % s, true)

	# black-hole proportion over many seeds (home counts as having one)
	var with_hole := 0
	var total := 0
	for s in range(AVERAGING_SEEDS):
		var g: Galaxy = Generator.generate(1000 + s)
		for system in g.systems:
			total += 1
			if system.has_black_hole():
				with_hole += 1
	var proportion := float(with_hole) / float(total)
	print("black-hole proportion over %d seeds: %.3f (target %.2f)" % [AVERAGING_SEEDS, proportion, Generator.BLACK_HOLE_CHANCE])
	_check("black-hole proportion is near the tunable constant", absf(proportion - Generator.BLACK_HOLE_CHANCE) < BLACK_HOLE_TOLERANCE, true)

	print("RESULT: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(1 if failures > 0 else 0)

func _check_galaxy(g: Galaxy, label: String, spacing_only: bool = false) -> void:
	var half: float = Generator.CUBE_SIZE / 2.0
	var names := {}
	var homes := 0
	var planets_ok := true
	var statuses_ok := true
	var inside := true
	var min_gap := INF
	var bodies_ok := true

	for i in range(g.systems.size()):
		var sys: StarSystem = g.systems[i]
		names[sys.name] = true
		if sys.is_home:
			homes += 1
		if sys.planets.size() > Generator.MAX_PLANETS:
			planets_ok = false
		for planet in sys.planets:
			if planet.role != CB.Role.PLANET:
				planets_ok = false
		if abs(sys.position.x) > half or abs(sys.position.y) > half or abs(sys.position.z) > half:
			inside = false
		if sys.star == null or sys.star.get_body_type() != CB.BodyType.SUN or sys.star.get_star_colour() == CB.StarColour.NONE:
			bodies_ok = false
		if sys.has_black_hole() and sys.black_hole.get_body_type() != CB.BodyType.BLACK_HOLE:
			bodies_ok = false
		if sys.is_home != (i == g.home_index):
			statuses_ok = false
		var expected_status := StarSystem.Status.TERRAN if sys.is_home else StarSystem.Status.UNKNOWN
		if sys.status != expected_status:
			statuses_ok = false
		for j in range(i + 1, g.systems.size()):
			min_gap = minf(min_gap, sys.position.distance_to(g.systems[j].position))

	_check("%s: positions respect minimum spacing" % label, min_gap >= Generator.MIN_SPACING, true)
	if spacing_only:
		_check("%s: positions inside the cube" % label, inside, true)
		return

	_check("%s: exactly 128 systems" % label, g.systems.size(), 128)
	_check("%s: unique names" % label, names.size(), 128)
	_check("%s: exactly one home" % label, homes, 1)
	_check("%s: every non-home system is UNKNOWN, home is TERRAN" % label, statuses_ok, true)
	_check("%s: 0-4 planets per system, all role Planet" % label, planets_ok, true)
	_check("%s: positions inside the cube" % label, inside, true)
	_check("%s: stars are suns with a colour, black holes are black holes" % label, bodies_ok, true)

	var home: StarSystem = g.get_home()
	_check("%s: home has a black hole" % label, home.has_black_hole(), true)
	_check("%s: home has a Terran planet" % label, home.has_terran_planet(), true)
	_check("%s: home distance is 0" % label, home.distance_ly, 0.0)
	var distance_ok := true
	for sys in g.systems:
		if not is_equal_approx(sys.distance_ly, sys.position.distance_to(home.position) * Generator.LY_PER_CUBE_UNIT):
			distance_ok = false
	_check("%s: distance_ly is measured from home" % label, distance_ok, true)

func _check(label: String, got, expected) -> void:
	var ok: bool = got == expected
	if not ok:
		failures += 1
	print("%s %s: got=%s expected=%s" % ["ok  " if ok else "FAIL", label, got, expected])
