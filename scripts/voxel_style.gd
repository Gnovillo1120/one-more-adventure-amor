extends RefCounted
## Visual layer for the 3D chapter: toon materials, sky + lighting moods, voxel
## terrain, cherry trees, water and small props. Gameplay never lives here.

const TOON = preload("res://assets/shaders/toon.gdshader")
const OUTLINE = preload("res://assets/shaders/outline.gdshader")
const WATER = preload("res://assets/shaders/water.gdshader")
const PORTAL = preload("res://assets/shaders/portal.gdshader")
const SKY = preload("res://assets/shaders/sky.gdshader")

# Overworld play rectangle: terrain is perfectly flat inside, hills rise outside.
const PLAY_X := 34.0
const PLAY_Z0 := -25.0
const PLAY_Z1 := 27.0
const GRID_X0 := -74
const GRID_X1 := 45
const GRID_Z0 := -70
const GRID_Z1 := 70
const GROUND_Y := -0.1

static var _mats: Dictionary = {}
static var _block_tex: ImageTexture

# ------------------------------------------------------------------ materials

static func block_texture() -> ImageTexture:
	if _block_tex:
		return _block_tex
	var img := Image.create(16, 16, false, Image.FORMAT_RGB8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1120
	for y in range(16):
		for x in range(16):
			var g: float = rng.randf_range(0.84, 1.0)
			if (x + y * 3) % 7 == 0:
				g -= 0.07
			img.set_pixel(x, y, Color(g, g, g))
	_block_tex = ImageTexture.create_from_image(img)
	return _block_tex

static func outline_mat(width: float = 0.03, color: Color = Color(0.16, 0.09, 0.14)) -> ShaderMaterial:
	var key := "ol|%s|%s" % [width, color.to_html()]
	if _mats.has(key):
		return _mats[key]
	var m := ShaderMaterial.new()
	m.shader = OUTLINE
	m.set_shader_parameter("width", width)
	m.set_shader_parameter("outline_color", color)
	_mats[key] = m
	return m

## Cached toon material. `outline` > 0 adds an ink outline pass.
static func toon(color: Color, outline: float = 0.0, rim: float = 0.0, glow: float = 0.0, tex_strength: float = 0.28) -> ShaderMaterial:
	var key := "t|%s|%s|%s|%s|%s" % [color.to_html(), outline, rim, glow, tex_strength]
	if _mats.has(key):
		return _mats[key]
	var m := ShaderMaterial.new()
	m.shader = TOON
	m.set_shader_parameter("albedo", color)
	m.set_shader_parameter("tex", block_texture())
	m.set_shader_parameter("tex_strength", tex_strength)
	m.set_shader_parameter("rim_strength", rim)
	if glow > 0.0:
		m.set_shader_parameter("emission_color", color)
		m.set_shader_parameter("emission_energy", glow)
	if outline > 0.0:
		m.next_pass = outline_mat(outline)
	_mats[key] = m
	return m

## Material that reads per-vertex / per-instance colour (terrain, leaves, flowers).
static func vertex_toon(tex_strength: float = 0.3) -> ShaderMaterial:
	var key := "vt|%s" % tex_strength
	if _mats.has(key):
		return _mats[key]
	var m := ShaderMaterial.new()
	m.shader = TOON
	m.set_shader_parameter("albedo", Color.WHITE)
	m.set_shader_parameter("tex", block_texture())
	m.set_shader_parameter("tex_strength", tex_strength)
	_mats[key] = m
	return m

static func water_mat(shallow: Color = Color(0.5, 0.92, 0.93, 0.8), deep: Color = Color(0.22, 0.7, 0.88, 0.9), flow: Vector2 = Vector2.ZERO, speed: float = 0.25, tile: float = 1.0) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = WATER
	m.set_shader_parameter("shallow", shallow)
	m.set_shader_parameter("deep", deep)
	m.set_shader_parameter("flow_dir", flow)
	m.set_shader_parameter("flow_speed", speed)
	m.set_shader_parameter("tile", tile)
	return m

static func portal_mat(a: Color = Color(0.45, 0.2, 0.9), b: Color = Color(0.3, 0.85, 1.0)) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = PORTAL
	m.set_shader_parameter("color_a", a)
	m.set_shader_parameter("color_b", b)
	return m

# ------------------------------------------------------------- atmosphere

const MOOD_DAY := {
	"top": Color("5b6fd0"), "mid": Color("f0a0b8"), "horizon": Color("ffcf8f"), "ground": Color("b88aa8"),
	"sun": Color("ffe3a0"), "stars": 0.0, "clouds": 0.55,
	"cloud_a": Color("fff0e6"), "cloud_b": Color("d08bb4"),
	"light": Color("ffd2a0"), "light_energy": 1.05,
	"ambient": Color("b3a6e6"), "ambient_energy": 0.62,
	"fog": Color("ffbfb0"), "fog_density": 0.0042,
}
const MOOD_END := {
	"top": Color("0d0522"), "mid": Color("3a1668"), "horizon": Color("9a58c8"), "ground": Color("1a0b30"),
	"sun": Color("cfb8ff"), "stars": 0.9, "clouds": 0.1,
	"cloud_a": Color("8a6fc0"), "cloud_b": Color("3a2468"),
	"light": Color("b9a4ff"), "light_energy": 0.62,
	"ambient": Color("6a58b8"), "ambient_energy": 0.5,
	"fog": Color("2e1556"), "fog_density": 0.0075,
}

static func make_atmosphere() -> Dictionary:
	var sky_mat := ShaderMaterial.new()
	sky_mat.shader = SKY
	var sky := Sky.new()
	sky.sky_material = sky_mat
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 0.92
	env.tonemap_white = 5.0
	env.glow_enabled = true
	env.glow_intensity = 0.7
	env.glow_bloom = 0.06
	env.glow_hdr_threshold = 1.25
	env.fog_enabled = true
	env.fog_sun_scatter = 0.0
	env.fog_sky_affect = 0.1
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.14
	env.adjustment_contrast = 1.06
	return {"env": env, "sky": sky_mat}

static func apply_mood(env: Environment, sky_mat: ShaderMaterial, sun: DirectionalLight3D, t: float) -> void:
	var a: Dictionary = MOOD_DAY
	var b: Dictionary = MOOD_END
	sky_mat.set_shader_parameter("top_color", (a.top as Color).lerp(b.top, t))
	sky_mat.set_shader_parameter("mid_color", (a.mid as Color).lerp(b.mid, t))
	sky_mat.set_shader_parameter("horizon_color", (a.horizon as Color).lerp(b.horizon, t))
	sky_mat.set_shader_parameter("ground_color", (a.ground as Color).lerp(b.ground, t))
	sky_mat.set_shader_parameter("sun_color", (a.sun as Color).lerp(b.sun, t))
	sky_mat.set_shader_parameter("star_amount", lerpf(a.stars, b.stars, t))
	sky_mat.set_shader_parameter("cloud_amount", lerpf(a.clouds, b.clouds, t))
	sky_mat.set_shader_parameter("cloud_color", (a.cloud_a as Color).lerp(b.cloud_a, t))
	sky_mat.set_shader_parameter("cloud_shadow", (a.cloud_b as Color).lerp(b.cloud_b, t))
	sun.light_color = (a.light as Color).lerp(b.light, t)
	sun.light_energy = lerpf(a.light_energy, b.light_energy, t)
	env.ambient_light_color = (a.ambient as Color).lerp(b.ambient, t)
	env.ambient_light_energy = lerpf(a.ambient_energy, b.ambient_energy, t)
	env.fog_light_color = (a.fog as Color).lerp(b.fog, t)
	env.fog_density = lerpf(a.fog_density, b.fog_density, t)
	# keep the painted sun disc exactly where the light comes from
	var toward_sun: Vector3 = sun.global_transform.basis.z
	sky_mat.set_shader_parameter("sun_dir", toward_sun)

static func make_sun() -> DirectionalLight3D:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-24, 62, 0)
	sun.shadow_enabled = true
	sun.shadow_blur = 1.6
	sun.shadow_bias = 0.04
	sun.shadow_normal_bias = 1.2
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.directional_shadow_max_distance = 58.0
	return sun

