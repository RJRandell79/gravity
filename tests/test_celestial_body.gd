extends SceneTree

const CB := preload("res://celestial_body.gd")

var failures := 0

func _initialize() -> void:
	# one case per body type
	_case("blue sun", CB.create(CB.Role.STAR, CB.Composition.HYDROGEN, 1_800_000.0, 0, "B3"), CB.BodyType.SUN, CB.StarColour.BLUE)
	_case("green sun", CB.create(CB.Role.STAR, CB.Composition.HYDROGEN, 1_390_000.0, 0, "G2"), CB.BodyType.SUN, CB.StarColour.GREEN)
	_case("red sun", CB.create(CB.Role.STAR, CB.Composition.HYDROGEN, 600_000.0, 0, "M2"), CB.BodyType.SUN, CB.StarColour.RED)
	_case("neutron star", CB.create(CB.Role.STAR, CB.Composition.NEUTRONIUM, 20.0), CB.BodyType.NEUTRON_STAR, CB.StarColour.NONE)
	_case("black hole", CB.create(CB.Role.STAR, CB.Composition.SINGULARITY, 30.0), CB.BodyType.BLACK_HOLE, CB.StarColour.NONE)
	_case("gas giant", CB.create(CB.Role.PLANET, CB.Composition.HYDROGEN, 140_000.0), CB.BodyType.GAS_GIANT, CB.StarColour.NONE)
	_case("rocky planet", CB.create(CB.Role.PLANET, CB.Composition.ROCKY, 6_800.0), CB.BodyType.ROCKY_PLANET, CB.StarColour.NONE)
	_case("terran planet", CB.create(CB.Role.PLANET, CB.Composition.ROCKY, 12_742.0, 3), CB.BodyType.TERRAN_PLANET, CB.StarColour.NONE)
	_case("neutronium planet", CB.create(CB.Role.PLANET, CB.Composition.NEUTRONIUM, 9_000.0), CB.BodyType.NEUTRONIUM_PLANET, CB.StarColour.NONE)

	# allowed property changes update the derived type
	var star: CB = CB.create(CB.Role.STAR, CB.Composition.HYDROGEN, 1_390_000.0, 0, "G2")
	star.composition = CB.Composition.SINGULARITY
	_check("sun -> singularity is a black hole", star.get_body_type(), CB.BodyType.BLACK_HOLE)
	star.composition = CB.Composition.HYDROGEN
	_check("black hole evaporated back is a sun again", star.get_body_type(), CB.BodyType.SUN)
	var planet: CB = CB.create(CB.Role.PLANET, CB.Composition.ROCKY, 12_742.0)
	planet.biosphere = 2
	_check("rocky + biosphere is terran", planet.get_body_type(), CB.BodyType.TERRAN_PLANET)
	planet.composition = CB.Composition.NEUTRONIUM
	_check("rocky -> neutronium planet", planet.get_body_type(), CB.BodyType.NEUTRONIUM_PLANET)

	# forbidden changes are refused and leave the body unchanged
	var gg: CB = CB.create(CB.Role.PLANET, CB.Composition.HYDROGEN, 140_000.0)
	gg.composition = CB.Composition.SINGULARITY
	_check("planet refuses singularity", gg.get_body_type(), CB.BodyType.GAS_GIANT)
	gg.role = CB.Role.STAR
	_check("gas giant can't be promoted to a sun", gg.get_body_type(), CB.BodyType.GAS_GIANT)
	gg.diameter_km = 2_000_000.0
	_check("size alone never makes a planet a sun", gg.get_body_type(), CB.BodyType.GAS_GIANT)
	var sun: CB = CB.create(CB.Role.STAR, CB.Composition.HYDROGEN, 1_390_000.0, 0, "G2")
	sun.composition = CB.Composition.ROCKY
	_check("star refuses rocky", sun.get_body_type(), CB.BodyType.SUN)
	_check("create rejects rocky star", CB.create(CB.Role.STAR, CB.Composition.ROCKY, 1_000.0), null)
	_check("create rejects singular planet", CB.create(CB.Role.PLANET, CB.Composition.SINGULARITY, 30.0), null)

	# saved resources load role before composition, so a black hole round-trips
	var path := "user://test_black_hole.tres"
	ResourceSaver.save(CB.create(CB.Role.STAR, CB.Composition.SINGULARITY, 30.0), path)
	var loaded: CB = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	_check("saved black hole loads as a black hole", loaded.get_body_type(), CB.BodyType.BLACK_HOLE)
	loaded.role = CB.Role.PLANET
	_check("loaded role is still fixed", loaded.role, CB.Role.STAR)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

	var rocky_m: float = CB.create(CB.Role.PLANET, CB.Composition.ROCKY, 10_000.0).get_mass()
	var neutron_m: float = CB.create(CB.Role.PLANET, CB.Composition.NEUTRONIUM, 10_000.0).get_mass()
	_check("same diameter, denser composition is heavier", neutron_m > rocky_m, true)

	print("RESULT: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(1 if failures > 0 else 0)

func _case(label: String, body: CB, expected_type: int, expected_colour: int) -> void:
	_check(label + " type", body.get_body_type(), expected_type)
	_check(label + " colour", body.get_star_colour(), expected_colour)

func _check(label: String, got, expected) -> void:
	var ok: bool = got == expected
	if not ok:
		failures += 1
	print("%s %s: got=%s expected=%s" % ["ok  " if ok else "FAIL", label, got, expected])
