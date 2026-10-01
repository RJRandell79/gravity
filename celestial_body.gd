class_name CelestialBody
extends Resource

## One data model for every star, planet and black hole, built on the
## original game's three body properties. Body type, star colour and mass
## are always derived from the properties -- there is deliberately no
## stored "type" field that could fall out of sync with them.

## Ordered as the original's composition ladder (cheapest changes at the
## Hydrogen end, most expensive at the Singularity end).
enum Composition { HYDROGEN, ROCKY, NEUTRONIUM, SINGULARITY }

enum BodyType { SUN, GAS_GIANT, ROCKY_PLANET, TERRAN_PLANET, NEUTRON_STAR, BLACK_HOLE }

## Matches the original's Grid legend for suns.
enum StarColour { NONE, BLUE, GREEN, RED }

## Not specified by the original-game reference; Jupiter is ~140,000 km
## and the Sun ~1,390,000 km, so this sits comfortably between them.
const STAR_DIAMETER_THRESHOLD_KM := 300_000.0

## Leading spectral letter -> Grid legend colour. Also an assumption, from
## real stellar temperatures: hot O/B/A blue, Sol-like F/G green, cool K/M red.
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

@export var composition: Composition = Composition.ROCKY
@export var diameter_km: float = 12_742.0
@export var biosphere: int = 0
## Stars only, e.g. "F5" or "M2". Ignored for every other body type.
@export var spectral_class: String = ""

static func create(p_composition: Composition, p_diameter_km: float, p_biosphere: int = 0, p_spectral_class: String = "") -> CelestialBody:
	var body := CelestialBody.new()
	body.composition = p_composition
	body.diameter_km = p_diameter_km
	body.biosphere = p_biosphere
	body.spectral_class = p_spectral_class
	return body

func get_body_type() -> BodyType:
	match composition:
		Composition.HYDROGEN:
			return BodyType.SUN if diameter_km >= STAR_DIAMETER_THRESHOLD_KM else BodyType.GAS_GIANT
		Composition.ROCKY:
			return BodyType.TERRAN_PLANET if biosphere > 0 else BodyType.ROCKY_PLANET
		Composition.NEUTRONIUM:
			return BodyType.NEUTRON_STAR
		_:
			return BodyType.BLACK_HOLE

func get_star_colour() -> StarColour:
	if get_body_type() != BodyType.SUN or spectral_class.is_empty():
		return StarColour.NONE
	return SPECTRAL_COLOURS.get(spectral_class.substr(0, 1).to_upper(), StarColour.NONE)

func get_mass() -> float:
	var radius := diameter_km / 2.0
	return DENSITY[composition] * radius * radius * radius