# ----------------------------------------------------------------- terrain

static func top_y(level: int) -> float:
	return GROUND_Y + float(level)

## Natural hill height (in whole blocks) for the cell whose corner is (x, z).
static func natural_level(noise: FastNoiseLite, x: int, z: int) -> int:
	var cx := x + 0.5
	var cz := z + 0.5
	var dx := maxf(absf(cx) - PLAY_X, 0.0)
	var dz := 0.0
	if cz < PLAY_Z0:
		dz = PLAY_Z0 - cz
	elif cz > PLAY_Z1:
		dz = cz - PLAY_Z1
	var d := sqrt(dx * dx + dz * dz)
	if d <= 0.0:
		return 0
	var base := 15.0 * (1.0 - exp(-d / 18.0))
	var wob := noise.get_noise_2d(cx, cz) * 5.0 * clampf(d / 10.0, 0.0, 1.0)
	return maxi(int(floor(base + wob + 0.5)), 0)

static func grass_color(rng: RandomNumberGenerator, noise: FastNoiseLite, x: int, z: int, level: int) -> Color:
	var n := noise.get_noise_2d(x * 2.3, z * 2.3)
	var c := Color("8ccf57").lerp(Color("a9dc62"), clampf(n * 1.4 + 0.5, 0.0, 1.0))
	if n < -0.25:
		c = c.lerp(Color("74b84a"), 0.6)
	c = c.lerp(Color("c6d96a"), clampf(float(level) / 26.0, 0.0, 0.35))
	var j := rng.randf_range(-0.035, 0.035)
	return Color(c.r + j, c.g + j, c.b + j * 0.6)

