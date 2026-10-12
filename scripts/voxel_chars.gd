extends RefCounted
## Chibi anime-voxel characters for the 3D chapter. Everything is built from
## outlined boxes so it matches the block world, but with real proportions,
## painted faces, hair, and walk/idle animation hooks.

const Style = preload("res://scripts/voxel_style.gd")

const ANAMI := {
	"skin": Color("f3c3a0"), "hair": Color("6a4129"), "hair_hi": Color("90603c"),
	"top": Color("1f9498"), "top_dark": Color("177579"), "under": Color("f2ece0"),
	"bottom": Color("2c3a5c"), "shoes": Color("efe6da"), "iris": Color("8c5a34"),
	"glasses": true, "style": "anami",
}
const GUILLERMO := {
	"skin": Color("ebb78d"), "hair": Color("5e3a22"), "hair_hi": Color("86593a"),
	"top": Color("2a2e38"), "top_dark": Color("1d2028"), "under": Color("e9dfce"),
	"bottom": Color("303c58"), "shoes": Color("3b302c"), "iris": Color("4a301d"),
	"glasses": false, "style": "guillermo",
}
const VILLAGER := {
	"skin": Color("d5a07c"), "hair": Color("6b4a33"), "hair_hi": Color("6b4a33"),
	"top": Color("8a6844"), "top_dark": Color("6e5035"), "under": Color("7ea65c"),
	"bottom": Color("5a4430"), "shoes": Color("4a3828"), "iris": Color("4f9a5a"),
	"glasses": false, "style": "villager",
}

# ----------------------------------------------------------------- helpers

static func _b(parent: Node3D, pos: Vector3, size: Vector3, color: Color, outline: float = 0.026, rim: float = 0.0, glow: float = 0.0, tex: float = 0.1) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = Style.toon(color, outline, rim, glow, tex)
	mi.position = pos
	parent.add_child(mi)
	return mi

static func _pivot(parent: Node3D, pos: Vector3, nm: String) -> Node3D:
	var n := Node3D.new()
	n.name = nm
	n.position = pos
	parent.add_child(n)
	return n

# -------------------------------------------------------------- face paint

static func _blend(img: Image, x: int, y: int, col: Color, cov: float) -> void:
	if cov <= 0.0 or x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
		return
	var old := img.get_pixel(x, y)
	var a := clampf(cov * col.a, 0.0, 1.0)
	img.set_pixel(x, y, Color(old.r * (1.0 - a) + col.r * a, old.g * (1.0 - a) + col.g * a, old.b * (1.0 - a) + col.b * a, 1.0))

static func _ell(img: Image, cx: float, cy: float, rx: float, ry: float, col: Color, ring: float = 0.0, ymin: float = -9999.0, ymax: float = 9999.0) -> void:
	var x0 := int(cx - rx - 3)
	var x1 := int(cx + rx + 3)
	var y0 := int(cy - ry - 3)
	var y1 := int(cy + ry + 3)
	var m := minf(rx, ry)
	for y in range(y0, y1 + 1):
		if float(y) < ymin or float(y) > ymax:
			continue
		for x in range(x0, x1 + 1):
			var u := (x + 0.5 - cx) / rx
			var v := (y + 0.5 - cy) / ry
			var dpx := (sqrt(u * u + v * v) - 1.0) * m
			var cov := clampf(0.5 - dpx, 0.0, 1.0)
			if ring > 0.0:
				cov *= clampf(dpx + ring + 0.5, 0.0, 1.0)
			_blend(img, x, y, col, cov)

static func _curve(img: Image, p0: Vector2, p1: Vector2, p2: Vector2, thick: float, col: Color) -> void:
	for i in range(0, 25):
		var t := float(i) / 24.0
		var p := p0.lerp(p1, t).lerp(p1.lerp(p2, t), t)
		_ell(img, p.x, p.y, thick * 0.5, thick * 0.5, col)

