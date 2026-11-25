class_name StarSystem
extends Resource

## One system on the Holo Tank: a star, 0-4 planets (no moons) and, in most
## systems, a black hole. A black hole is a second star-role body with
## singularity composition, kept apart from the sun so a system can have both.

## Holo Tank colour legend: green / red / amber.
enum Status { TERRAN, OUTIE, UNKNOWN }

## Shown as e.g. "Arcturus/Alpha Bootis".
@export var name: String = ""
## Inside the star map's cube, centred on the origin.
@export var position: Vector3 = Vector3.ZERO
## Measured from the home system, so home itself is 0.
@export var distance_ly: float = 0.0
@export var star: CelestialBody
@export var planets: Array[CelestialBody] = []
## null = this system has no black hole.
@export var black_hole: CelestialBody
@export var status: Status = Status.UNKNOWN
@export var is_home: bool = false

func has_black_hole() -> bool:
	return black_hole != null

func has_terran_planet() -> bool:
	for planet in planets:
		if planet.get_body_type() == CelestialBody.BodyType.TERRAN_PLANET:
			return true
	return false

## Plain-data form, for comparing two galaxies and for test output.
func to_dict() -> Dictionary:
	var planet_dicts: Array = []
	for planet in planets:
		planet_dicts.append(_body_to_dict(planet))
	return {
		"name": name,
		"position": [position.x, position.y, position.z],
		"distance_ly": distance_ly,
		"star": _body_to_dict(star),
		"planets": planet_dicts,
		"black_hole": _body_to_dict(black_hole),
		"status": status,
		"is_home": is_home,
	}

static func _body_to_dict(body: CelestialBody) -> Variant:
	if body == null:
		return null
	return {
		"role": body.role,
		"composition": body.composition,
		"diameter_km": body.diameter_km,
		"biosphere": body.biosphere,
		"spectral_class": body.spectral_class,
	}
