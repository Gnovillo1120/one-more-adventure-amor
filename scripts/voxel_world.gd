extends Node3D

const Style = preload("res://scripts/voxel_style.gd")
const Chars = preload("res://scripts/voxel_chars.gd")

signal finished
signal message_requested(lines: Array)
signal objective_changed(text: String)

var health: float = 100.0
var max_health: float = 100.0
var quest_index: int = 0
var active: bool = true
var player: CharacterBody3D
var pivot: Node3D
var camera: Camera3D
var cat: Node3D
var boss: Node3D
var cage: Node3D
var sword: Node3D
var player_art: Node3D
var enemies: Array = []
var targets: Dictionary = {}
var materials: Dictionary = {}
var marker_labels: Dictionary = {}
var target_objects: Dictionary = {}
var danger_ring: MeshInstance3D
var world_environment: Environment
var daylight: DirectionalLight3D
var sky_material: ShaderMaterial
var mood_t: float = 0.0
var mood_target: float = 0.0
var terrain_data: Dictionary = {}
var petals: GPUParticles3D
var animated: Array = []
var switches: Array = [false, false, false]
var memories: Array = [false, false, false, false]
var yaw: float = 0.0
var pitch: float = -0.3
var attack_timer: float = 0.0
var hurt_timer: float = 0.0
var time: float = 0.0
var boss_phase: int = 0
var pulse_timer: float = 8.0
var boss_health: int = 4
var respawn: Vector3 = Vector3(0, 1, 8)
var goals: Array = ["Busca pescado en el estanque de la casa. [E]", "Lleva el pescado al gato junto a la casa. [E]", "Sigue al gato hasta el salón de aldeanos. [E]", "Activa las tres granjas: caña, hierro y cultivos. [E]", "Vuelve al aldeano para abrir el sendero. [E]", "Despeja la cueva: clic izquierdo para atacar.", "Cruza el portal de la cascada. [E]", "Activa el puente seguro hacia la isla del End. [E]", "Derrota las sombras del Olvidado.", "Activa los cuatro recuerdos alrededor del cristal. [E]", "Golpea al Olvidado y libera a Guillermo.", "Habla con Guillermo y vuelve a casa. [E]"]

func _ready() -> void:
	_build_world()
	_emit_goal()

func set_active(value: bool) -> void:
	active = value

func _mat(key: String, color: Color) -> Material:
	return Style.toon(color)

func _box(pos: Vector3, size: Vector3, color: Color, solid: bool = false, parent: Node3D = null) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var cube := BoxMesh.new()
	cube.size = size
	mesh.mesh = cube
	mesh.material_override = _mat(str(color), color)
	mesh.position = pos
	if size.x * size.y * size.z < 0.3:
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var host: Node3D = self if parent == null else parent
	host.add_child(mesh)
	if solid:
		var body := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = size
		shape.shape = box
		body.position = pos
		body.add_child(shape)
		host.add_child(body)
	return mesh

func _label(pos: Vector3, text: String) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.position = pos
	l.font_size = 44
	l.pixel_size = 0.0085
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.outline_size = 14
	l.outline_modulate = Color(0.2, 0.1, 0.22, 0.95)
	l.modulate = Color("fff0f4")
	l.no_depth_test = false
	l.fixed_size = false
	add_child(l)
	return l

func _glass(pos: Vector3, size: Vector3, tint: Color = Color(0.7, 0.92, 1.0, 0.28)) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var cube := BoxMesh.new()
	cube.size = size
	mesh.mesh = cube
	var m := StandardMaterial3D.new()
	m.albedo_color = tint
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 0.1
	m.metallic = 0.2
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.material_override = m
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh.position = pos
	add_child(mesh)
	return mesh

func _glow_box(pos: Vector3, size: Vector3, color: Color, energy: float = 2.0, parent: Node3D = null) -> MeshInstance3D:
	var host: Node3D = self if parent == null else parent
	return Style.box_node(host, pos, size, color, 0.0, energy)

func _light(pos: Vector3, color: Color, energy: float = 1.2, rng_m: float = 8.0, parent: Node3D = null) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.light_color = color
	l.light_energy = energy
	l.omni_range = rng_m
	l.position = pos
	(self if parent == null else parent).add_child(l)
	return l

func _cells_mesh(cells: Dictionary, y: float, mat: Material, name_hint: String) -> MeshInstance3D:
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var uvs := PackedVector2Array()
	var idx := PackedInt32Array()
	for c in cells.keys():
		var x: int = c.x
		var z: int = c.y
		var base := verts.size()
		for p in [Vector2(x, z), Vector2(x + 1, z), Vector2(x + 1, z + 1), Vector2(x, z + 1)]:
			verts.append(Vector3(p.x, y, p.y))
			norms.append(Vector3.UP)
			uvs.append(Vector2(p.x, p.y) * 0.11)
		idx.append_array([base, base + 1, base + 2, base, base + 2, base + 3])
	var mesh := ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = idx
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var mi := MeshInstance3D.new()
	mi.name = name_hint
	mi.mesh = mesh
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	return mi

func _stream_cells(points: Array, half: float, into: Dictionary) -> void:
	for i in range(points.size() - 1):
		var a: Vector2 = points[i]
		var b: Vector2 = points[i + 1]
		var steps := int(a.distance_to(b) * 2.0) + 1
		for s in range(steps + 1):
			var p := a.lerp(b, float(s) / steps)
			for dx in range(-3, 4):
				for dz in range(-3, 4):
					var cx := int(floor(p.x)) + dx
					var cz := int(floor(p.y)) + dz
					if Vector2(cx + .5, cz + .5).distance_to(p) <= half:
						into[Vector2i(cx, cz)] = true

