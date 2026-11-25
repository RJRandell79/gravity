extends Node3D

## Navigable 3D cube star map: the generated galaxy's systems inside a
## wireframe cube, orbit/zoom camera, and click-to-select. Confirming a
## selection (ui_accept) hands the chosen system to NavState and switches to
## the flight scene, which builds that system.
##
## Holo Tank legend (from the original): star colour = system status
## (green Terran, red Outie, amber unknown), a small cyan blip beside the
## star = the system has a black hole, a cyan ring = home system.

const CUBE_SIZE := GalaxyGenerator.CUBE_SIZE

const STAR_RADIUS := 0.07
const STAR_PICK_RADIUS := 0.18 # larger than the visual sphere, easier to click
const BLIP_RADIUS := 0.035
const BLIP_OFFSET := Vector3(0.13, 0.13, 0.0) # up and right of the star, as seen from the camera
const HOME_RING_RADIUS := 0.17
const HOME_RING_THICKNESS := 0.012

const STATUS_COLOURS := {
	StarSystem.Status.TERRAN: Color(0.2, 0.9, 0.3),
	StarSystem.Status.OUTIE: Color(0.95, 0.2, 0.2),
	StarSystem.Status.UNKNOWN: Color(1.0, 0.75, 0.15),
}
const CYAN := Color(0.2, 0.9, 1.0)

const ZOOM_MIN := 4.0
const ZOOM_MAX := 20.0
const ORBIT_SPEED := 0.01
const ZOOM_STEP := 1.0

const FLIGHT_SCENE := "res://main.tscn"

@onready var camera_rig: Node3D = $CameraRig
@onready var camera: Camera3D = $CameraRig/Camera3D

## One body per generated system, in the same order as galaxy.systems.
var stars: Array[StaticBody3D] = []
var selected_star: StaticBody3D = null

var _blips: Array[MeshInstance3D] = []
var _home_rings: Array[MeshInstance3D] = []

var yaw := 0.0
var pitch := -0.4
var zoom := 10.0

var _dragging := false
var _drag_last := Vector2.ZERO

func _ready() -> void:
	_build_cube_wireframe()
	_spawn_stars()
	_update_camera()

func _build_cube_wireframe() -> void:
	var h := CUBE_SIZE / 2.0
	var corners := [
		Vector3(-h, -h, -h), Vector3(h, -h, -h), Vector3(h, h, -h), Vector3(-h, h, -h),
		Vector3(-h, -h, h), Vector3(h, -h, h), Vector3(h, h, h), Vector3(-h, h, h),
	]
	var edges := [
		[0, 1], [1, 2], [2, 3], [3, 0],
		[4, 5], [5, 6], [6, 7], [7, 4],
		[0, 4], [1, 5], [2, 6], [3, 7],
	]
	var points := PackedVector3Array()
	for edge in edges:
		points.append(corners[edge[0]])
		points.append(corners[edge[1]])

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = points
	var array_mesh := ArrayMesh.new()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)

	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0.35, 0.55, 0.9)
	array_mesh.surface_set_material(0, material)

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "CubeWireframe"
	mesh_instance.mesh = array_mesh
	add_child(mesh_instance)

func _spawn_stars() -> void:
	var galaxy: Galaxy = GalaxyState.galaxy
	for i in range(galaxy.systems.size()):
		var star := _make_star(i, galaxy.systems[i])
		add_child(star)
		stars.append(star)

func _make_star(index: int, system: StarSystem) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = "Star%d" % index
	body.position = system.position
	body.input_ray_pickable = true
	body.set_meta("system_index", index)

	var sphere := SphereMesh.new()
	sphere.radius = STAR_RADIUS
	sphere.height = STAR_RADIUS * 2.0
	sphere.material = _unshaded_material(STATUS_COLOURS[system.status])

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = sphere
	body.add_child(mesh_instance)

	var collision := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = STAR_PICK_RADIUS
	collision.shape = shape
	body.add_child(collision)

	if system.has_black_hole():
		var blip_mesh := SphereMesh.new()
		blip_mesh.radius = BLIP_RADIUS
		blip_mesh.height = BLIP_RADIUS * 2.0
		blip_mesh.material = _unshaded_material(CYAN)
		var blip := MeshInstance3D.new()
		blip.name = "BlackHoleBlip"
		blip.mesh = blip_mesh
		body.add_child(blip)
		_blips.append(blip)

	if system.is_home:
		var ring_mesh := TorusMesh.new()
		ring_mesh.inner_radius = HOME_RING_RADIUS - HOME_RING_THICKNESS
		ring_mesh.outer_radius = HOME_RING_RADIUS + HOME_RING_THICKNESS
		ring_mesh.material = _unshaded_material(CYAN)
		var ring := MeshInstance3D.new()
		ring.name = "HomeRing"
		ring.mesh = ring_mesh
		body.add_child(ring)
		_home_rings.append(ring)

	return body