static func paint_face(spec: Dictionary, mood: String = "neutral") -> ImageTexture:
	var w := 176
	var h := 128
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var skin: Color = spec.skin
	img.fill(Color(skin.r, skin.g, skin.b, 1.0))
	var style: String = spec.style
	var ink := Color("2a1a1c")
	var ex := [50.0, 126.0]
	var ey := 70.0
	if style == "villager":
		for i in range(2):
			_ell(img, ex[i], ey, 14, 11, Color("f4f0e6"))
			_ell(img, ex[i] + (3.0 if i == 0 else -3.0), ey, 7, 8, spec.iris)
			_ell(img, ex[i] + (3.0 if i == 0 else -3.0), ey, 3.4, 4.0, Color("1d2a1e"))
		_curve(img, Vector2(30, 44), Vector2(88, 38), Vector2(146, 44), 8.0, Color("4a3524"))
		_ell(img, 88.0, 100.0, 12.0, 3.0, Color("8d5a48"))
		return ImageTexture.create_from_image(img)
	# blush first (under everything)
	for i in range(2):
		_ell(img, ex[i] + (-4.0 if i == 0 else 4.0), 102.0, 15.0, 7.0, Color(1.0, 0.52, 0.58, 0.32))
	# eyes
	for i in range(2):
		var cx: float = ex[i]
		if mood == "happy":
			_ell(img, cx, ey + 8.0, 17.0, 13.0, ink, 4.4, -9999.0, ey + 8.0)
		else:
			_ell(img, cx, ey, 17.0, 23.0, Color("fbf8f6"))
			_ell(img, cx, ey + 3.0, 14.4, 20.0, spec.iris)
			_ell(img, cx, ey + 11.0, 11.0, 10.0, (spec.iris as Color).lightened(0.32).lerp(Color("ffd9a8"), 0.25))
			_ell(img, cx, ey + 1.0, 6.4, 10.4, Color("1c1214"))
			# upper lash line, thick
			_ell(img, cx, ey, 18.0, 24.0, ink, 5.0, -9999.0, ey + 1.0)
			# wing tip
			var out := -1.0 if i == 0 else 1.0
			_curve(img, Vector2(cx + out * 12.0, ey - 5.0), Vector2(cx + out * 18.0, ey - 7.0), Vector2(cx + out * 20.0, ey - 12.0), 3.4, ink)
			# highlights
			_ell(img, cx - 5.5, ey - 7.5, 5.6, 6.4, Color.WHITE)
			_ell(img, cx + 5.5, ey + 11.0, 3.0, 3.0, Color(1, 1, 1, 0.9))
	# brows
	var bcol: Color = (spec.hair as Color).darkened(0.25)
	var inner := 0.0
	if mood == "worried":
		inner = -7.0
	elif mood == "determined":
		inner = 5.0
	_curve(img, Vector2(ex[0] - 14.0, 38.0), Vector2(ex[0] - 1.0, 32.0 + inner * 0.5), Vector2(ex[0] + 13.0, 36.0 + inner), 4.4, bcol)
	_curve(img, Vector2(ex[1] + 14.0, 38.0), Vector2(ex[1] + 1.0, 32.0 + inner * 0.5), Vector2(ex[1] - 13.0, 36.0 + inner), 4.4, bcol)
	# nose hint + mouth
	_curve(img, Vector2(87.0, 84.0), Vector2(89.0, 88.0), Vector2(85.0, 90.0), 2.0, skin.darkened(0.2))
	if mood == "happy":
		_ell(img, 88.0, 108.0, 12.0, 9.0, Color("86303a"), 0.0, 106.0, 9999.0)
		_ell(img, 88.0, 117.0, 7.0, 4.0, Color("e8737f"), 0.0, 112.0, 9999.0)
		_ell(img, 88.0, 104.5, 11.0, 2.2, Color("fdfafa"), 0.0, 104.0, 108.0)
	elif mood == "worried":
		_curve(img, Vector2(77.0, 108.0), Vector2(88.0, 101.0), Vector2(99.0, 108.0), 3.0, Color("9a4a4e"))
	else:
		_curve(img, Vector2(76.0, 106.0), Vector2(88.0, 113.0), Vector2(100.0, 106.0), 3.0, Color("a5504f"))
	# glasses
	if spec.glasses:
		var gc := Color("3a2418")
		for i in range(2):
			_ell(img, ex[i], ey + 1.0, 31.0, 30.0, gc, 3.8)
			_ell(img, ex[i], ey + 1.0, 28.0, 27.0, Color(0.7, 0.85, 1.0, 0.07))
			_ell(img, ex[i] - 9.0, ey - 12.0, 8.0, 3.0, Color(1, 1, 1, 0.22))
		_curve(img, Vector2(ex[0] + 29.0, ey - 2.0), Vector2(88.0, ey - 9.0), Vector2(ex[1] - 29.0, ey - 2.0), 3.2, gc)
		_curve(img, Vector2(ex[0] - 26.0, ey - 4.0), Vector2(10.0, ey - 8.0), Vector2(0.0, ey - 6.0), 3.0, gc)
		_curve(img, Vector2(ex[1] + 26.0, ey - 4.0), Vector2(166.0, ey - 8.0), Vector2(176.0, ey - 6.0), 3.0, gc)
	return ImageTexture.create_from_image(img)