static func in_path(x: int, z: int) -> int:
	# 1 = main stone path, 2 = path edge. Mirrors the original road rectangles.
	var fx := x + 0.5
	var fz := z + 0.5
	if fx >= 0.0 and fx <= 8.0 and fz >= -21.0 and fz <= 17.0:
		return 1
	if fx >= -24.5 and fx <= 0.5 and fz >= 5.5 and fz <= 8.5:
		return 1
	if fx >= -0.8 and fx <= 8.8 and fz >= -21.8 and fz <= 17.8:
		return 2
	if fx >= -25.3 and fx <= 1.3 and fz >= 4.7 and fz <= 9.3:
		return 2
	return 0

static func build_terrain(parent: Node3D, plateaus: Array, water_cells: Dictionary) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var noise := FastNoiseLite.new()
	noise.seed = 1120
	noise.frequency = 0.045
	noise.fractal_octaves = 3
	var pn := FastNoiseLite.new()
	pn.seed = 99
	pn.frequency = 0.09
	var w := GRID_X1 - GRID_X0
	var d := GRID_Z1 - GRID_Z0
	var levels := PackedInt32Array()
	levels.resize(w * d)
	for zi in range(d):
		for xi in range(w):
			var x := GRID_X0 + xi
			var z := GRID_Z0 + zi
			var lv := natural_level(noise, x, z)
			for p in plateaus:
				var dist: float = Vector2(x + 0.5 - p.x, z + 0.5 - p.y).length()
				if dist <= p.z:
					lv = int(p.w)
				elif dist <= p.z + 5.0:
					var blend: float = (dist - p.z) / 5.0
					lv = int(round(lerpf(float(p.w), float(lv), blend)))
			levels[zi * w + xi] = lv

	var chunks: Dictionary = {}
	var cur: Array = [null]

	var lvl := func(x: int, z: int) -> int:
		if x < GRID_X0 or x >= GRID_X1 or z < GRID_Z0 or z >= GRID_Z1:
			return -9
		return levels[(z - GRID_Z0) * w + (x - GRID_X0)]

	var add_quad := func(p: Array, n: Vector3, c: Array, uv: Array) -> void:
		var ch: Dictionary = cur[0]
		var order := [0, 1, 2, 3]
		if ((p[1] - p[0]).cross(p[2] - p[0])).dot(n) > 0.0:
			order = [0, 3, 2, 1]
		var base: int = ch.verts.size()
		for k in order:
			ch.verts.append(p[k])
			ch.norms.append(n)
			ch.cols.append(c[k])
			ch.uvs.append(uv[k])
		ch.idx.append_array([base, base + 1, base + 2, base, base + 2, base + 3])

	for z in range(GRID_Z0, GRID_Z1):
		for x in range(GRID_X0, GRID_X1):
			var lv: int = lvl.call(x, z)
			var y := top_y(lv)
			var ck := Vector2i(int(floor(float(x) / 20.0)), int(floor(float(z) / 20.0)))
			if not chunks.has(ck):
				chunks[ck] = {"verts": PackedVector3Array(), "norms": PackedVector3Array(), "cols": PackedColorArray(), "uvs": PackedVector2Array(), "idx": PackedInt32Array()}
			cur[0] = chunks[ck]
			# --- top face colour
			var cell := Vector2i(x, z)
			var base_col: Color
			var path := in_path(x, z) if lv == 0 else 0
			if water_cells.has(cell):
				base_col = Color("d9c9a0").lerp(Color("c7b88c"), rng.randf())
			elif lv == 0 and x >= -22 and x < -9 and z >= -19 and z < -5:
				base_col = Color("767c8a").lerp(Color("5f6676"), rng.randf() * .8)
				if pn.get_noise_2d(x * 2.0, z * 2.0) > .35:
					base_col = base_col.lerp(Color("5f8f55"), .65)
			elif path == 1:
				var tile := ((x + z) % 2 == 0)
				base_col = Color("d6c4a0") if tile else Color("c4b08a")
				base_col = base_col.lerp(Color("e6d6b4"), rng.randf() * 0.25)
			elif path == 2:
				base_col = Color("a9b768").lerp(Color("c4b27a"), 0.5)
			elif lv >= 9 and pn.get_noise_2d(x, z) > -0.1:
				base_col = Color("9a9aa6").lerp(Color("6f9a5e"), clampf(pn.get_noise_2d(x * 3, z * 3) + 0.2, 0.0, 0.7))
			else:
				base_col = grass_color(rng, pn, x, z, lv)
				if pn.get_noise_2d(x * 1.7 + 40, z * 1.7) > 0.32:
					base_col = base_col.lerp(Color("f0b6d0"), 0.78)  # fallen cherry petals
			# --- baked vertex AO (classic voxel corner darkening)
			var corner_cols: Array = []
			var cx_arr := [x, x + 1, x + 1, x]
			var cz_arr := [z, z, z + 1, z + 1]
			var sx := [-1, 1, 1, -1]
			var sz := [-1, -1, 1, 1]
			for k in range(4):
				var s1: bool = lvl.call(x + sx[k], z) > lv
				var s2: bool = lvl.call(x, z + sz[k]) > lv
				var cn: bool = lvl.call(x + sx[k], z + sz[k]) > lv
				var occ := 3 if (s1 and s2) else (int(s1) + int(s2) + int(cn))
				var shade := 1.0 - 0.13 * float(occ)
				corner_cols.append(Color(base_col.r * shade, base_col.g * shade, base_col.b * shade))
			var pts: Array = [
				Vector3(x, y, z), Vector3(x + 1, y, z), Vector3(x + 1, y, z + 1), Vector3(x, y, z + 1)
			]
			var tuv: Array = [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]
			add_quad.call(pts, Vector3.UP, corner_cols, tuv)
			# --- side faces where the neighbour is lower
			var dirs := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
			for dv in dirs:
				var nl: int = lvl.call(x + dv.x, z + dv.y)
				if nl >= lv:
					continue
				var drop_to := top_y(nl) if nl > -9 else -14.0
				var nrm := Vector3(dv.x, 0, dv.y)
				var a: Vector3
				var b: Vector3
				if dv.x == 1:
					a = Vector3(x + 1, 0, z); b = Vector3(x + 1, 0, z + 1)
				elif dv.x == -1:
					a = Vector3(x, 0, z + 1); b = Vector3(x, 0, z)
				elif dv.y == 1:
					a = Vector3(x + 1, 0, z + 1); b = Vector3(x, 0, z + 1)
				else:
					a = Vector3(x, 0, z); b = Vector3(x + 1, 0, z)
				var cliff := lv >= 9
				var dirt := Color("8d6944") if not cliff else Color("8e909c")
				dirt = dirt.lerp(Color("5b3f2a") if not cliff else Color("5c5f6e"), rng.randf() * 0.35)
				var lip := base_col if not cliff else Color("6f9a5e")
				# grass lip on the upper 0.3 m, dirt/stone below
				var yl := y - 0.3
				var side_a := Color(lip.r * 0.9, lip.g * 0.9, lip.b * 0.9)
				var side_uv: Array = [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]
				add_quad.call([Vector3(a.x, y, a.z), Vector3(b.x, y, b.z), Vector3(b.x, yl, b.z), Vector3(a.x, yl, a.z)], nrm, [side_a, side_a, side_a, side_a], side_uv)
				if yl > drop_to:
					var darker := Color(dirt.r * 0.92, dirt.g * 0.92, dirt.b * 0.92)
					add_quad.call([Vector3(a.x, yl, a.z), Vector3(b.x, yl, b.z), Vector3(b.x, drop_to, b.z), Vector3(a.x, drop_to, a.z)], nrm, [dirt, dirt, darker, darker], side_uv)

	var body := StaticBody3D.new()
	body.name = "TerrainBody"
	parent.add_child(body)
	var first_mi: MeshInstance3D = null
	for ck in chunks.keys():
		var ch: Dictionary = chunks[ck]
		var mesh := ArrayMesh.new()
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = ch.verts
		arrays[Mesh.ARRAY_NORMAL] = ch.norms
		arrays[Mesh.ARRAY_COLOR] = ch.cols
		arrays[Mesh.ARRAY_TEX_UV] = ch.uvs
		arrays[Mesh.ARRAY_INDEX] = ch.idx
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		var mi := MeshInstance3D.new()
		mi.name = "Terrain"
		mi.mesh = mesh
		mi.material_override = vertex_toon(0.32)
		mi.visibility_range_end = 170.0
		parent.add_child(mi)
		if first_mi == null:
			first_mi = mi
		var cs := CollisionShape3D.new()
		cs.shape = mesh.create_trimesh_shape()
		body.add_child(cs)
	return {"levels": levels, "width": w, "mesh": first_mi}