func _unshaded_material(colour: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = colour
	return material

## The generated system behind a star body, or null.
func get_system(star: StaticBody3D) -> StarSystem:
	if star == null or not star.has_meta("system_index"):
		return null
	return GalaxyState.galaxy.systems[star.get_meta("system_index")]

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_RIGHT:
			_dragging = mb.pressed
			_drag_last = mb.position
		elif mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			_try_select(mb.position)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			_zoom_by(-ZOOM_STEP)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			_zoom_by(ZOOM_STEP)
	elif event is InputEventMouseMotion and _dragging:
		var mm := event as InputEventMouseMotion
		var delta: Vector2 = mm.position - _drag_last
		_drag_last = mm.position
		yaw -= delta.x * ORBIT_SPEED
		pitch = clamp(pitch - delta.y * ORBIT_SPEED, -1.4, 1.4)
		_update_camera()
	elif event is InputEventPanGesture:
		# trackpad two-finger scroll (macOS) arrives as a pan gesture, not
		# a mouse-wheel button event
		var pan := event as InputEventPanGesture
		_zoom_by(pan.delta.y * ZOOM_STEP)
	elif event is InputEventMagnifyGesture:
		# trackpad pinch (macOS): >1.0 = spreading fingers = zoom in
		var mag := event as InputEventMagnifyGesture
		_zoom_by(-(mag.factor - 1.0) * ZOOM_STEP * 5.0)
	elif event.is_action_pressed("ui_accept"):
		_confirm_travel()

func _confirm_travel() -> void:
	if selected_star == null:
		return
	# stars are in galaxy.systems order, so the star's index is the system's
	var index := stars.find(selected_star)
	NavState.set_pending_system(index)
	print("star map: confirmed travel to %s (%s) -- system %d" % [get_system(selected_star).name, selected_star.name, index])
	get_tree().change_scene_to_file(FLIGHT_SCENE)

func _update_camera() -> void:
	camera_rig.rotation = Vector3(pitch, yaw, 0.0)
	camera.position = Vector3(0, 0, zoom)
	_face_markers_to_camera()

## Keeps the black-hole blip in the star's top-right corner on screen and
## the home ring flat to the camera, however the cube is orbited. The star
## bodies sit in the map's own space, so the rig's basis is the camera's.
func _face_markers_to_camera() -> void:
	for blip in _blips:
		blip.position = camera_rig.basis * BLIP_OFFSET
	for ring in _home_rings:
		# a torus lies in its local XZ plane; turn it to face the camera
		ring.basis = camera_rig.basis * Basis(Vector3.RIGHT, PI / 2.0)

func _zoom_by(amount: float) -> void:
	var before := zoom
	zoom = clamp(zoom + amount, ZOOM_MIN, ZOOM_MAX)
	_update_camera()
	if zoom != before:
		print("star map: zoom %.1f -> %.1f" % [before, zoom])

func pick_star_at_screen_pos(screen_pos: Vector2) -> StaticBody3D:
	var space_state := get_world_3d().direct_space_state
	var from: Vector3 = camera.project_ray_origin(screen_pos)
	var to: Vector3 = from + camera.project_ray_normal(screen_pos) * 1000.0
	var query := PhysicsRayQueryParameters3D.create(from, to)
	var result := space_state.intersect_ray(query)
	if result and result.collider in stars:
		return result.collider
	return null

func _try_select(screen_pos: Vector2) -> void:
	var star := pick_star_at_screen_pos(screen_pos)
	if star:
		selected_star = star
		var system := get_system(star)
		print("star map: selected %s (%s) at %s, %.1f ly from home" % [system.name, star.name, star.position, system.distance_ly])
	else:
		print("star map: click at %s hit no star" % [screen_pos])