static func face_material(spec: Dictionary, mood: String) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = Style.TOON
	m.set_shader_parameter("albedo", spec.skin)
	m.set_shader_parameter("tex", Style.block_texture())
	m.set_shader_parameter("tex_strength", 0.04)
	m.set_shader_parameter("decal", paint_face(spec, mood))
	m.set_shader_parameter("decal_amount", 1.0)
	m.set_shader_parameter("rim_strength", 0.2)
	return m

# --------------------------------------------------------------- humanoids

static func build_humanoid(spec: Dictionary, mood: String = "neutral") -> Node3D:
	var root := Node3D.new()
	root.name = "Char"
	var body := _pivot(root, Vector3.ZERO, "Body")
	var skin: Color = spec.skin
	var style: String = spec.style
	# legs
	for s in [-1.0, 1.0]:
		var leg := _pivot(body, Vector3(.15 * s, .6, 0), "LegL" if s < 0 else "LegR")
		_b(leg, Vector3(0, -.29, 0), Vector3(.2, .56, .22), spec.bottom)
		_b(leg, Vector3(0, -.55, -.04), Vector3(.23, .13, .31), spec.shoes, 0.026)
		_b(leg, Vector3(0, -.6, -.04), Vector3(.24, .04, .32), (spec.shoes as Color).darkened(0.35), 0.0)
	# torso
	var torso := _pivot(body, Vector3(0, .87, 0), "Torso")
	_b(torso, Vector3.ZERO, Vector3(.52, .52, .3), spec.top, 0.026, 0.25)
	_b(torso, Vector3(0, -.2, 0), Vector3(.54, .13, .32), spec.top_dark, 0.0)
	if style == "guillermo":
		_b(torso, Vector3(0, .02, -.152), Vector3(.2, .48, .02), spec.under, 0.0)
		_b(torso, Vector3(-.17, .1, -.152), Vector3(.08, .34, .025), (spec.top as Color).lightened(0.08), 0.0)
		_b(torso, Vector3(0, .27, 0), Vector3(.56, .1, .34), spec.top_dark, 0.02)  # collar
	elif style == "anami":
		_b(torso, Vector3(0, .24, -.145), Vector3(.22, .1, .03), skin, 0.0)  # neckline
		_b(torso, Vector3(0, .02, -.152), Vector3(.5, .04, .02), (spec.top as Color).lightened(0.18), 0.0)
		# little satchel strap
		_b(torso, Vector3(.0, .02, -.0), Vector3(.1, .56, .33), Color("c88c58"), 0.0)
	elif style == "villager":
		_b(torso, Vector3(0, -.02, -.155), Vector3(.34, .44, .02), spec.under, 0.0)
		_b(torso, Vector3(0, .0, 0), Vector3(.56, .08, .34), Color("5c4430"), 0.0)
	# arms
	for s in [-1.0, 1.0]:
		var arm := _pivot(body, Vector3(.34 * s, 1.1, 0), "ArmL" if s < 0 else "ArmR")
		_b(arm, Vector3(0, -.16, 0), Vector3(.16, .34, .18), spec.top, 0.024)
		_b(arm, Vector3(0, -.42, 0), Vector3(.13, .2, .15), skin if style != "guillermo" else skin, 0.022)
		var hand := _pivot(arm, Vector3(0, -.56, 0), "Hand")
		_b(hand, Vector3.ZERO, Vector3(.14, .12, .14), skin, 0.02)
	# head
	var head := _pivot(body, Vector3(0, 1.5, 0), "Head")
	_b(head, Vector3.ZERO, Vector3(.76, .72, .7), skin, 0.03, 0.3, 0.0, 0.05)
	for s in [-1.0, 1.0]:
		_b(head, Vector3(.4 * s, -.02, .02), Vector3(.06, .16, .14), skin, 0.015)
	var face := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(.72, .52)
	face.mesh = q
	face.material_override = face_material(spec, mood)
	face.position = Vector3(0, -.06, -.353)
	face.rotation.y = PI
	face.name = "Face"
	head.add_child(face)
	if style == "anami":
		_hair_anami(head, spec)
	elif style == "guillermo":
		_hair_guillermo(head, spec)
	elif style == "villager":
		_b(head, Vector3(0, -.12, -.42), Vector3(.17, .3, .18), skin.darkened(0.08), 0.02)
		_b(head, Vector3(0, .38, 0), Vector3(.8, .1, .74), (spec.hair as Color), 0.02)
	root.set_meta("spec_style", style)
	return root

