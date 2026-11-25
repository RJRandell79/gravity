class_name GalaxyGenerator
extends RefCounted

## Builds a Galaxy from a seed. A pure static function with no autoload or
## scene-tree dependency, so headless test scripts can call it directly.
##
## Determinism rule: everything random comes from the one seeded
## RandomNumberGenerator below, called in a fixed order. Nothing here may
## touch the global randf()/randi()/shuffle(), or the same seed would stop
## giving the same galaxy.

const SYSTEM_COUNT := 128

## The original drew its galaxy from 65,536 possible permutations; seeds
## wrap into that range so a seed number means the same thing as in the
## original.
const SEED_COUNT := 65536

## Fraction of systems that get a black hole (the home system always does).
const BLACK_HOLE_CHANCE := 0.8

## Edge length of the star map's cube. The star map builds its wireframe
## from this, so the generator and the map can't disagree.
const CUBE_SIZE := 6.0
## No two stars closer than this, so every star stays individually clickable.
const MIN_SPACING := 0.5
const MAX_PLACEMENT_ATTEMPTS := 200
## Scale of the cube, for distance_ly. The cube's corner-to-corner span is
## about 10.4 cube units, so roughly 52 light years.
const LY_PER_CUBE_UNIT := 5.0

const MAX_PLANETS := 4
## Weight of 0, 1, 2, 3 and 4 planets (index = planet count).
const PLANET_COUNT_WEIGHTS := [1.0, 2.0, 3.0, 2.0, 1.0]

## Relative likelihood of each planet composition: gas giant, rocky,
## neutronium. Neutronium planets are rare.
const PLANET_COMPOSITION_WEIGHTS := {
	CelestialBody.Composition.HYDROGEN: 35.0,
	CelestialBody.Composition.ROCKY: 62.0,
	CelestialBody.Composition.NEUTRONIUM: 3.0,
}

## Chance that a rocky planet is Terran (has a biosphere).
const TERRAN_CHANCE := 0.15
const BIOSPHERE_MIN := 1
const BIOSPHERE_MAX := 3

const PLANET_DIAMETER_KM := {
	CelestialBody.Composition.HYDROGEN: Vector2(50_000.0, 150_000.0),
	CelestialBody.Composition.ROCKY: Vector2(3_000.0, 15_000.0),
	CelestialBody.Composition.NEUTRONIUM: Vector2(500.0, 5_000.0),
}

## Star diameter by spectral letter, loosely following real main-sequence
## sizes (the Sun, class G, is about 1.39 million km).
const STAR_DIAMETER_KM := {
	"O": Vector2(9_000_000.0, 15_000_000.0),
	"B": Vector2(2_500_000.0, 9_000_000.0),
	"A": Vector2(2_000_000.0, 2_500_000.0),
	"F": Vector2(1_600_000.0, 1_950_000.0),
	"G": Vector2(1_330_000.0, 1_600_000.0),
	"K": Vector2(970_000.0, 1_330_000.0),
	"M": Vector2(200_000.0, 970_000.0),
}

const BLACK_HOLE_DIAMETER_KM := Vector2(20.0, 60.0)

static func generate(p_seed: int) -> Galaxy:
	var galaxy_seed := posmod(p_seed, SEED_COUNT)
	var rng := RandomNumberGenerator.new()
	rng.seed = galaxy_seed

	var galaxy := Galaxy.new()
	galaxy.seed = galaxy_seed

	var catalogue_order := _shuffled_catalogue_indices(rng)
	for i in range(SYSTEM_COUNT):
		var system := _make_system(rng, catalogue_order[i], galaxy.systems)
		galaxy.systems.append(system)

	galaxy.home_index = rng.randi_range(0, SYSTEM_COUNT - 1)
	_make_home(rng, galaxy)
	_post_process(rng, galaxy)
	return galaxy

## Hook for later passes that need the finished galaxy, e.g. making sure the
## home system always has reachable jump destinations (#16). Deliberately
## empty for now; anything added here must keep using `rng` so seeds stay
## reproducible.
static func _post_process(_rng: RandomNumberGenerator, _galaxy: Galaxy) -> void:
	pass

