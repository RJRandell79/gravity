class_name CelestialBody
extends Resource

## One data model for every star, planet and black hole, built on the
## original game's three body properties. Body type, star colour and mass
## are always derived -- there is deliberately no stored "type" field that
## could fall out of sync with the properties.

## Ordered as the original's composition ladder (cheapest changes at the
## Hydrogen end, most expensive at the Singularity end).
enum Composition { HYDROGEN, ROCKY, NEUTRONIUM, SINGULARITY }

## A body's place in its system. Fixed once set: a gas giant can never
## become a sun, and a planet can never collapse into a singularity.
enum Role { STAR, PLANET }

enum BodyType { SUN, NEUTRON_STAR, BLACK_HOLE, GAS_GIANT, ROCKY_PLANET, TERRAN_PLANET, NEUTRONIUM_PLANET }

## Matches the original's Grid legend for suns.
enum StarColour { NONE, BLUE, GREEN, RED }

const ALLOWED_COMPOSITIONS := {
	Role.STAR: [Composition.HYDROGEN, Composition.NEUTRONIUM, Composition.SINGULARITY],
	Role.PLANET: [Composition.HYDROGEN, Composition.ROCKY, Composition.NEUTRONIUM],
}

## Not settled by the original-game reference; follows real stellar
## temperatures: hot O/B/A blue, Sol-like F/G green, cool K/M red.
const SPECTRAL_COLOURS := {
	"O": StarColour.BLUE, "B": StarColour.BLUE, "A": StarColour.BLUE,
	"F": StarColour.GREEN, "G": StarColour.GREEN,
	"K": StarColour.RED, "M": StarColour.RED,
}

## Relative densities for a simple mass value only -- real tuning is out
## of scope until bodies actually exert gravity in flight.
const DENSITY := {
	Composition.HYDROGEN: 1.0,
	Composition.ROCKY: 4.0,
	Composition.NEUTRONIUM: 1.0e6,
	Composition.SINGULARITY: 1.0e9,
}

var _role_fixed := false

## Must stay declared before composition: saved resources load properties
## in declaration order, and composition is validated against the role.
@export var role: Role = Role.PLANET:
	set(value):
		if _role_fixed and value != role:
			push_error("CelestialBody: role is fixed -- a planet can never become a star, or vice versa")
			return
		role = value
		_role_fixed = true

## Hydrogen by default because it's the one composition valid for both roles.
@export var composition: Composition = Composition.HYDROGEN:
	set(value):
		if not ALLOWED_COMPOSITIONS[role].has(value):
			push_error("CelestialBody: a %s can't have %s composition" % [Role.keys()[role], Composition.keys()[value]])
			return
		composition = value

@export var diameter_km: float = 140_000.0
@export var biosphere: int = 0
## Stars only, e.g. "F5" or "M2". Ignored for every other body type.
@export var spectral_class: String = ""

static func is_allowed(p_role: Role, p_composition: Composition) -> bool:
	return ALLOWED_COMPOSITIONS[p_role].has(p_composition)

## Returns null for a role/composition pair the rules don't allow.
static func create(p_role: Role, p_composition: Composition, p_diameter_km: float, p_biosphere: int = 0, p_spectral_class: String = "") -> CelestialBody:
	if not is_allowed(p_role, p_composition):
		push_error("CelestialBody: a %s can't have %s composition" % [Role.keys()[p_role], Composition.keys()[p_composition]])
		return null
	var body := CelestialBody.new()
	body.role = p_role
	body.composition = p_composition
	body.diameter_km = p_diameter_km
	body.biosphere = p_biosphere
	body.spectral_class = p_spectral_class
	return body

func get_body_type() -> BodyType:
	if role == Role.STAR:
		match composition:
			Composition.NEUTRONIUM:
				return BodyType.NEUTRON_STAR
			Composition.SINGULARITY:
				return BodyType.BLACK_HOLE
			_:
				return BodyType.SUN
	match composition:
		Composition.ROCKY:
			return BodyType.TERRAN_PLANET if biosphere > 0 else BodyType.ROCKY_PLANET
		Composition.NEUTRONIUM:
			return BodyType.NEUTRONIUM_PLANET
		_:
			return BodyType.GAS_GIANT

func get_star_colour() -> StarColour:
	if get_body_type() != BodyType.SUN or spectral_class.is_empty():
		return StarColour.NONE
	return SPECTRAL_COLOURS.get(spectral_class.substr(0, 1).to_upper(), StarColour.NONE)

func get_mass() -> float:
	var radius := diameter_km / 2.0
	return DENSITY[composition] * radius * radius * radius