static func _hair_anami(head: Node3D, spec: Dictionary) -> void:
	var hc: Color = spec.hair
	var hh: Color = spec.hair_hi
	var back := _pivot(head, Vector3(0, 0, 0), "HairBack")
	_b(head, Vector3(0, .43, .02), Vector3(.84, .2, .8), hc, 0.03, 0.4)                 # crown
	_b(head, Vector3(0, .2, .02), Vector3(.82, .2, .78), hc, 0.0, 0.0)                 # upper skull cover
	_b(back, Vector3(0, -.12, .39), Vector3(.84, .98, .2), hc, 0.03, 0.35)              # long back mass
	_b(back, Vector3(-.2, -.7, .4), Vector3(.4, .34, .22), hc, 0.03, 0.3)               # wavy tail L
	_b(back, Vector3(.22, -.76, .42), Vector3(.42, .34, .22), hh, 0.03, 0.3)            # wavy tail R
	_b(back, Vector3(0, -.58, .42), Vector3(.5, .22, .2), hc, 0.0, 0.0)
	for s in [-1.0, 1.0]:
		_b(head, Vector3(.45 * s, -.12, .02), Vector3(.14, .86, .54), hc, 0.03, 0.35)    # face-framing locks
		_b(head, Vector3(.46 * s, -.58, .06), Vector3(.16, .34, .44), hh if s > 0 else hc, 0.03, 0.3)
	# bangs, centre-parted with a gap
	_b(head, Vector3(-.23, .31, -.37), Vector3(.32, .2, .1), hc, 0.0, 0.2)
	_b(head, Vector3(.22, .3, -.37), Vector3(.3, .24, .1), hh, 0.0, 0.2)
	_b(head, Vector3(-.34, .2, -.375), Vector3(.14, .22, .08), hc, 0.0)
	_b(head, Vector3(.35, .18, -.375), Vector3(.14, .26, .08), hh, 0.0)
	_b(head, Vector3(0, .39, -.34), Vector3(.2, .12, .14), hc, 0.0)