func _marker(key: String, pos: Vector3, title: String) -> void:
	targets[key] = pos
	marker_labels[key] = _label(pos + Vector3(0, 2.8, 0), title)
	var object := Node3D.new()
	object.name = "Object_" + key
	object.position = pos
	add_child(object)
	target_objects[key] = object
	if key == "cat":
		target_objects[key] = cat
		object.queue_free()
		return
	if key == "villager":
		var v := Chars.build_humanoid(Chars.VILLAGER, "neutral")
		v.rotation.y = PI
		object.add_child(v)
		animated.append({"node": v, "kind": "npc"})
	elif key == "portal":
		var frame := Color("2b1f3e")
		var trim := Color("b07cff")
		for x in [-1.5, 1.5]:
			_box(Vector3(x, 1.5, 0), Vector3(.5, 3.0, .6), frame, false, object)
			_glow_box(Vector3(x * 1.0, 1.5, -.31), Vector3(.1, 2.6, .04), trim, 2.2, object)
		_box(Vector3(0, 3.1, 0), Vector3(3.5, .5, .6), frame, false, object)
		_glow_box(Vector3(0, 3.1, -.31), Vector3(3.0, .1, .04), trim, 2.2, object)
		_box(Vector3(0, .1, 0), Vector3(3.5, .2, .8), frame, false, object)
		var pane := MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = Vector2(2.6, 2.95)
		pane.mesh = q
		pane.material_override = Style.portal_mat()
		pane.position = Vector3(0, 1.55, 0)
		pane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		object.add_child(pane)
		_light(Vector3(0, 1.6, 1.5), Color("a67bff"), 1.8, 9.0, object)
		Style.motes(object, Vector3(0, 1.4, 0), Color("c9a8ff"), Vector3(1.2, .2, .3), 50, .8)
	elif key.begins_with("switch"):
		var glow := Color("62c8ff") if key == "switch0" else Color("f2f2f2") if key == "switch1" else Color("8fe071")
		_box(Vector3(0, .3, 0), Vector3(.9, .6, .9), Color("a89a86"), false, object)
		_box(Vector3(0, .62, 0), Vector3(.7, .05, .7), Color("8d806e"), false, object)
		var lever := Style.box_node(object, Vector3(0, 1.05, 0), Vector3(.14, .9, .14), Color("6c5442"), 0.02)
		lever.rotation.z = .35
		_glow_box(Vector3(-.15, 1.5, 0), Vector3(.3, .3, .3), glow, 2.4, object)
		Style.motes(object, Vector3(0, 1.4, 0), glow, Vector3(.35, .1, .35), 14, .5)
	elif key == "bridge":
		_box(Vector3(0, .75, 0), Vector3(.22, 1.5, .22), Color("5d4770"), false, object)
		_box(Vector3(0, 1.5, 0), Vector3(1.3, .65, .24), Color("d9c3e8"), false, object)
		_glow_box(Vector3(0, 1.5, -.13), Vector3(.9, .3, .03), Color("b07cff"), 2.0, object)
	elif key == "fish" or key.begins_with("memory"):
		var icon: String = "fish" if key == "fish" else ["diploma", "gyoza", "bandana", "cookie"][int(key.trim_prefix("memory"))]
		var sprite := Sprite3D.new()
		sprite.texture = load("res://assets/art/sprites/%s.png" % icon)
		sprite.pixel_size = .05
		sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		sprite.position.y = .75 if key == "fish" else 2.2
		sprite.shaded = false
		sprite.double_sided = true
		sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
		object.add_child(sprite)
		var ring := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = .5
		tm.outer_radius = .62
		tm.rings = 24
		tm.ring_segments = 6
		ring.mesh = tm
		ring.material_override = Style.toon(Color("ffe08a"), 0.0, 0.0, 2.2)
		ring.position.y = .05 if key == "fish" else .12
		ring.scale = Vector3(1, .25, 1)
		ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		object.add_child(ring)
		_light(Vector3(0, 1.4, 0), Color("ffd98a"), .8, 5.0, object)
		animated.append({"node": sprite, "kind": "bob", "base": sprite.position.y, "seed": randf() * 6.0})
	elif key == "guillermo":
		_box(Vector3(0, .12, 0), Vector3(1, .24, 1), Color("cbaedb"), false, object)

func _spawn_enemy(pos: Vector3, area: String) -> void:
	var e := Chars.build_shade()
	e.position = pos
	add_child(e)
	enemies.append({"node": e, "hp": 2, "timer": 2.0, "area": area, "seed": randf() * 6.0})

func _tree_solid(pos: Vector3) -> void:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(.9, 3.0, .9)
	shape.shape = box
	body.position = pos + Vector3(0, 1.5, 0)
	body.add_child(shape)
	add_child(body)

func _build_forest(rng: RandomNumberGenerator) -> void:
	# Trees are batched into 24 m chunks so the engine can frustum/distance cull them.
	var chunks: Dictionary = {}
	var add_tree := func(p: Vector3, sc: float) -> void:
		var key := Vector2i(int(floor(p.x / 24.0)), int(floor(p.z / 24.0)))
		if not chunks.has(key):
			chunks[key] = {"leaves": [], "wood": []}
		Style.cherry_tree_cubes(p, rng, sc, chunks[key].leaves, chunks[key].wood)
	var curated := [Vector2(-28, 3), Vector2(-29, 14), Vector2(-22, 18), Vector2(-10, 17), Vector2(-1.5, 20), Vector2(14, 17), Vector2(24, 18), Vector2(31, 12), Vector2(31, -4), Vector2(-31, -9), Vector2(-31, 23), Vector2(19, -22), Vector2(11, -25), Vector2(-3.5, -16)]
	for c in curated:
		var p := Vector3(c.x, Style.ground_height(terrain_data, c.x, c.y) + .1, c.y)
		add_tree.call(p, 1.0 + rng.randf() * .25)
		_tree_solid(p)
	for z in range(Style.GRID_Z0 + 2, Style.GRID_Z1 - 2, 3):
		for x in range(Style.GRID_X0 + 2, Style.GRID_X1 - 2, 3):
			var lv := Style.level_at_world(terrain_data, x, z)
			if lv < 1 or lv > 12:
				continue
			if absf(x) < Style.PLAY_X + 1.0 and z > Style.PLAY_Z0 - 1.0 and z < Style.PLAY_Z1 + 1.0:
				continue
			if x > 38 or (Vector2(x, z).distance_to(Vector2(-48, -27)) < 11.0):
				continue
			var chance := 0.15 if lv < 9 else 0.06
			if rng.randf() > chance:
				continue
			var p := Vector3(x + rng.randf_range(-1.0, 1.0), Style.top_y(lv) + .1, z + rng.randf_range(-1.0, 1.0))
			add_tree.call(p, 1.0 + rng.randf() * .45)
	for key in chunks.keys():
		var ch: Dictionary = chunks[key]
		var l := Style.cube_cloud(self, ch.leaves, Vector3(1.02, 1.02, 1.02), true, 0.2, "CherryLeaves")
		var w := Style.cube_cloud(self, ch.wood, Vector3(.82, 1.02, .82), true, 0.2, "CherryWood")
		l.visibility_range_end = 105.0
		w.visibility_range_end = 105.0

func _scatter_flora(rng: RandomNumberGenerator) -> void:
	var flowers: Array = []
	var grass: Array = []
	var fc := [Color("ff9ec4"), Color("fff3f6"), Color("ffe27a"), Color("c9a6ff"), Color("ff7fa2")]
	for i in range(900):
		var x := rng.randf_range(-33.5, 33.5)
		var z := rng.randf_range(-24.5, 26.5)
		if Style.in_path(int(floor(x)), int(floor(z))) != 0:
			continue
		if _inside_structures(x, z) or _in_water(x, z):
			continue
		if rng.randf() < 0.22:
			flowers.append([Vector3(x, Style.GROUND_Y + .14, z), fc[rng.randi() % fc.size()]])
		else:
			var h := rng.randf_range(.18, .42)
			grass.append([Vector3(x, Style.GROUND_Y + h / 2.0, z), Color("5fa845").lerp(Color("9ad45f"), rng.randf())])
	Style.cube_cloud(self, flowers, Vector3(.17, .28, .17), false, 0.0, "Flowers")
	Style.cube_cloud(self, grass, Vector3(.1, .32, .1), false, 0.0, "Tufts")

