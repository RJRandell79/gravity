extends Node3D

## Navigable 3D cube star map: placeholder star points inside a wireframe
## cube, orbit/zoom camera, and click-to-select. Map screen only -- no
## connection to flight yet (see #7).

const CUBE_SIZE := 6.0
const STAR_COUNT := 12
const STAR_SEED := 1

const ZOOM_MIN := 4.0
const ZOOM_MAX := 20.0
const ORBIT_SPEED := 0.01
const ZOOM_STEP := 1.0

@onready var camera_rig: Node3D = $CameraRig
@onready var camera: Camera3D = $CameraRig/Camera3D

var stars: Array[StaticBody3D] = []
var selected_star: StaticBody3D = null

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
	var rng := RandomNumberGenerator.new()
	rng.seed = STAR_SEED
	var h := CUBE_SIZE / 2.0
	for i in range(STAR_COUNT):
		var pos := Vector3(
			rng.randf_range(-h, h),
			rng.randf_range(-h, h),
			rng.randf_range(-h, h)
		)
		var star := _make_star(i, pos)
		add_child(star)
		stars.append(star)

func _make_star(index: int, pos: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = "Star%d" % index
	body.position = pos
	body.input_ray_pickable = true

	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(1.0, 0.9, 0.6)

	var sphere := SphereMesh.new()
	sphere.radius = 0.12
	sphere.height = 0.24
	sphere.material = material

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = sphere
	body.add_child(mesh_instance)

	var collision := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.3 # larger than the visual sphere, easier to click
	collision.shape = shape
	body.add_child(collision)

	return body

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

func _update_camera() -> void:
	camera_rig.rotation = Vector3(pitch, yaw, 0.0)
	camera.position = Vector3(0, 0, zoom)

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
		print("star map: selected %s at %s" % [star.name, star.position])
	else:
		print("star map: click at %s hit no star" % [screen_pos])