static func _hair_guillermo(head: Node3D, spec: Dictionary) -> void:
	var hc: Color = spec.hair
	var hh: Color = spec.hair_hi
	_b(head, Vector3(0, .43, .0), Vector3(.82, .24, .78), hc, 0.03, 0.4)
	_b(head, Vector3(0, .6, -.06), Vector3(.5, .14, .42), hh, 0.02, 0.35)                # swept volume on top
	_b(head, Vector3(.1, .33, -.36), Vector3(.64, .2, .14), hc, 0.0, 0.25)               # fringe
	_b(head, Vector3(-.2, .2, -.375), Vector3(.2, .2, .08), hc, 0.0)
	_b(head, Vector3(.3, .25, -.38), Vector3(.2, .26, .08), hh, 0.0)                      # forelock
	for s in [-1.0, 1.0]:
		_b(head, Vector3(.42 * s, .16, .0), Vector3(.1, .44, .56), hc, 0.03, 0.3)
		_b(head, Vector3(.41 * s, -.06, -.2), Vector3(.09, .22, .12), hc, 0.0)
	_b(head, Vector3(0, .05, .38), Vector3(.82, .56, .12), hc, 0.03, 0.3)                # back/nape
	_b(head, Vector3(0, -.2, .37), Vector3(.5, .12, .1), hc, 0.0)

# --------------------------------------------------------------- animation

static func part(ch: Node3D, path: String) -> Node3D:
	return ch.get_node_or_null(path) as Node3D

## Walk / idle animation for humanoid rigs. `speed` 0..1 (1 = running pace).
static func animate_humanoid(ch: Node3D, t: float, speed: float, swing: float = 0.0, look_at_world: Variant = null) -> void:
	var body := part(ch, "Body")
	if body == null:
		return
	var s := clampf(speed, 0.0, 1.0)
	var ph := t * 9.5
	var ll := part(body, "LegL")
	var lr := part(body, "LegR")
	var al := part(body, "ArmL")
	var ar := part(body, "ArmR")
	var head := part(body, "Head")
	var hb := part(body, "Head/HairBack")
	var torso := part(body, "Torso")
	var amp := 0.75 * s
	ll.rotation.x = lerp_angle(ll.rotation.x, sin(ph) * amp, 0.35)
	lr.rotation.x = lerp_angle(lr.rotation.x, -sin(ph) * amp, 0.35)
	al.rotation.x = lerp_angle(al.rotation.x, -sin(ph) * amp * 0.8, 0.35)
	var arm_target := sin(ph) * amp * 0.8
	if swing > 0.0:
		# overhead swing: wind up then slash down
		var k := 1.0 - swing
		arm_target = lerpf(-2.5, 0.35, smoothstep(0.0, 1.0, k * 1.15))
	ar.rotation.x = lerp_angle(ar.rotation.x, arm_target, 0.55 if swing > 0.0 else 0.35)
	var bob := absf(sin(ph)) * 0.06 * s + sin(t * 2.0) * 0.008 * (1.0 - s)
	body.position.y = bob
	torso.rotation.z = sin(ph) * 0.05 * s
	head.rotation.z = -sin(ph) * 0.04 * s
	if hb:
		hb.rotation.x = lerp_angle(hb.rotation.x, -0.08 * s + sin(ph * 0.5 + 1.0) * 0.05 * s + sin(t * 1.4) * 0.015, 0.2)
	if look_at_world != null:
		var local: Vector3 = ch.global_transform.affine_inverse() * (look_at_world as Vector3)
		var yaw := clampf(atan2(-local.x, -local.z), -0.7, 0.7)
		head.rotation.y = lerp_angle(head.rotation.y, yaw * 0.8, 0.12)

# ------------------------------------------------------------------- cat