var water_lookup: Dictionary = {}

func _in_water(x: float, z: float) -> bool:
	return water_lookup.has(Vector2i(int(floor(x)), int(floor(z))))

func _inside_structures(x: float, z: float) -> bool:
	var rects := [Rect2(-18, -2, 12, 10), Rect2(-3, -15, 15, 10), Rect2(7, 0, 20, 9), Rect2(-25, -25, 20, 8), Rect2(12, -18, 18, 12), Rect2(-22, -20, 15, 16)]
	for r in rects:
		if r.has_point(Vector2(x, z)):
			return true
	return false

func _build_world() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1120
	# ---- sky, sun, fog, bloom
	var atm: Dictionary = Style.make_atmosphere()
	world_environment = atm.env
	sky_material = atm.sky
	var env := WorldEnvironment.new()
	env.environment = world_environment
	add_child(env)
	daylight = Style.make_sun()
	add_child(daylight)
	Style.apply_mood(world_environment, sky_material, daylight, 0.0)
	# ---- water layout (needs to exist before terrain so the bed can be tinted)
	var pond: Dictionary = {}
	var pn := FastNoiseLite.new()
	pn.seed = 5
	pn.frequency = 0.25
	for dz in range(-6, 7):
		for dx in range(-8, 9):
			var cx := -4 + dx
			var cz := 12 + dz
			var u := (dx + .5) / 5.8
			var v := (dz + .5) / 3.9
			if u * u + v * v < 1.0 + pn.get_noise_2d(cx, cz) * .45:
				pond[Vector2i(cx, cz)] = true
	var stream: Dictionary = {}
	_stream_cells([Vector2(-15, -14), Vector2(-15, -7), Vector2(-13, -3.4), Vector2(-8.5, -3), Vector2(-5.6, -1.2), Vector2(-4.8, 3), Vector2(-5.2, 8), Vector2(-4.4, 10.5)], 1.15, stream)
	var pool: Dictionary = {}
	for dz in range(-3, 3):
		for dx in range(-4, 4):
			pool[Vector2i(-15 + dx, -15 + dz)] = true
	water_lookup = {}
	for d in [pond, stream, pool]:
		for k in d.keys():
			water_lookup[k] = true
	# ---- terrain (flat play area + terraced cherry hills + pagoda plateau)
	terrain_data = Style.build_terrain(self, [Vector4(-49, -27, 7.5, 8)], water_lookup)
	var wm := Style.water_mat()
	_cells_mesh(water_lookup, Style.GROUND_Y + .16, wm, "Water")
	# ---- landmarks
	_house(Vector3(-12, 0, 3))
	_torii(Vector3(4, 0, -1))
	var pagoda_y := Style.top_y(8)
	_pagoda(Vector3(-49, pagoda_y, -27), 1.55)
	_build_forest(rng)
	_scatter_flora(rng)
	# pond dressing
	_marker("fish", Vector3(-4, 0, 12), "Estanque · pescado [E]")
	for p in [Vector3(-9.2, 0, 16), Vector3(-8.2, 0, 17.2), Vector3(-0.2, 0, 18)]:
		Style.bamboo_cluster(self, p, rng, 5)
	for p in [Vector3(-9.5, 0, 10.5), Vector3(1.2, 0, 11), Vector3(-6.8, 0, 16.3), Vector3(-1.6, 0, 8.6), Vector3(-1.5, 0, 15.8)]:
		Style.rock(self, p, rng, rng.randf_range(.6, 1.0))
	for p in [Vector2(-5.5, 11), Vector2(-2.5, 13.2), Vector2(-6.8, 13.6), Vector2(-1.4, 11.2)]:
		Style.box_node(self, Vector3(p.x, Style.GROUND_Y + .2, p.y), Vector3(.9, .05, .9), Color("5fb04b"))
		Style.box_node(self, Vector3(p.x + .1, Style.GROUND_Y + .25, p.y), Vector3(.22, .1, .22), Color("ff9ec4"), 0.0, 0.6)
	# wooden bridge where the west path crosses the stream
	_box(Vector3(-4.9, .06, 7), Vector3(3.2, .2, 3.4), Color("a9794e"))
	for z in range(-1, 2):
		_box(Vector3(-4.9, .17, 7 + z * 1.0), Vector3(3.2, .03, .08), Color("7a5636"))
	for x in [-6.4, -3.4]:
		_box(Vector3(x, .6, 7), Vector3(.12, .9, 3.4), Color("6b4a33"))
	# ---- the cat (an orange tabby, as in the hall screenshot)
	cat = Chars.build_cat()
	add_child(cat)
	cat.position = Vector3(-9, 0, 8)
	cat.rotation.y = -.6
	_marker("cat", cat.position, "Un amigo con bigotes [E]")
	_farms()
	_cave()
	_end_island()
	# ---- Anami (the player)
	player = CharacterBody3D.new()
	add_child(player)
	player.position = respawn
	var collider := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = .35
	capsule.height = 1.8
	collider.shape = capsule
	collider.position.y = .9
	player.add_child(collider)
	player_art = Chars.build_humanoid(Chars.ANAMI, "determined")
	player.add_child(player_art)
	var hand: Node3D = player_art.get_node("Body/ArmR/Hand")
	sword = Node3D.new()
	hand.add_child(sword)
	sword.rotation.x = -.42
	sword.position = Vector3(0, -.02, -.04)
	Style.box_node(sword, Vector3(0, .1, 0), Vector3(.1, .26, .1), Color("5a3d2a"), 0.015)
	Style.box_node(sword, Vector3(0, .26, 0), Vector3(.42, .08, .14), Color("ffd27a"), 0.02, 0.7, 0.3)
	Style.box_node(sword, Vector3(0, .66, 0), Vector3(.1, .72, .045), Color("dff2ff"), 0.02, 0.6, 0.4)
	Style.box_node(sword, Vector3(0, 1.08, 0), Vector3(.07, .16, .04), Color("dff2ff"), 0.0, 0.8, 0.0)
	Style.box_node(sword, Vector3(0, .27, -.075), Vector3(.1, .1, .03), Color("62c8ff"), 0.0, 2.6, 0.0)
	pivot = Node3D.new()
	player.add_child(pivot)
	pivot.position.y = 1.8
	var arm := SpringArm3D.new()
	arm.spring_length = 6.2
	arm.margin = .3
	arm.add_excluded_object(player.get_rid())
	pivot.add_child(arm)
	camera = Camera3D.new()
	camera.fov = 62
	camera.far = 320
	arm.add_child(camera)
	camera.current = true
	petals = Style.petal_storm(self)