static func level_at_world(data: Dictionary, x: float, z: float) -> int:
	var xi := int(floor(x)) - GRID_X0
	var zi := int(floor(z)) - GRID_Z0
	var w: int = data.width
	var lv: PackedInt32Array = data.levels
	if xi < 0 or xi >= w or zi < 0 or zi * w + xi >= lv.size():
		return 0
	return lv[zi * w + xi]

static func ground_height(data: Dictionary, x: float, z: float) -> float:
	return top_y(level_at_world(data, x, z))

# --------------------------------------------------------------- instancing

## One MultiMesh of coloured unit cubes (leaves, flowers, petals, clouds).
static func cube_cloud(parent: Node3D, items: Array, cube: Vector3 = Vector3.ONE, shadows: bool = true, tex_strength: float = 0.25, name_hint: String = "Cubes") -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var box := BoxMesh.new()
	box.size = cube
	mm.mesh = box
	mm.instance_count = items.size()
	for i in range(items.size()):
		var it: Array = items[i]
		mm.set_instance_transform(i, Transform3D(Basis(), it[0]))
		mm.set_instance_color(i, it[1])
	var mmi := MultiMeshInstance3D.new()
	mmi.name = name_hint
	mmi.multimesh = mm
	mmi.material_override = vertex_toon(tex_strength)
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mmi)
	return mmi