static func build_cat() -> Node3D:
	var root := Node3D.new()
	root.name = "Cat"
	var orange := Color("ee9a45")
	var cream := Color("fbe6c4")
	var dark := Color("c4742a")
	var o := 0.02
	_b(root, Vector3(0, .34, .12), Vector3(.4, .36, .74), orange, o, 0.3)
	for z in [-.05, .12, .3]:
		_b(root, Vector3(0, .54, z), Vector3(.42, .05, .08), dark, 0.0)
	_b(root, Vector3(0, .3, -.24), Vector3(.28, .22, .1), cream, 0.0)
	var head := _pivot(root, Vector3(0, .54, -.42), "Head")
	_b(head, Vector3(0, 0, 0), Vector3(.46, .4, .4), orange, o, 0.3)
	_b(head, Vector3(0, -.08, -.22), Vector3(.24, .14, .08), cream, 0.0)
	_b(head, Vector3(0, -.02, -.262), Vector3(.07, .05, .03), Color("f08aa0"), 0.0)
	for s in [-1.0, 1.0]:
		_b(head, Vector3(.15 * s, .27, 0), Vector3(.13, .2, .1), orange, o)
		_b(head, Vector3(.15 * s, .26, -.045), Vector3(.07, .12, .03), Color("f4a4b4"), 0.0)
		_b(head, Vector3(.12 * s, .05, -.208), Vector3(.1, .13, .02), Color("2a1a14"), 0.0)
		_b(head, Vector3(.115 * s, .08, -.222), Vector3(.04, .05, .01), Color.WHITE, 0.0)
	for x in [-.13, .13]:
		for z in [-.14, .42]:
			_b(root, Vector3(x, .11, z), Vector3(.12, .22, .12), orange, o)
			_b(root, Vector3(x, .035, z - .01), Vector3(.13, .07, .15), cream, 0.0)
	var tail := _pivot(root, Vector3(0, .42, .5), "Tail")
	_b(tail, Vector3(0, .1, .06), Vector3(.1, .26, .1), orange, o)
	_b(tail, Vector3(0, .3, .1), Vector3(.1, .22, .1), dark, o)
	_b(tail, Vector3(0, .46, .08), Vector3(.1, .12, .1), cream, 0.0)
	root.scale = Vector3.ONE * 1.25
	return root

static func animate_cat(cat: Node3D, t: float, moving: bool) -> void:
	var tail := part(cat, "Tail")
	if tail:
		tail.rotation.z = sin(t * (6.0 if moving else 2.4)) * 0.35
		tail.rotation.x = -0.25
	var head := part(cat, "Head")
	if head:
		head.rotation.z = sin(t * 1.3) * 0.06

# ----------------------------------------------------------- enemies / boss

static func build_shade() -> Node3D:
	var root := Node3D.new()
	root.name = "Shade"
	var fl := _pivot(root, Vector3(0, .55, 0), "Float")
	var ink := Color("241a3c")
	var edge := Color("8a55e6")
	var ol := Style.outline_mat(0.045, edge)
	for spec in [[Vector3(0, .5, 0), Vector3(.92, 1.0, .86)], [Vector3(0, -.15, 0), Vector3(.72, .34, .68)], [Vector3(.0, -.45, 0), Vector3(.4, .26, .4)]]:
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = spec[1]
		mi.mesh = bm
		var m: ShaderMaterial = Style.toon(ink, 0.0, 0.55, 0.0, 0.05).duplicate()
		m.next_pass = ol
		mi.material_override = m
		mi.position = spec[0]
		fl.add_child(mi)
	for s in [-1.0, 1.0]:
		_b(fl, Vector3(.21 * s, .72, -.44), Vector3(.2, .24, .04), Color("35cfff"), 0.0, 2.0)
		var h := _b(fl, Vector3(.34 * s, 1.15, .0), Vector3(.12, .4, .12), ink, 0.03, 0.4)
		h.rotation.z = -.3 * s
	_b(fl, Vector3(0, .52, -.44), Vector3(.34, .06, .04), Color("35cfff"), 0.0, 1.6)
	var orbit := _pivot(fl, Vector3(0, .5, 0), "Orbit")
	for i in range(3):
		var a := TAU * float(i) / 3.0
		_b(orbit, Vector3(cos(a) * 1.05, sin(a * 2.0) * .15, sin(a) * 1.05), Vector3(.16, .16, .16), edge, 0.0, 0.0, 2.6)
	return root