func _torii(pos: Vector3) -> void:
	var charcoal := Color("2b2630")
	var pink := Color("d98aa6")
	for x in [-3.9, 3.9]:
		_box(pos + Vector3(x, 2.6, 0), Vector3(.7, 5.2, .7), charcoal, true)
		_box(pos + Vector3(x, .3, 0), Vector3(1.0, .6, 1.0), Color("c9bfae"))
	_box(pos + Vector3(0, 4.4, 0), Vector3(8.4, .38, .5), pink)
	_box(pos + Vector3(0, 5.35, 0), Vector3(10.2, .45, .85), charcoal)
	_box(pos + Vector3(0, 5.75, 0), Vector3(11.0, .3, .7), charcoal)
	for s in [-1.0, 1.0]:
		var tip := _box(pos + Vector3(5.55 * s, 6.0, 0), Vector3(1.1, .3, .7), charcoal)
		tip.rotation.z = .35 * s
	_box(pos + Vector3(0, 4.95, 0), Vector3(1.6, 1.3, .22), Color("e8c7d2"))
	_glow_box(pos + Vector3(0, 4.95, -.13), Vector3(.5, .9, .03), Color("ffb7cc"), 1.4)
	for x in [-2.4, 2.4]:
		Style.lantern(self, pos + Vector3(x, 3.6, -.6), true)

func _house(pos: Vector3) -> void:
	var cream := Color("e6dcc8")
	var charcoal := Color("2e2a33")
	var roof := Color("373640")
	var pinkband := Color("c97b95")
	_box(pos + Vector3(0, -.3, 0), Vector3(10, .4, 8), Color("8a6a56"), true)
	_box(pos + Vector3(0, 3, -4), Vector3(10, 6, .4), cream, true)
	_box(pos + Vector3(-5, 3, 0), Vector3(.4, 6, 8), cream, true)
	_box(pos + Vector3(5, 3, 0), Vector3(.4, 6, 8), cream, true)
	for x in [-3.4, 3.4]:
		_box(pos + Vector3(x, 3, 4), Vector3(3, 6, .4), cream, true)
		_box(pos + Vector3(x, 3.8, 4.25), Vector3(1.4, 1.6, .2), Color("d58aa2"))
		_glow_box(pos + Vector3(x, 3.8, 4.38), Vector3(.8, 1.2, .1), Color("ffd9a0"), 1.5)
		_box(pos + Vector3(x, 2.4, 4.45), Vector3(1.8, .25, .5), Color("6b4a33"))
		for f in range(4):
			Style.box_node(self, pos + Vector3(x - .65 + f * .43, 2.75, 4.5), Vector3(.2, .3, .2), [Color("ff9ec4"), Color("fff3f6"), Color("ffe27a"), Color("ff7fa2")][f], 0.0, 0.5)
	for x in [-5, 5]:
		for z in [-4, 4]:
			_box(pos + Vector3(x, 3, z), Vector3(.6, 6.5, .6), charcoal)
	for tier in range(10):
		_box(pos + Vector3(0, 6.3 + tier * .5, 0), Vector3(11 - tier * 1.05, .5, 9), roof)
		_box(pos + Vector3(0, 6.3 + tier * .5, 4.6), Vector3(11 - tier * 1.05, .5, .25), pinkband if tier % 3 == 0 else roof)
		_box(pos + Vector3(0, 6.3 + tier * .5, -4.6), Vector3(11 - tier * 1.05, .5, .25), pinkband if tier % 3 == 0 else roof)
	_box(pos + Vector3(0, 7.3, 4.7), Vector3(2.8, 2.3, .4), cream)
	_box(pos + Vector3(0, 7.3, 4.95), Vector3(1.4, 1.6, .2), Color("d7a0b4"))
	_glow_box(pos + Vector3(0, 7.3, 5.08), Vector3(.85, 1.1, .1), Color("ffd9a0"), 1.6)
	_box(pos + Vector3(0, 8.5, 4.7), Vector3(3.2, .3, 1.5), roof)
	# timber framing on the long walls
	for wx in [-5.22, 5.22]:
		for zz in [-3.0, -1.0, 1.0, 3.0]:
			_box(pos + Vector3(wx, 3, zz), Vector3(.12, 6, .3), charcoal)
		for yy in [1.0, 3.2, 5.4]:
			_box(pos + Vector3(wx, yy, 0), Vector3(.12, .28, 8), charcoal)
		_box(pos + Vector3(wx * 1.0, 3.6, 0), Vector3(.14, 1.3, 1.6), Color("d58aa2"))
		_glow_box(pos + Vector3(wx * 1.0 + (.08 if wx > 0 else -.08), 3.6, 0), Vector3(.08, 1.0, 1.2), Color("ffd9a0"), 1.4)
	# stone porch + steps + door
	_box(pos + Vector3(0, .05, 5.4), Vector3(4.6, .3, 2.2), Color("d4cbbb"))
	_box(pos + Vector3(0, -.05, 6.3), Vector3(3.6, .2, 1.0), Color("c4baa9"))
	_box(pos + Vector3(0, 1.5, 4.25), Vector3(1.8, 3.0, .3), Color("5a4036"))
	_box(pos + Vector3(0, 1.5, 4.42), Vector3(1.3, 2.6, .1), Color("8a5a40"))
	_glow_box(pos + Vector3(.45, 1.5, 4.5), Vector3(.1, .1, .1), Color("ffd27a"), 2.0)
	Style.lantern(self, pos + Vector3(-1.5, 3.0, 5.2), true)
	Style.lantern(self, pos + Vector3(1.5, 3.0, 5.2), true)
	# interior
	_box(pos + Vector3(-2, .65, -2), Vector3(2.8, 1, 1.8), Color("6e98b4"), true)
	_box(pos + Vector3(-2, 1, -3), Vector3(3, 1.5, .4), Color("dfa3b5"))
	_box(pos + Vector3(2.7, .8, -2), Vector3(1.8, 1.4, 1), Color("b08558"), true)
	_box(pos + Vector3(0, 4, -2), Vector3(8, .3, 3), Color("a98258"))
	_box(pos + Vector3(0, 4.6, -.5), Vector3(8, .2, .2), Color("594436"))
	for x in [-3, 0, 3]:
		_box(pos + Vector3(x, 4.3, -.5), Vector3(.15, .7, .15), Color("594436"))
	_glow_box(pos + Vector3(0, 3.5, 0), Vector3(.45, .5, .45), Color("ffdb84"), 2.2)
	_label(pos + Vector3(0, 12.5, 0), "Nuestro refugio")

