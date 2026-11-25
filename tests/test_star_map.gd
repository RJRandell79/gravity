extends SceneTree

## Headless smoke test of the star map against the generated galaxy:
## godot --headless --path . -s tests/test_star_map.gd
## (Covers what a headless run can: data -> scene wiring, picking and the
## travel handoff. Colours and layout still need a look in Run in Browser.)

var failures := 0

func _initialize() -> void:
	# autoloads (GalaxyState, NavState) only run _ready after _initialize
	await process_frame
	var galaxy: Galaxy = root.get_node("GalaxyState").galaxy
	var nav: Node = root.get_node("NavState")
	_check("galaxy autoload generated 128 systems", galaxy.systems.size(), 128)

	var map: Node3D = load("res://star_map.tscn").instantiate()
	root.add_child(map)
	await physics_frame
	await physics_frame
	await process_frame

	_check("one star body per system", map.stars.size(), 128)

	var holes := 0
	var homes := 0
	var colours_ok := true
	for i in range(galaxy.systems.size()):
		var sys: StarSystem = galaxy.systems[i]
		var body: StaticBody3D = map.stars[i]
		if body.has_node("BlackHoleBlip") != sys.has_black_hole():
			colours_ok = false
		if body.has_node("HomeRing") != sys.is_home:
			colours_ok = false
		if body.has_node("BlackHoleBlip"):
			holes += 1
		if body.has_node("HomeRing"):
			homes += 1
		var mesh_instance: MeshInstance3D = body.get_child(0)
		var colour: Color = mesh_instance.mesh.material.albedo_color
		if colour != map.STATUS_COLOURS[sys.status]:
			colours_ok = false
		if not body.position.is_equal_approx(sys.position):
			colours_ok = false
		if map.get_system(body) != sys:
			colours_ok = false
	_check("blips, home ring, colour and position all come from generated data", colours_ok, true)
	_check("blip count matches systems with a black hole", holes, _count_holes(galaxy))
	_check("exactly one home ring", homes, 1)

	# select the home star by projecting it to the screen and clicking there
	var home_body: StaticBody3D = map.stars[galaxy.home_index]
	var screen_pos: Vector2 = map.camera.unproject_position(home_body.global_position)
	var picked: StaticBody3D = map.pick_star_at_screen_pos(screen_pos)
	_check("picking the home star's screen position selects it", picked, home_body)

	# orbit: markers are re-aimed at the camera without errors
	map.yaw = 1.2
	map.pitch = 0.5
	map._update_camera()
	var picked_after: StaticBody3D = map.pick_star_at_screen_pos(map.camera.unproject_position(home_body.global_position))
	_check("picking still works after orbiting", picked_after, home_body)

	# travel handoff: confirming a selection hands its system to the flight
	# scene, which consumes it and builds that system. Use a non-home system
	# so the flight scene's home fallback can't pass by accident.
	var target_index := (galaxy.home_index + 1) % galaxy.systems.size()
	map.selected_star = map.stars[target_index]
	map._confirm_travel()
	_check("confirming travel hands over the selected system", nav.pending_system_index, target_index)
	await process_frame
	await process_frame
	var flight: Node = null
	for child in root.get_children():
		if child.has_node("Ship"):
			flight = child
	_check("travel loaded the flight scene", flight != null, true)
	if flight != null:
		_check("flight scene built the selected system", flight.system, galaxy.systems[target_index])
	_check("pending system was consumed", nav.has_pending_system(), false)

	print("RESULT: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(1 if failures > 0 else 0)

func _count_holes(galaxy: Galaxy) -> int:
	var n := 0
	for sys in galaxy.systems:
		if sys.has_black_hole():
			n += 1
	return n

func _check(label: String, got, expected) -> void:
	var ok: bool = got == expected
	if not ok:
		failures += 1
	print("%s %s: got=%s expected=%s" % ["ok  " if ok else "FAIL", label, got, expected])