static func animate_shade(sh: Node3D, t: float, seed_val: float) -> void:
	var fl := part(sh, "Float")
	if fl:
		fl.position.y = .55 + sin(t * 2.2 + seed_val) * .12
	var orbit := part(sh, "Float/Orbit")
	if orbit:
		orbit.rotation.y = t * 1.6 + seed_val

static func build_boss() -> Node3D:
	var root := Node3D.new()
	root.name = "Boss"
	var fl := _pivot(root, Vector3(0, .15, 0), "Float")
	var robe := Color("1b1430")
	var edge := Color("56e0ff")
	var ol := Style.outline_mat(0.04, Color("7a4be0"))
	for spec in [[Vector3(0, .35, 0), Vector3(1.1, .7, .85)], [Vector3(0, .95, 0), Vector3(.9, .6, .7)], [Vector3(0, 1.45, 0), Vector3(.72, .5, .6)], [Vector3(0, 1.75, 0), Vector3(1.2, .24, .66)]]:
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = spec[1]
		mi.mesh = bm
		var m: ShaderMaterial = Style.toon(robe, 0.0, 0.5, 0.0, 0.05).duplicate()
		m.next_pass = ol
		mi.material_override = m
		mi.position = spec[0]
		fl.add_child(mi)
	var head := _pivot(fl, Vector3(0, 2.2, 0), "Head")
	_b(head, Vector3.ZERO, Vector3(.78, .78, .72), robe, 0.0, 0.5)
	head.get_child(0).material_override = Style.toon(robe, 0.0, 0.5, 0.0, 0.05).duplicate()
	(head.get_child(0).material_override as ShaderMaterial).next_pass = ol
	_b(head, Vector3(0, -.02, -.365), Vector3(.52, .46, .04), Color("08040f"), 0.0)
	for s in [-1.0, 1.0]:
		_b(head, Vector3(.14 * s, .02, -.39), Vector3(.14, .08, .03), edge, 0.0, 0.0, 4.0)
		var horn := _b(head, Vector3(.3 * s, .52, 0), Vector3(.14, .5, .14), robe, 0.03, 0.4)
		horn.rotation.z = -.35 * s
	for s in [-1.0, 1.0]:
		var arm := _pivot(fl, Vector3(.7 * s, 1.7, -.1), "Arm" + ("L" if s < 0 else "R"))
		_b(arm, Vector3(0, -.4, -.25), Vector3(.24, .8, .26), robe, 0.03, 0.4)
		_b(arm, Vector3(0, -.85, -.35), Vector3(.2, .2, .2), edge, 0.0, 0.0, 3.0)
		arm.rotation.x = -.5
	var crown := _pivot(fl, Vector3(0, 3.0, 0), "Crown")
	for i in range(5):
		var a := TAU * float(i) / 5.0
		var shard := _b(crown, Vector3(cos(a) * .85, sin(a * 3.0) * .12, sin(a) * .85), Vector3(.16, .42, .16), Color("a67bff"), 0.0, 0.0, 3.0)
		shard.rotation = Vector3(0.3, a, 0.3)
	return root

static func animate_boss(b: Node3D, t: float, angry: bool) -> void:
	var fl := part(b, "Float")
	if fl:
		fl.position.y = .15 + sin(t * 1.5) * .18
	var crown := part(b, "Float/Crown")
	if crown:
		crown.rotation.y = t * (2.4 if angry else 0.8)
	for n in ["Float/ArmL", "Float/ArmR"]:
		var arm := part(b, n)
		if arm:
			arm.rotation.x = -.5 + sin(t * 1.8 + (0.0 if n.ends_with("L") else 1.3)) * .12 - (0.5 if angry else 0.0)