func _pagoda(pos: Vector3, scale: float) -> void:
	var host := Node3D.new()
	host.position = pos
	host.scale = Vector3.ONE * scale
	add_child(host)
	var stone := Color("a7a9b6")
	var wall := Color("efe3cf")
	var wood := Color("5a4348")
	var roof := Color("3a3a48")
	var trim := Color("e08aa8")
	_box(Vector3(0, .5, 0), Vector3(10, 1, 10), stone, false, host)
	_box(Vector3(0, 1.3, 0), Vector3(8.6, .6, 8.6), Color("c4c2cc"), false, host)
	for tier in range(4):
		var y := 1.6 + tier * 2.5
		var w := 6.6 - tier * 1.15
		_box(Vector3(0, y + 1.0, 0), Vector3(w, 1.9, w), wall, false, host)
		for x in [-1, 1]:
			for z in [-1, 1]:
				_box(Vector3(x * w / 2.0, y + 1.0, z * w / 2.0), Vector3(.4, 2.0, .4), wood, false, host)
		_glow_box(Vector3(0, y + 1.1, -w / 2.0 - .02), Vector3(w * .35, 1.0, .06), Color("ffd9a0"), 1.2, host)
		_box(Vector3(0, y + 2.1, 0), Vector3(w + 2.2, .3, w + 2.2), trim, false, host)
		_box(Vector3(0, y + 2.4, 0), Vector3(w + 1.5, .4, w + 1.5), roof, false, host)
		_box(Vector3(0, y + 2.75, 0), Vector3(w + .5, .35, w + .5), roof, false, host)
		for sx in [-1, 1]:
			for sz in [-1, 1]:
				var c := _box(Vector3(sx * (w + 2.0) / 2.0, y + 2.6, sz * (w + 2.0) / 2.0), Vector3(1.1, .3, 1.1), roof, false, host)
				c.rotation = Vector3(.0, 0, 0)
				_box(Vector3(sx * (w + 2.6) / 2.0, y + 2.9, sz * (w + 2.6) / 2.0), Vector3(.7, .3, .7), roof, false, host)
	_box(Vector3(0, 12.6, 0), Vector3(.35, 2.4, .35), roof, false, host)
	_glow_box(Vector3(0, 14.0, 0), Vector3(.5, .5, .5), Color("ffd27a"), 2.4, host)
	_label(pos + Vector3(0, 21, 0), "El templo en la colina")

func _farms() -> void:
	for i in range(3):
		var p := Vector3(10 + i * 7, 0, 4)
		_box(p + Vector3(0, .1, 0), Vector3(5, .3, 7), Color("6b573b"), true)
		_box(p + Vector3(0, .26, 0), Vector3(4.6, .06, 6.6), Color("4f3e2a"))
		for row in range(4):
			for col in range(3):
				var h: float = 1.8 if i == 0 else .55
				var c: Color = Color("86c761") if i == 0 else Color("e6bb55")
				_box(p + Vector3(-1.5 + col * 1.2, .3 + h / 2, -2.5 + row * 1.4), Vector3(.35, h, .35), c)
				if i != 0:
					_box(p + Vector3(-1.5 + col * 1.2, .3 + h + .08, -2.5 + row * 1.4), Vector3(.3, .22, .3), Color("f3d36e"))
		_marker("switch" + str(i), p + Vector3(0, 0, 5), ["Caña · agua [E]", "Hierro · palanca [E]", "Cultivos · semillas [E]"][i])
	# tall glass-fronted sugar-cane tower, like the reference screenshots
	for row in range(5):
		_box(Vector3(10, 1 + row * 1.1, .5), Vector3(5.6, .18, .2), Color("eef4f4"))
		_box(Vector3(10, .6 + row * 1.1, .6), Vector3(4.8, .75, .18), Color("73ad5f"))
	for x in [7.2, 12.8]:
		_box(Vector3(x, 3, .5), Vector3(.2, 6, .2), Color("eef4f4"))
	_glass(Vector3(10, 3.0, .15), Vector3(5.4, 6, .08))
	# iron farm tower
	_box(Vector3(17, 5, -4), Vector3(6, 1, 6), Color("9aa1aa"))
	_box(Vector3(17, 2.5, -4), Vector3(.6, 5, .6), Color("757983"), true)
	for k in range(3):
		_box(Vector3(17, 1.2 + k * 1.3, -4), Vector3(2.4 - k * .5, .2, 2.4 - k * .5), Color("c9ced6"))
	_glow_box(Vector3(17, 5.7, -4), Vector3(.8, .5, .8), Color("ffe08a"), 1.6)
	_label(Vector3(17, 7.6, -4), "Granja de hierro")
	# mob tower
	_box(Vector3(27, 9, -13), Vector3(8, 1, 8), Color("575d6b"))
	_box(Vector3(27, 4, -13), Vector3(2, 8, 2), Color("747987"), true)
	for k in range(4):
		_box(Vector3(27, 1.5 + k * 1.8, -13), Vector3(3.2, .25, 3.2), Color("8a8f9e"))
	_label(Vector3(27, 11.6, -13), "Granja de mobs")
	# the villager trading hall: white quartz + charcoal floor, pink signs, orange cat vibe
	_box(Vector3(4, -.35, -10), Vector3(12, .5, 7), Color("3a3842"), true)
	for tx in range(-1, 11, 2):
		for tz in range(-13, -6, 2):
			if (tx + tz) % 4 == 0:
				_box(Vector3(tx + .5, -.09, tz + .5), Vector3(1.9, .02, 1.9), Color("46434f"))
	_box(Vector3(-2.2, 2, -10), Vector3(.5, 4, 7), Color("efece2"), true)
	_box(Vector3(10.2, 2, -10), Vector3(.5, 4, 7), Color("efece2"), true)
	for x in [-1, 2, 5, 8]:
		_box(Vector3(x, 2, -13), Vector3(2.5, 4, .5), Color("efece2"), true)
		_box(Vector3(x, .8, -12.6), Vector3(1.4, 1, .5), Color("b57648"), true)
		_glow_box(Vector3(x, 3.2, -12.7), Vector3(1.0, .5, .08), Color("ffb7cc"), .9)
		var v := Chars.build_humanoid(Chars.VILLAGER, "neutral")
		v.position = Vector3(x, .6, -11)
		v.rotation.y = PI
		add_child(v)
		animated.append({"node": v, "kind": "npc"})
	_box(Vector3(4, 4.5, -10), Vector3(13, .5, 8), Color("efece2"))
	for x in [-1, 4, 9]:
		Style.lantern(self, Vector3(x, 3.9, -8.2), true)
	_marker("villager", Vector3(4, 0, -6), "Salón de aldeanos [E]")

