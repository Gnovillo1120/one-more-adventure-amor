extends SceneTree
# Dev-only capture rig (software GL works under xvfb-run):
#   xvfb-run -a godot --path . --rendering-driver opengl3 --script tools/capture_3d.gd -- <out_prefix> [view_prefix]
var world
var cam: Camera3D
var frames := 0
var out := "/tmp/shot"
var only := ""
var views := []
var vi := 0
func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0: out = args[0]
	if args.size() > 1: only = args[1]
	root.size = Vector2i(1280, 720)
	var VW = load("res://scripts/voxel_world.gd")
	world = VW.new()
	root.add_child(world)
	cam = Camera3D.new(); cam.fov = 62; cam.far = 320
	root.add_child(cam); cam.current = true
	# name, cam pos, look target, quest (for mood), player pos
	views = [
		["a_pond_house", Vector3(9, 3.0, 11), Vector3(-9, 3.2, 5), 0],
		["b_torii_path", Vector3(4, 2.6, 14), Vector3(4, 3.4, -9), 0],
		["c_farms", Vector3(3, 3.0, 13), Vector3(17, 2.5, 2), 0],
		["d_cave", Vector3(-15, 2.4, -2), Vector3(-15, 2.4, -18), 0],
		["e_wide", Vector3(5, 19, 25), Vector3(0, 0, -8), 0],
		["f_pagoda", Vector3(-24, 9, 21), Vector3(-49, 14, -27), 0],
		["g_hero", Vector3(-1.5, 1.7, 12.6), Vector3(.0, 1.25, 15.5), 0],
		["g2_hero_side", Vector3(-3.2, 1.5, 17.4), Vector3(.0, 1.25, 15.5), 0],
		["h_end", Vector3(52, 3.2, 9), Vector3(75, 3.5, -6), 8],
		["i_end_hero", Vector3(66.5, 2.4, 2), Vector3(75, 1.6, -9), 9],
		["j_guillermo_caged", Vector3(70.6, 1.7, -7.2), Vector3(75, 1.3, -10), 9],
		["k_guillermo_freed", Vector3(70.6, 1.7, -7.2), Vector3(75, 1.3, -10), 11],
		["l_walk", Vector3(14, 1.4, -14.2), Vector3(14, 1.0, -17), 0, "walk", Vector3(14, 0, -17)],
		["m_swing", Vector3(14, 1.6, -14.2), Vector3(14, 1.2, -17), 0, "swing", Vector3(14, 0, -17)],
	]
	if only != "":
		views = views.filter(func(v): return v[0].begins_with(only))
func _process(delta: float) -> bool:
	frames += 1
	if vi >= views.size():
		quit(); return false
	var v = views[vi]
	if frames == 2:
		world.camera.current = false
		cam.make_current()
		world.quest_index = v[3]
		world._update_atmosphere(true)
		# put the hero where the hero shot expects her
		if v.size() > 5:
			world.player.position = v[5]
		else:
			world.player.position = (Vector3(0, 0, 15.5) if v[0].begins_with('g') else Vector3(30, 0, -22)) if v[3] == 0 else Vector3(66, 0.5, 4)
		world.player_art.rotation.y = -PI * .5 if v.size() > 4 else 0.0
		if v[3] == 11:
			world._free_guillermo()
		cam.position = v[1]
		cam.look_at(v[2], Vector3.UP)
	if frames == 10 and v.size() > 4:
		world.set_physics_process(false)
	if frames == 12 and v.size() > 4:
		var C = load("res://scripts/voxel_chars.gd")
		for i in range(60):
			C.animate_humanoid(world.player_art, 0.34, 1.0 if v[4] == "walk" else 0.0, 0.62 if v[4] == "swing" else 0.0)
	if frames == 13 and vi == 0:
		print("ACTIVE CAM: ", root.get_camera_3d().get_path(), " pos ", root.get_camera_3d().global_position, " mine ", cam.global_position, " cur ", cam.current)
	if frames == 14 and v.size() > 4:
		print("rot=", world.player_art.rotation.y, " global=", world.player_art.global_rotation.y, " pos=", world.player.global_position, " cam=", cam.global_position)
	if frames == 14:
		var img := root.get_texture().get_image()
		img.save_png("%s_%s.png" % [out, v[0]])
		world.set_physics_process(true)
		print("saved ", v[0], "  draws=", RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME), " tris=", RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME))
		vi += 1
		frames = 0
	return false
