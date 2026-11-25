class_name SystemLayout
extends RefCounted

## Pure maths for laying out one system in the flight scene: orbit radii and
## periods, where every body is at a given calendar time, flight masses and
## draw sizes. No nodes, so the flight scene and the tests share one source
## of truth.
##
## Key rule: a planet's position is a function of TimeSystem.calendar_time,
## never accumulated frame by frame. A jump that skips calendar time puts
## the planets where they should be with no extra handling.

## Star at the scene origin. Planets orbit in system.planets order,
## innermost first.
const FIRST_ORBIT_RADIUS := 110.0
const ORBIT_SPACING := 70.0

## Calendar seconds for the innermost planet to go round once -- the
## tunable orbital speed. Outer periods follow Kepler's third law.
const INNER_ORBIT_PERIOD := 20.0

## Used in place of an outermost orbit when a system has no planets.
const EMPTY_SYSTEM_RADIUS := 60.0
## The black hole sits this far beyond the outermost orbit, standing still:
## "outside the system but attached to it".
const BLACK_HOLE_MARGIN := 90.0
const BLACK_HOLE_TRIGGER_RADIUS := 24.0
## Where the ship arrives, just outside the outermost orbit, opposite the
## black hole.
const ENTRY_MARGIN := 45.0

## The ship's camera follows it; this is its zoom (below 1 = zoomed out).
## Tuned so a 4-planet system's outermost orbit and black hole fit on a
## 1152x648 screen with the camera on the star.
const FLIGHT_CAMERA_ZOOM := 0.65

## Game-tuned gravity, one mass per body type. CelestialBody.get_mass()
## isn't used: at generated sizes it ranks a black hole below a gas giant.
## Order matters more than the numbers: star > black hole > any planet.
const FLIGHT_MASS := {
	CelestialBody.BodyType.SUN: 4_000_000.0,
	CelestialBody.BodyType.NEUTRON_STAR: 4_000_000.0,
	CelestialBody.BodyType.BLACK_HOLE: 2_000_000.0,
	CelestialBody.BodyType.GAS_GIANT: 400_000.0,
	CelestialBody.BodyType.NEUTRONIUM_PLANET: 250_000.0,
	CelestialBody.BodyType.ROCKY_PLANET: 100_000.0,
	CelestialBody.BodyType.TERRAN_PLANET: 100_000.0,
}

## Draw radius in pixels (also the gravity softening radius), interpolated
## by diameter_km within each kind's generated range.
const STAR_DRAW_RADIUS := Vector2(16.0, 36.0)
const PLANET_DRAW_RADIUS := {
	CelestialBody.Composition.HYDROGEN: Vector2(10.0, 16.0),
	CelestialBody.Composition.ROCKY: Vector2(5.0, 9.0),
	CelestialBody.Composition.NEUTRONIUM: Vector2(3.0, 5.0),
}

## Placeholder colours borrowed from the Grid legend in the reference doc.
const STAR_COLOURS := {
	CelestialBody.StarColour.BLUE: Color(0.55, 0.7, 1.0),
	CelestialBody.StarColour.GREEN: Color(0.55, 1.0, 0.5),
	CelestialBody.StarColour.RED: Color(1.0, 0.4, 0.3),
	CelestialBody.StarColour.NONE: Color(1.0, 0.7, 0.2),
}
const PLANET_COLOURS := {
	CelestialBody.BodyType.TERRAN_PLANET: Color(0.2, 0.9, 1.0),
	CelestialBody.BodyType.ROCKY_PLANET: Color(0.6, 0.42, 0.25),
	CelestialBody.BodyType.GAS_GIANT: Color(0.85, 0.3, 0.85),
	CelestialBody.BodyType.NEUTRONIUM_PLANET: Color(0.7, 0.7, 0.75),
}

static func orbit_radius(index: int) -> float:
	return FIRST_ORBIT_RADIUS + index * ORBIT_SPACING

## Kepler's third law: period grows with radius^1.5, so outer planets are
## slower.
static func orbit_period(index: int) -> float:
	return INNER_ORBIT_PERIOD * pow(orbit_radius(index) / FIRST_ORBIT_RADIUS, 1.5)

static func outermost_radius(system: StarSystem) -> float:
	if system.planets.is_empty():
		return EMPTY_SYSTEM_RADIUS
	return orbit_radius(system.planets.size() - 1)

static func planet_angle(system: StarSystem, index: int, calendar_time: float) -> float:
	# fmod keeps precision once calendar_time gets large
	return _phase(system.name + "#planet%d" % index) + TAU * fmod(calendar_time / orbit_period(index), 1.0)

static func planet_position(system: StarSystem, index: int, calendar_time: float) -> Vector2:
	return Vector2.RIGHT.rotated(planet_angle(system, index, calendar_time)) * orbit_radius(index)

static func black_hole_angle(system: StarSystem) -> float:
	return _phase(system.name + "#black_hole")

static func black_hole_distance(system: StarSystem) -> float:
	return outermost_radius(system) + BLACK_HOLE_MARGIN

static func black_hole_position(system: StarSystem) -> Vector2:
	return Vector2.RIGHT.rotated(black_hole_angle(system)) * black_hole_distance(system)

## Opposite the black hole, so the ship doesn't arrive next to it.
static func entry_point(system: StarSystem) -> Vector2:
	return Vector2.RIGHT.rotated(black_hole_angle(system) + PI) * (outermost_radius(system) + ENTRY_MARGIN)

## Speed for a circular orbit around the star at the entry point, in the
## same direction the planets go (angle increasing).
static func entry_velocity(system: StarSystem) -> Vector2:
	var at := entry_point(system)
	var speed := sqrt(flight_mass(system.star) / at.length())
	return at.normalized().rotated(PI / 2.0) * speed

static func flight_mass(body: CelestialBody) -> float:
	return FLIGHT_MASS[body.get_body_type()]

static func draw_radius(body: CelestialBody) -> float:
	if body.role == CelestialBody.Role.STAR:
		if body.composition == CelestialBody.Composition.SINGULARITY:
			return BLACK_HOLE_TRIGGER_RADIUS
		# star sizes span two orders of magnitude, so interpolate on a log scale
		var smallest: float = GalaxyGenerator.STAR_DIAMETER_KM["M"].x
		var largest: float = GalaxyGenerator.STAR_DIAMETER_KM["O"].y
		var t := inverse_lerp(log(smallest), log(largest), log(max(body.diameter_km, 1.0)))
		return lerpf(STAR_DRAW_RADIUS.x, STAR_DRAW_RADIUS.y, clampf(t, 0.0, 1.0))
	var range_km: Vector2 = GalaxyGenerator.PLANET_DIAMETER_KM[body.composition]
	var range_px: Vector2 = PLANET_DRAW_RADIUS[body.composition]
	var t := inverse_lerp(range_km.x, range_km.y, body.diameter_km)
	return lerpf(range_px.x, range_px.y, clampf(t, 0.0, 1.0))

static func body_colour(body: CelestialBody) -> Color:
	if body.role == CelestialBody.Role.STAR:
		return STAR_COLOURS[body.get_star_colour()]
	return PLANET_COLOURS[body.get_body_type()]

## Fixed starting angle from a stable hash: deterministic per system and
## body, with nothing extra stored in the galaxy data.
static func _phase(key: String) -> float:
	return float(posmod(key.hash(), 3600)) / 3600.0 * TAU