func _cave() -> void:
	var rock := [Color("5d6472"), Color("51586a"), Color("6a7080"), Color("464d5e")]
	for x in range(-24, -5, 3):
		var hgt := 6.0 + (x % 3)
		_box(Vector3(x, hgt / 2.0, -22), Vector3(3, hgt, 5), rock[(x + 30) % 4], true)
		_box(Vector3(x, hgt + .15, -22), Vector3(3.0, .3, 5.0), Color("7fb25b"))
	# waterfall curtain + splash pool
	var wf := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(2.8, 7.0, .4)
	wf.mesh = bm
	wf.material_override = Style.water_mat(Color("bfeeff"), Color("5fb7ee"), Vector2(0, -1), 0.9, 1.0)
	wf.position = Vector3(-15, 3.5, -19.3)
	wf.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(wf)
	Style.motes(self, Vector3(-15, .6, -17.6), Color("e6fbff"), Vector3(1.6, .2, .6), 40, 1.2)
	var cr := RandomNumberGenerator.new()
	cr.seed = 808
	for x in [-22, -9]:
		_box(Vector3(x, 2.5, -12), Vector3(2, 5, 14), Color("535a6a"), true)
		var dirn := 1.0 if x < 0 and x == -22 else -1.0
		for zz in range(-19, -5, 2):
			for yy in range(0, 5, 2):
				var off := cr.randf_range(.05, .75)
				var c: Color = rock[cr.randi() % 4]
				if cr.randf() < .22:
					c = Color("4f7d49")
				_box(Vector3(x + dirn * (1.0 + off / 2.0), yy + 1.0, zz + 1.0), Vector3(off, 2.0, 2.0), c)
	_box(Vector3(-15.5, 5, -12), Vector3(15, .7, 14), Color("4c5362"))
	_box(Vector3(-15.5, 5.45, -12), Vector3(15, .3, 14), Color("78ad57"))
	for i in range(16):
		var sx := cr.randf_range(-20.6, -10.4)
		var sz := cr.randf_range(-18.5, -5.5)
		var sh := cr.randf_range(.5, 1.5)
		_box(Vector3(sx, 4.65 - sh / 2.0, sz), Vector3(.45, sh, .45), rock[cr.randi() % 4])
	for x in [-20.6, -10.4]:
		for z in [-16, -9]:
			var t := Style.lantern(self, Vector3(x, 3.3, z), true)
	for i in range(7):
		var cx := -20.5 + (i % 4) * 3.4
		var cz := -16.0 + (i / 4) * 5.0
		_glow_box(Vector3(cx, .4, cz), Vector3(.3, .8, .3), Color("62c8ff"), 2.2)
	_marker("portal", Vector3(-15, 0, -18), "Portal entre la cascada [E]")
	for i in range(3):
		_spawn_enemy(Vector3(-19 + i * 3, 0, -10 - i * 2), "cave")

func _end_island() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 33
	var obsidian := Color("2c2342")
	_box(Vector3(75, -1.2, 0), Vector3(40, 2.4, 40), Color("2b2241"))
	_box(Vector3(75, -3.4, 0), Vector3(30, 2.2, 30), Color("231b36"))
	_box(Vector3(75, -5.4, 0), Vector3(18, 2.0, 18), Color("1c152c"))
	_box(Vector3(75, -.2, 0), Vector3(32, 1, 32), Color("958a6c"), true)
	_box(Vector3(75, .32, 0), Vector3(32, .06, 32), Color("a09474"))
	_box(Vector3(50, -.2, 0), Vector3(8, 1, 9), Color("958a6c"), true)
	_box(Vector3(50, -1.4, 0), Vector3(7, 1.4, 8), Color("2b2241"))
	_marker("bridge", Vector3(50, 0, 0), "Esta vez, puente con barandas [E]")
	for x in [64, 86]:
		for z in [-11, 11]:
			_box(Vector3(x, 4, z), Vector3(2, 8, 2), obsidian, true)
			_box(Vector3(x, 8.4, z), Vector3(2.4, .5, 2.4), Color("3d3158"))
			var crystal := Style.box_node(self, Vector3(x, 10.2, z), Vector3(.9, .9, .9), Color("c78bff"), 0.0, 3.0, 0.0)
			crystal.rotation = Vector3(.6, .6, 0)
			animated.append({"node": crystal, "kind": "spin", "base": 10.2, "seed": rng.randf() * 6.0})
			_light(Vector3(x, 9.0, z), Color("b07cff"), 1.1, 11.0)
	# scattered void islands and amethyst spires
	for i in range(28):
		var a := rng.randf() * TAU
		var r := rng.randf_range(32, 70)
		var c := Vector3(75 + cos(a) * r, rng.randf_range(-14, 6), sin(a) * r)
		if c.x < 56:
			continue
		var s := rng.randf_range(2.0, 6.0)
		_box(c, Vector3(s, s * .5, s), Color("3c3156").lerp(Color("ded4a4"), rng.randf() * .35))
		_box(c + Vector3(0, -s * .45, 0), Vector3(s * .55, s * .5, s * .55), Color("2a2140"))
		if rng.randf() < .5:
			_glow_box(c + Vector3(0, s * .45, 0), Vector3(.4, s * .6, .4), Color("b07cff"), 2.2)
	for i in range(10):
		var a := rng.randf() * TAU
		var r := rng.randf_range(8, 13)
		var p := Vector3(75 + cos(a) * r, .3, sin(a) * r)
		var h := rng.randf_range(1.2, 2.8)
		_glow_box(p + Vector3(0, h / 2, 0), Vector3(.5, h, .5), Color("a57cff"), 1.15)
	Style.motes(self, Vector3(75, 1.0, 0), Color("c9a8ff"), Vector3(16, 1, 16), 90, .9)
	# the Forgotten One
	boss = Chars.build_boss()
	boss.position = Vector3(76, 0, -6)
	boss.rotation.y = PI * .5
	boss.scale = Vector3.ONE * 1.7
	add_child(boss)
	danger_ring = MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 3.8
	torus.outer_radius = 4.0
	torus.rings = 24
	torus.ring_segments = 8
	danger_ring.mesh = torus
	danger_ring.material_override = Style.toon(Color("ff9a7a"), 0.0, 0.0, 2.6)
	danger_ring.position = boss.position + Vector3(0, .1, 0)
	danger_ring.visible = false
	add_child(danger_ring)
	_label(Vector3(76, 6.6, -6), "EL OLVIDADO")
	# the amethyst cage and Guillermo (worried, no mustache)
	cage = Node3D.new()
	add_child(cage)
	cage.position = Vector3(75, 0, -10)
	for x in [-1, 1]:
		for z in [-1, 1]:
			_glow_box(Vector3(x * 1.3, 1.7, z * 1.3), Vector3(.2, 3.4, .2), Color("b07cff"), 1.8, cage)
	for k in range(3):
		_glow_box(Vector3(0, .5 + k * 1.2, -1.3), Vector3(2.6, .08, .08), Color("c9a8ff"), 1.4, cage)
		_glow_box(Vector3(0, .5 + k * 1.2, 1.3), Vector3(2.6, .08, .08), Color("c9a8ff"), 1.4, cage)
	_box(Vector3(0, 3.5, 0), Vector3(3.0, .25, 3.0), Color("3d3158"), false, cage)
	_light(Vector3(0, 2, 0), Color("b07cff"), 1.2, 7.0, cage)
	var g := Chars.build_humanoid(Chars.GUILLERMO, "worried")
	g.position = Vector3(75, 0, -10)
	g.rotation.y = PI * .5
	g.name = "Guillermo"
	add_child(g)
	guillermo_node = g
	animated.append({"node": g, "kind": "npc"})
	_marker("guillermo", Vector3(75, 0, -9), "Guillermo [E]")
	for i in range(4):
		var p := Vector3(69 if i % 2 == 0 else 81, 0, -3 if i < 2 else 6)
		_box(p + Vector3(0, .7, 0), Vector3(1.5, 1.4, 1.5), Color("8d7aa3"), true)
		_box(p + Vector3(0, 1.45, 0), Vector3(1.7, .12, 1.7), Color("c4b0d8"))
		_box(p + Vector3(0, 1.6, 0), Vector3(.7, .35, .7), Color("e8c680"))
		_marker("memory" + str(i), p, ["Diploma", "Gyoza", "Bandana", "Galleta"][i] + " [E]")