const LEAF_COLORS := [Color("f6b9d2"), Color("ee9fc2"), Color("ffd3e3"), Color("e48db4"), Color("f9c6dc")]
const WOOD_COLORS := [Color("6b5a52"), Color("5a4b47"), Color("7a6760")]

## Appends cube instances for one cherry tree.
static func cherry_tree_cubes(pos: Vector3, rng: RandomNumberGenerator, scale: float, leaves: Array, wood: Array) -> void:
	var h := rng.randi_range(4, 6)
	var lean := Vector2(rng.randf_range(-.6, .6), rng.randf_range(-.6, .6))
	for i in range(h):
		var o := Vector3(lean.x * float(i) / h, i + .5, lean.y * float(i) / h) * scale
		wood.append([pos + o, WOOD_COLORS[rng.randi() % 3]])
	var top := Vector3(lean.x, float(h), lean.y) * scale
	# forked limbs
	var limbs := rng.randi_range(2, 3)
	var ang0 := rng.randf() * TAU
	for l in range(limbs):
		var a := ang0 + TAU * float(l) / limbs
		var dir := Vector3(cos(a), 0, sin(a))
		for s in range(1, 3):
			var o := top + dir * float(s) * .9 * scale + Vector3(0, float(s) * .55 - 1.0, 0) * scale
			wood.append([pos + o, WOOD_COLORS[rng.randi() % 3]])
	var cy := float(h) + 0.8
	var rx := 3.9 * scale
	var ry := 2.1 * scale
	for dy in range(-2, 4):
		for dx in range(-5, 6):
			for dz in range(-5, 6):
				var v := Vector3(dx / rx, dy / ry, dz / rx)
				var dist := v.length()
				if dist > 1.0 or dist < 0.52:
					continue
				if rng.randf() < 0.1 + dist * 0.22:
					continue
				var p := pos + Vector3(dx * scale + lean.x * 2.0, cy + dy * scale * .85, dz * scale + lean.y * 2.0)
				var c: Color = LEAF_COLORS[rng.randi() % LEAF_COLORS.size()]
				if dy < 0:
					c = c.darkened(0.04)
				leaves.append([p, c])

