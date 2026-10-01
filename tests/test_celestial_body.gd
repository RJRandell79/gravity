extends SceneTree

const CB := preload("res://celestial_body.gd")

var failures := 0

func _initialize() -> void:
	_case("blue sun", CB.create(CB.Composition.HYDROGEN, 1_800_000.0, 0, "B3"), CB.BodyType.SUN, CB.StarColour.BLUE)
	_case("green sun", CB.create(CB.Composition.HYDROGEN, 1_390_000.0, 0, "G2"), CB.BodyType.SUN, CB.StarColour.GREEN)
	_case("red sun", CB.create(CB.Composition.HYDROGEN, 600_000.0, 0, "M2"), CB.BodyType.SUN, CB.StarColour.RED)
	_case("gas giant", CB.create(CB.Composition.HYDROGEN, 140_000.0), CB.BodyType.GAS_GIANT, CB.StarColour.NONE)
	_case("rocky planet", CB.create(CB.Composition.ROCKY, 6_800.0, 0), CB.BodyType.ROCKY_PLANET, CB.StarColour.NONE)
	_case("terran planet", CB.create(CB.Composition.ROCKY, 12_742.0, 3), CB.BodyType.TERRAN_PLANET, CB.StarColour.NONE)
	_case("neutron star", CB.create(CB.Composition.NEUTRONIUM, 20.0), CB.BodyType.NEUTRON_STAR, CB.StarColour.NONE)
	_case("black hole", CB.create(CB.Composition.SINGULARITY, 30.0), CB.BodyType.BLACK_HOLE, CB.StarColour.NONE)

	# property changes must change the derived type
	var body: CB = CB.create(CB.Composition.ROCKY, 12_742.0, 0)
	_check("mutate: start rocky", body.get_body_type(), CB.BodyType.ROCKY_PLANET)
	body.biosphere = 2
	_check("mutate: biosphere 0 -> 2", body.get_body_type(), CB.BodyType.TERRAN_PLANET)
	body.composition = CB.Composition.SINGULARITY
	_check("mutate: rocky -> singularity", body.get_body_type(), CB.BodyType.BLACK_HOLE)
	var gg: CB = CB.create(CB.Composition.HYDROGEN, 140_000.0, 0, "G2")
	_check("mutate: gas giant ignores spectral", gg.get_star_colour(), CB.StarColour.NONE)
	gg.diameter_km = 1_390_000.0
	_check("mutate: gas giant grown -> sun", gg.get_body_type(), CB.BodyType.SUN)
	_check("mutate: grown sun picks up colour", gg.get_star_colour(), CB.StarColour.GREEN)

	var rocky_m: float = CB.create(CB.Composition.ROCKY, 10_000.0).get_mass()
	var neutron_m: float = CB.create(CB.Composition.NEUTRONIUM, 10_000.0).get_mass()
	_check("mass: same diameter, denser composition is heavier", neutron_m > rocky_m, true)

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