var guillermo_node: Node3D

func _unhandled_input(event: InputEvent) -> void:
	if active and event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		yaw -= event.relative.x * .003
		pitch = clampf(pitch - event.relative.y * .002, -.75, .15)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		return
	time += delta
	attack_timer = maxf(0, attack_timer - delta)
	hurt_timer = maxf(0, hurt_timer - delta)
	pivot.rotation = Vector3(pitch, yaw, 0)
	_animate_world(delta)
	var guide := current_target()
	for key in marker_labels:
		marker_labels[key].visible = targets[key].distance_to(guide) < .1 or targets[key].distance_to(player.position) < 7
	if not active:
		player.velocity = Vector3.ZERO
		return
	var move := Vector2.ZERO
	move.x = float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A))
	move.y = float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))
	move = move.normalized()
	var direction := Vector3(move.x, 0, move.y).rotated(Vector3.UP, yaw)
	var moving := direction.length_squared() > .01
	if moving:
		player_art.rotation.y = lerp_angle(player_art.rotation.y, atan2(-direction.x, -direction.z), .25)
	Chars.animate_humanoid(player_art, time, 1.0 if moving else 0.0, (attack_timer / .45) if attack_timer > 0.0 else 0.0)
	player.velocity.x = direction.x * 5.3
	player.velocity.z = direction.z * 5.3
	player.velocity.y -= 18 * delta
	if player.is_on_floor():
		player.velocity.y = -.5
	player.move_and_slide()
	if player.position.y < -6:
		player.position = respawn
		health = maxf(health, 65)
	if quest_index == 2:
		var cat_goal := Vector3(4, 0, -6)
		var cat_dir := cat_goal - cat.position
		if cat_dir.length() > .05:
			cat.rotation.y = lerp_angle(cat.rotation.y, atan2(-cat_dir.x, -cat_dir.z), .15)
		cat.position = cat.position.move_toward(cat_goal, delta * 2.5)
	for e in enemies:
		if e.hp <= 0:
			continue
		var live: bool = (e.area == "cave" and quest_index == 5) or (e.area == "boss" and quest_index == 8)
		if not live:
			continue
		var n: Node3D = e.node
		var distance: float = n.position.distance_to(player.position)
		e.timer -= delta
		if distance < 13 and distance > 1.4:
			var toward := player.position - n.position
			toward.y = 0
			n.position += toward.normalized() * delta * 1.5
			n.look_at(Vector3(player.position.x, n.position.y, player.position.z), Vector3.UP)
		if e.timer < .7:
			n.scale = Vector3.ONE * (1.0 + sin(time * 12) * .12)
		if e.timer <= 0:
			e.timer = 3.0
			if distance < 2.0:
				_damage(8)
	if quest_index == 5 and _alive("cave") == 0:
		_step(6)
	if quest_index == 8:
		pulse_timer -= delta
		danger_ring.visible = pulse_timer < 1.5
		boss.scale = Vector3.ONE * (1.7 + (.12 * sin(time * 10) if pulse_timer < 1.5 else 0.0))
		if pulse_timer <= 0:
			pulse_timer = 8
			if player.position.distance_to(boss.position) < 4:
				_damage(10)
		if _alive("boss") == 0:
			danger_ring.visible = false
			_step(9)
			_say("El Olvidado", "¿Por qué estos recuerdos no se borran?", "worried")
	health = minf(max_health, health + delta * 1.8)

func _alive(area: String) -> int:
	var count := 0
	for e in enemies:
		if e.area == area and e.hp > 0:
			count += 1
	return count

func _damage(amount: float) -> void:
	if hurt_timer > 0:
		return
	health -= amount
	hurt_timer = 1.2
	if health <= 0:
		health = max_health
		player.position = respawn
		_say("Anami", "Otra oportunidad. No voy a dejarte aquí, amor.", "worried")

func attack() -> void:
	if not active or attack_timer > 0:
		return
	attack_timer = .45
	for e in enemies:
		if e.hp > 0 and e.node.position.distance_to(player.position) < 3.0 and ((e.area == "cave" and quest_index == 5) or (e.area == "boss" and quest_index == 8)):
			e.hp -= 1
			if e.hp <= 0:
				e.node.visible = false
	if quest_index == 10 and player.position.distance_to(boss.position) < 3.5:
		boss_health -= 1
		boss.scale *= .85
		if boss_health <= 0:
			boss.visible = false
			cage.visible = false
			_step(11)
			_free_guillermo()
			_say("Guillermo", "¡Amor! Sabía que vendrías. Aunque el gato hizo bastante trabajo.", "happy")

func _near(key: String) -> bool:
	return targets.has(key) and player.position.distance_to(targets[key]) < 3.5

func current_target() -> Vector3:
	match quest_index:
		0: return targets["fish"]
		1: return cat.position
		2, 4: return targets["villager"]
		3:
			for i in range(3):
				if not switches[i]:
					return targets["switch" + str(i)]
		5, 8:
			var closest: Vector3 = targets["portal"] if quest_index == 5 else boss.position
			var distance: float = INF
			for e in enemies:
				if e.hp > 0 and e.area == ("cave" if quest_index == 5 else "boss"):
					var d: float = e.node.position.distance_squared_to(player.position)
					if d < distance:
						distance = d
						closest = e.node.position
			return closest
		6: return targets["portal"]
		7: return targets["bridge"]
		9:
			for i in range(4):
				if not memories[i]:
					return targets["memory" + str(i)]
		10: return boss.position
		11: return targets["guillermo"]
	return player.position

func get_prompt() -> String:
	if player.position.distance_to(current_target()) < 3.5:
		return "Clic izquierdo · espada" if quest_index in [5, 8, 10] else "E · interactuar"
	return "WASD · caminar | Ratón · mirar"