# -------------------------------------------------------------- particles

static func petal_storm(parent: Node3D) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.name = "Petals"
	p.amount = 140
	p.lifetime = 11.0
	p.preprocess = 11.0
	p.visibility_aabb = AABB(Vector3(-40, -12, -40), Vector3(80, 30, 80))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(30, 1.0, 30)
	pm.direction = Vector3(.6, -.2, .25)
	pm.spread = 25.0
	pm.initial_velocity_min = 0.6
	pm.initial_velocity_max = 1.6
	pm.gravity = Vector3(.35, -.55, .1)
	pm.angular_velocity_min = -90.0
	pm.angular_velocity_max = 90.0
	pm.scale_min = 0.6
	pm.scale_max = 1.2
	p.process_material = pm
	var q := QuadMesh.new()
	q.size = Vector2(.17, .12)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color("ffc2d9")
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	q.material = m
	p.draw_pass_1 = q
	p.position = Vector3(0, 9, 0)
	parent.add_child(p)
	return p

static func motes(parent: Node3D, pos: Vector3, color: Color, extents: Vector3, amount: int = 60, rise: float = 0.7) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = amount
	p.lifetime = 6.0
	p.preprocess = 6.0
	p.visibility_aabb = AABB(-extents * 1.5 - Vector3(0, 4, 0), extents * 3.0 + Vector3(0, 12, 0))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = extents
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 15.0
	pm.initial_velocity_min = rise * 0.6
	pm.initial_velocity_max = rise * 1.2
	pm.gravity = Vector3.ZERO
	pm.scale_min = 0.5
	pm.scale_max = 1.3
	p.process_material = pm
	var q := QuadMesh.new()
	q.size = Vector2(.14, .14)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = color
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = 2.0
	q.material = m
	p.draw_pass_1 = q
	p.position = pos
	parent.add_child(p)
	return p

# ------------------------------------------------------------------ props

static func box_node(parent: Node3D, pos: Vector3, size: Vector3, color: Color, outline: float = 0.0, glow: float = 0.0, rim: float = 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	mi.mesh = b
	mi.material_override = toon(color, outline, rim, glow)
	mi.position = pos
	if size.x * size.y * size.z < 0.3:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi

static func lantern(parent: Node3D, pos: Vector3, light: bool = true) -> Node3D:
	var n := Node3D.new()
	n.position = pos
	parent.add_child(n)
	box_node(n, Vector3(0, 0, 0), Vector3(.34, .46, .34), Color("ffd98a"), 0.0, 2.6)
	box_node(n, Vector3(0, .31, 0), Vector3(.46, .1, .46), Color("2d2430"))
	box_node(n, Vector3(0, -.31, 0), Vector3(.42, .1, .42), Color("2d2430"))
	if light:
		var l := OmniLight3D.new()
		l.light_color = Color("ffc67a")
		l.light_energy = 1.1
		l.omni_range = 7.0
		l.shadow_enabled = false
		n.add_child(l)
	return n

static func bamboo_cluster(parent: Node3D, pos: Vector3, rng: RandomNumberGenerator, count: int = 5) -> void:
	for i in range(count):
		var h := rng.randf_range(4.0, 8.0)
		var o := Vector3(rng.randf_range(-.9, .9), 0, rng.randf_range(-.9, .9))
		box_node(parent, pos + o + Vector3(0, h / 2.0, 0), Vector3(.22, h, .22), Color("6fbf4f").lerp(Color("9ad45f"), rng.randf()), 0.0)
		for j in range(1, int(h)):
			box_node(parent, pos + o + Vector3(0, j * 1.0, 0), Vector3(.28, .07, .28), Color("4c8f3a"))
		box_node(parent, pos + o + Vector3(.25, h - .6, 0), Vector3(.5, .12, .22), Color("86d05a"))

static func rock(parent: Node3D, pos: Vector3, rng: RandomNumberGenerator, s: float = 1.0) -> void:
	var c := Color("a4a6b2").lerp(Color("7f8290"), rng.randf())
	box_node(parent, pos + Vector3(0, .35 * s, 0), Vector3(1.4, .7, 1.1) * s, c)
	box_node(parent, pos + Vector3(.2 * s, .8 * s, .1 * s), Vector3(.8, .5, .7) * s, c.lightened(.08))
	if rng.randf() < 0.6:
		box_node(parent, pos + Vector3(-.3 * s, .75 * s, 0), Vector3(.6, .12, .6) * s, Color("78b052"))