# Fisher-Yates with our own rng. Array.shuffle() would use the global one.
static func _shuffled_catalogue_indices(rng: RandomNumberGenerator) -> Array[int]:
	var order: Array[int] = []
	for i in range(StarCatalogue.size()):
		order.append(i)
	for i in range(order.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp := order[i]
		order[i] = order[j]
		order[j] = tmp
	return order

static func _make_system(rng: RandomNumberGenerator, catalogue_index: int, placed: Array[StarSystem]) -> StarSystem:
	var system := StarSystem.new()
	system.name = StarCatalogue.star_name(catalogue_index)
	system.position = _pick_position(rng, placed)
	system.star = _make_star(rng, StarCatalogue.spectral_class(catalogue_index))

	var planet_count := _weighted_index(rng, PLANET_COUNT_WEIGHTS)
	for i in range(planet_count):
		system.planets.append(_make_planet(rng))

	if rng.randf() < BLACK_HOLE_CHANCE:
		system.black_hole = _make_black_hole(rng)
	return system

static func _pick_position(rng: RandomNumberGenerator, placed: Array[StarSystem]) -> Vector3:
	var half := CUBE_SIZE / 2.0
	var candidate := Vector3.ZERO
	for attempt in range(MAX_PLACEMENT_ATTEMPTS):
		candidate = Vector3(
			rng.randf_range(-half, half),
			rng.randf_range(-half, half),
			rng.randf_range(-half, half)
		)
		var clear := true
		for other in placed:
			if other.position.distance_to(candidate) < MIN_SPACING:
				clear = false
				break
		if clear:
			return candidate
	push_error("GalaxyGenerator: no clear spot after %d attempts -- raise CUBE_SIZE or lower MIN_SPACING" % MAX_PLACEMENT_ATTEMPTS)
	return candidate

static func _make_star(rng: RandomNumberGenerator, spectral_class: String) -> CelestialBody:
	var range_km: Vector2 = STAR_DIAMETER_KM[spectral_class.substr(0, 1)]
	var diameter := rng.randf_range(range_km.x, range_km.y)
	return CelestialBody.create(CelestialBody.Role.STAR, CelestialBody.Composition.HYDROGEN, diameter, 0, spectral_class)

static func _make_planet(rng: RandomNumberGenerator) -> CelestialBody:
	var composition: CelestialBody.Composition = _weighted_key(rng, PLANET_COMPOSITION_WEIGHTS)
	var range_km: Vector2 = PLANET_DIAMETER_KM[composition]
	var diameter := rng.randf_range(range_km.x, range_km.y)
	var biosphere := 0
	if composition == CelestialBody.Composition.ROCKY and rng.randf() < TERRAN_CHANCE:
		biosphere = rng.randi_range(BIOSPHERE_MIN, BIOSPHERE_MAX)
	return CelestialBody.create(CelestialBody.Role.PLANET, composition, diameter, biosphere)

static func _make_black_hole(rng: RandomNumberGenerator) -> CelestialBody:
	var diameter := rng.randf_range(BLACK_HOLE_DIAMETER_KM.x, BLACK_HOLE_DIAMETER_KM.y)
	return CelestialBody.create(CelestialBody.Role.STAR, CelestialBody.Composition.SINGULARITY, diameter)

## Marks the chosen system as home: guaranteed black hole and at least one
## Terran planet, starts Terran-occupied. Also fills in distance_ly for
## every system, measured from home.
static func _make_home(rng: RandomNumberGenerator, galaxy: Galaxy) -> void:
	var home := galaxy.systems[galaxy.home_index]
	home.is_home = true
	home.status = StarSystem.Status.TERRAN

	if not home.has_black_hole():
		home.black_hole = _make_black_hole(rng)

	if not home.has_terran_planet():
		var rocky_index := -1
		for i in range(home.planets.size()):
			if home.planets[i].composition == CelestialBody.Composition.ROCKY:
				rocky_index = i
				break
		if rocky_index >= 0:
			# a lifeless rocky planet becomes Terran
			home.planets[rocky_index].biosphere = rng.randi_range(BIOSPHERE_MIN, BIOSPHERE_MAX)
		else:
			var terran := _make_terran_planet(rng)
			if home.planets.size() < MAX_PLANETS:
				home.planets.append(terran)
			else:
				home.planets[0] = terran

	for system in galaxy.systems:
		system.distance_ly = system.position.distance_to(home.position) * LY_PER_CUBE_UNIT

static func _make_terran_planet(rng: RandomNumberGenerator) -> CelestialBody:
	var range_km: Vector2 = PLANET_DIAMETER_KM[CelestialBody.Composition.ROCKY]
	var diameter := rng.randf_range(range_km.x, range_km.y)
	var biosphere := rng.randi_range(BIOSPHERE_MIN, BIOSPHERE_MAX)
	return CelestialBody.create(CelestialBody.Role.PLANET, CelestialBody.Composition.ROCKY, diameter, biosphere)

static func _weighted_index(rng: RandomNumberGenerator, weights: Array) -> int:
	var total := 0.0
	for w in weights:
		total += w
	var roll := rng.randf() * total
	for i in range(weights.size()):
		roll -= weights[i]
		if roll < 0.0:
			return i
	return weights.size() - 1

# Dictionary iteration order is insertion order, so this is deterministic.
static func _weighted_key(rng: RandomNumberGenerator, weights: Dictionary) -> Variant:
	var total := 0.0
	for key in weights:
		total += weights[key]
	var roll := rng.randf() * total
	var last = null
	for key in weights:
		last = key
		roll -= weights[key]
		if roll < 0.0:
			return key
	return last