func interact() -> void:
	if not active:
		return
	match quest_index:
		0:
			if _near("fish"):
				_step(1)
				_say("Anami", "Un pescado. Moneda oficial de los gatos.", "playful")
		1:
			if _near("cat"):
				_step(2)
				_say("Anami", "Hola, detective. Encuentra a Guillermo y te ganas otro.", "happy")
		2:
			if _near("villager"):
				_step(3)
				_say("Aldeano", "La corrupción apagó tres granjas. Agua para la caña, palanca de hierro y semillas para los cultivos. Nada de intercambiar veinte esmeraldas.", "neutral")
		3:
			for i in range(3):
				if _near("switch" + str(i)) and not switches[i]:
					if i > 0 and not switches[i - 1]:
						_say("Anami", "Primero el agua para la caña, después la palanca de hierro y al final las semillas. El aldeano dejó la pista en ese orden.", "neutral")
						return
					switches[i] = true
					_box(targets["switch" + str(i)] + Vector3(0, 1, 0), Vector3(.3, 1.2, .3), Color("92e3ac"))
			if switches.all(func(v): return v):
				_step(4)
		4:
			if _near("villager"):
				_step(5)
				respawn = Vector3(-15, 1, -5)
				_say("Aldeano", "El gato encontró huellas en la cascada. Usa tu espada: las sombras avisan antes de atacar. Respira, retrocede y vuelve a intentarlo.", "neutral")
		6:
			if _near("portal"):
				player.position = Vector3(50, 1, 2)
				respawn = player.position
				_step(7)
				_say("Anami", "El End... La última vez vencimos al dragón y yo perdí contra el piso. Esta vez quiero barandas.", "embarrassed")
		7:
			if _near("bridge"):
				_box(Vector3(59, -.1, 0), Vector3(12, .8, 4), Color("aa8fbc"), true)
				for z in [-2.2, 2.2]:
					_box(Vector3(59, .8, z), Vector3(12, 1.4, .4), Color("6f577e"), true)
				_step(8)
				for i in range(3):
					_spawn_enemy(Vector3(70 + i * 3, 0, 2), "boss")
				_say("El Olvidado", "Los recuerdos se desvanecen. Entrégame los tuyos y déjalo ir.", "worried")
		9:
			for i in range(4):
				if _near("memory" + str(i)) and not memories[i]:
					memories[i] = true
					_box(targets["memory" + str(i)] + Vector3(0, 2, 0), Vector3(.6, .6, .6), Color("ffd995"))
					_say("Anami", ["Ese diploma: no sabíamos lo que empezaba.", "Una gyoza y todos los temas que guardamos para nuestra cita.", "La bandana. El comienzo de nosotros.", "La galleta. Hasta nuestros desastres tienen receta." ][i], "affectionate")
			if memories.all(func(v): return v):
				_step(10)
		11:
			if _near("guillermo"):
				finished.emit()
				active = false

func _step(index: int) -> void:
	quest_index = index
	_update_atmosphere(true)
	_emit_goal()

func _update_atmosphere(instant: bool = false) -> void:
	if not world_environment:
		return
	mood_target = 1.0 if quest_index >= 7 else 0.0
	if instant:
		mood_t = mood_target
		Style.apply_mood(world_environment, sky_material, daylight, mood_t)

func _animate_world(delta: float) -> void:
	if not is_equal_approx(mood_t, mood_target):
		mood_t = move_toward(mood_t, mood_target, delta * 0.6)
		Style.apply_mood(world_environment, sky_material, daylight, mood_t)
	for a in animated:
		var n: Node3D = a.node
		if not is_instance_valid(n):
			continue
		match a.kind:
			"npc":
				var look: Variant = null
				if n.global_position.distance_to(player.global_position) < 10.0:
					look = player.global_position + Vector3(0, 1.4, 0)
				Chars.animate_humanoid(n, time + float(n.get_instance_id() % 7), 0.0, 0.0, look)
			"bob":
				n.position.y = a.base + sin(time * 2.0 + a.seed) * .12
			"spin":
				n.rotation.y += delta * 1.6
				n.position.y = a.base + sin(time * 1.8 + a.seed) * .22
	Chars.animate_cat(cat, time, quest_index == 2 and cat.position.distance_to(Vector3(4, 0, -6)) > .2)
	if is_instance_valid(boss) and boss.visible:
		Chars.animate_boss(boss, time, quest_index == 8)
	for e in enemies:
		if e.hp > 0:
			Chars.animate_shade(e.node, time, e.seed)
	if is_instance_valid(petals):
		petals.global_position = player.global_position + Vector3(0, 9, 0)

func _emit_goal() -> void:
	objective_changed.emit(goals[mini(quest_index, goals.size() - 1)])

func _say(speaker: String, text: String, mood: String) -> void:
	message_requested.emit([{"speaker": speaker, "text": text, "mood": mood}])

func get_save_data() -> Dictionary:
	return {"quest": quest_index, "health": health, "switches": switches.duplicate(), "memories": memories.duplicate(), "position": [player.position.x, player.position.y, player.position.z], "boss_health": boss_health, "enemy_hp": enemies.map(func(e): return e.hp)}

func restore_save(data: Dictionary) -> void:
	quest_index = clampi(int(data.get("quest", 0)), 0, 11)
	health = clampf(float(data.get("health", 100)), 1, 100)
	switches = data.get("switches", [false, false, false])
	memories = data.get("memories", [false, false, false, false])
	boss_health = int(data.get("boss_health", 4))
	var p: Array = data.get("position", [0, 1, 8])
	player.position = Vector3(p[0], p[1], p[2])
	for i in range(3):
		if switches[i]:
			_box(targets["switch" + str(i)] + Vector3(0, 1, 0), Vector3(.3, 1.2, .3), Color("92e3ac"))
	for i in range(4):
		if memories[i]:
			_box(targets["memory" + str(i)] + Vector3(0, 2, 0), Vector3(.6, .6, .6), Color("ffd995"))
	if quest_index >= 3:
		cat.position = targets["villager"]
	if quest_index >= 8:
		_box(Vector3(59, -.1, 0), Vector3(12, .8, 4), Color("aa8fbc"), true)
		for z in [-2.2, 2.2]:
			_box(Vector3(59, .8, z), Vector3(12, 1.4, .4), Color("6f577e"), true)
		for i in range(3):
			_spawn_enemy(Vector3(70 + i * 3, 0, 2), "boss")
	var hp: Array = data.get("enemy_hp", [])
	for i in range(enemies.size()):
		if i < hp.size():
			enemies[i].hp = hp[i]
		elif quest_index > 5 and enemies[i].area == "cave":
			enemies[i].hp = 0
		elif quest_index > 8 and enemies[i].area == "boss":
			enemies[i].hp = 0
		enemies[i].node.visible = enemies[i].hp > 0
	if quest_index >= 11:
		boss.visible = false
		cage.visible = false
		_free_guillermo()
	respawn = Vector3(50, 1, 2) if quest_index >= 7 else Vector3(-15, 1, -5) if quest_index >= 5 else Vector3(0, 1, 8)
	_update_atmosphere(true)
	_emit_goal()

func _free_guillermo() -> void:
	if is_instance_valid(guillermo_node):
		var face: MeshInstance3D = guillermo_node.get_node_or_null("Body/Head/Face")
		if face:
			face.material_override = Chars.face_material(Chars.GUILLERMO, "happy")
