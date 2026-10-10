extends Node3D

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
var danger_ring: MeshInstance3D
var world_environment: Environment
var daylight: DirectionalLight3D
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

func _mat(key: String, color: Color) -> StandardMaterial3D:
	if materials.has(key):
		return materials[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 1.0
	var pixels := Image.create(16, 16, false, Image.FORMAT_RGB8)
	var rng := RandomNumberGenerator.new()
	rng.seed = absi(key.hash())
	for y in range(16):
		for x in range(16):
			var grain: float = rng.randf_range(.88, 1.0)
			if y % 5 == 0 and x % 4 != 0:
				grain = .82
			pixels.set_pixel(x, y, Color(grain, grain, grain))
	m.albedo_texture = ImageTexture.create_from_image(pixels)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	materials[key] = m
	return m

func _box(pos: Vector3, size: Vector3, color: Color, solid: bool = false, parent: Node3D = null) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var cube := BoxMesh.new()
	cube.size = size
	mesh.mesh = cube
	mesh.material_override = _mat(str(color), color)
	mesh.position = pos
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
	l.font_size = 40
	l.pixel_size = 0.01
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.outline_size = 8
	add_child(l)
	return l

func _marker(key: String, pos: Vector3, title: String) -> void:
	targets[key] = pos
	marker_labels[key] = _label(pos + Vector3(0, 2.8, 0), title)

func _avatar(pos: Vector3, clothing: Color, hair: Color, parent: Node3D = null) -> Node3D:
	var a := Node3D.new()
	(self if parent == null else parent).add_child(a)
	a.position = pos
	_box(Vector3(0, 1.1, 0), Vector3(.55, .7, .35), clothing, false, a)
	_box(Vector3(0, 1.7, 0), Vector3(.5, .5, .5), Color("d7aa83"), false, a)
	_box(Vector3(0, 1.97, .02), Vector3(.56, .18, .54), hair, false, a)
	for x in [-.13, .13]:
		_box(Vector3(x, 1.73, -.26), Vector3(.07, .06, .03), Color("473932"), false, a)
	_box(Vector3(0, 1.57, -.26), Vector3(.14, .035, .03), Color("b27671"), false, a)
	_box(Vector3(-.14, .4, 0), Vector3(.2, .65, .25), Color("293b4c"), false, a)
	_box(Vector3(.14, .4, 0), Vector3(.2, .65, .25), Color("293b4c"), false, a)
	_box(Vector3(-.39, 1.1, 0), Vector3(.18, .7, .25), clothing, false, a)
	_box(Vector3(.39, 1.1, 0), Vector3(.18, .7, .25), clothing, false, a)
	return a

func _build_world() -> void:
	var env := WorldEnvironment.new()
	var atmosphere := Environment.new()
	world_environment=atmosphere
	atmosphere.background_mode = Environment.BG_COLOR
	atmosphere.background_color = Color("b5cfde")
	atmosphere.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	atmosphere.ambient_light_color = Color("ffe4d0")
	atmosphere.ambient_light_energy = .7
	env.environment = atmosphere
	add_child(env)
	var sun := DirectionalLight3D.new()
	daylight=sun
	sun.rotation_degrees = Vector3(-55, -35, 0)
	sun.light_color = Color("ffdfbc")
	sun.light_energy = 1.2
	add_child(sun)
	_box(Vector3(0, -.6, 0), Vector3(70, 1, 56), Color("789756"), true)
	_box(Vector3(4, -.04, -2), Vector3(8, .1, 38), Color("b4a485"))
	_box(Vector3(-12, -.04, 7), Vector3(25, .1, 3), Color("b4a485"))
	_house(Vector3(-12, 0, 3))
	_pagoda(Vector3(-27, 0, -20))
	for x in [-25, -19, -5, 12, 19, 26]:
		_tree(Vector3(x, 0, -15 + (x % 3) * 4))
	for x in [-26, -20, 14, 24]:
		_tree(Vector3(x, 0, 19))
	_box(Vector3(-4, -.01, 12), Vector3(5, .15, 4), Color("619ba9"))
	_marker("fish", Vector3(-4, 0, 12), "Estanque · pescado [E]")
	cat = Node3D.new()
	add_child(cat)
	cat.position = Vector3(-9, 0, 8)
	_box(Vector3(0, .35, 0), Vector3(.65, .45, .3), Color("e5bd83"), false, cat)
	_box(Vector3(-.3, .6, 0), Vector3(.3, .3, .3), Color("f0d2a2"), false, cat)
	_box(Vector3(-.38, .8, 0), Vector3(.12, .18, .22), Color("e5bd83"), false, cat)
	_marker("cat", cat.position, "Un amigo con bigotes [E]")
	_farms()
	_cave()
	_end_island()
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
	player_art = _avatar(Vector3.ZERO, Color("718eac"), Color("946943"), player)
	_box(Vector3(0, 1.67, .23), Vector3(.56, .66, .16), Color("946943"), false, player_art)
	pivot = Node3D.new()
	player.add_child(pivot)
	pivot.position.y = 1.7
	var arm := SpringArm3D.new()
	arm.spring_length = 5.7
	arm.margin = .3
	arm.add_excluded_object(player.get_rid())
	pivot.add_child(arm)
	camera = Camera3D.new()
	camera.fov = 66
	arm.add_child(camera)
	camera.current = true
	sword = Node3D.new()
	player.add_child(sword)
	sword.position = Vector3(.6, 1, -.3)
	_box(Vector3(0, .4, 0), Vector3(.12, .9, .12), Color("bdd4e1"), false, sword)
	_box(Vector3.ZERO, Vector3(.4, .12, .15), Color("bd9855"), false, sword)

func _tree(pos: Vector3) -> void:
	_box(pos + Vector3(0, 1.5, 0), Vector3(.6, 3, .6), Color("704e39"), true)
	_box(pos + Vector3(0, 3.5, 0), Vector3(3.8, 1.8, 3.8), Color("db9dae"))
	_box(pos + Vector3(.4, 4.6, 0), Vector3(2.6, .8, 2.7), Color("e8b1bc"))

func _house(pos: Vector3) -> void:
	_box(pos + Vector3(0, -.3, 0), Vector3(10, .4, 8), Color("71564d"), true)
	_box(pos + Vector3(0, 3, -4), Vector3(10, 6, .4), Color("e1ddd1"), true)
	_box(pos + Vector3(-5, 3, 0), Vector3(.4, 6, 8), Color("e1ddd1"), true)
	_box(pos + Vector3(5, 3, 0), Vector3(.4, 6, 8), Color("e1ddd1"), true)
	for x in [-3.4, 3.4]:
		_box(pos + Vector3(x, 3, 4), Vector3(3, 6, .4), Color("e1ddd1"), true)
		_box(pos + Vector3(x, 3.8, 4.25), Vector3(1.4, 1.6, .2), Color("c68194"))
		_box(pos + Vector3(x, 3.8, 4.38), Vector3(.8, 1.2, .1), Color("8db9bf"))
	for x in [-5, 5]:
		for z in [-4, 4]:
			_box(pos + Vector3(x, 3, z), Vector3(.6, 6.5, .6), Color("3d3937"))
	for tier in range(10):
		_box(pos + Vector3(0, 6.3 + tier * .5, 0), Vector3(11 - tier * 1.05, .5, 9), Color("33363b"))
		_box(pos + Vector3(0, 6.3 + tier * .5, 4.6), Vector3(11 - tier * 1.05, .5, .25), Color("ba8294") if tier % 3 == 0 else Color("33363b"))
	_box(pos + Vector3(0, 7.3, 4.7), Vector3(2.8, 2.3, .4), Color("e1ddd1"))
	_box(pos + Vector3(0, 7.3, 4.95), Vector3(1.4, 1.6, .2), Color("b88b9e"))
	_box(pos + Vector3(0, 7.3, 5.08), Vector3(.85, 1.1, .1), Color("91bdc5"))
	_box(pos + Vector3(0, 8.5, 4.7), Vector3(3.2, .3, 1.5), Color("33363b"))
	_box(pos + Vector3(-2, .65, -2), Vector3(2.8, 1, 1.8), Color("608aa6"), true)
	_box(pos + Vector3(-2, 1, -3), Vector3(3, 1.5, .4), Color("d49aac"))
	_box(pos + Vector3(2.7, .8, -2), Vector3(1.8, 1.4, 1), Color("a37b51"), true)
	_box(pos + Vector3(0, 4, -2), Vector3(8, .3, 3), Color("9f7752"))
	_box(pos + Vector3(0, 4.6, -.5), Vector3(8, .2, .2), Color("594436"))
	for x in [-3, 0, 3]:
		_box(pos + Vector3(x, 4.3, -.5), Vector3(.15, .7, .15), Color("594436"))
	_box(pos + Vector3(0, 3.5, 0), Vector3(.45, .5, .45), Color("ffdb84"))
	_label(pos + Vector3(0, 12, 0), "Nuestro refugio")

func _pagoda(pos: Vector3) -> void:
	_box(pos + Vector3(0, 1, 0), Vector3(9, 2, 9), Color("758363"), true)
	for tier in range(3):
		var y: float = 2.5 + tier * 2.2
		var width: float = 6.5 - tier * 1.3
		_box(pos + Vector3(0, y + .7, 0), Vector3(width, 1.8, width), Color("e6d3b9"))
		for x in [-1, 1]:
			for z in [-1, 1]:
				_box(pos + Vector3(x * width / 2, y + .7, z * width / 2), Vector3(.35, 2, .35), Color("71533b"))
		_box(pos + Vector3(0, y + 1.8, 0), Vector3(width + 1.5, .3, width + 1.5), Color("846571"))
		_box(pos + Vector3(0, y + 2.1, 0), Vector3(width + .5, .4, width + .5), Color("5e514a"))
	_label(pos + Vector3(0, 10, 0), "El templo en la colina")

func _farms() -> void:
	for i in range(3):
		var p := Vector3(10 + i * 7, 0, 4)
		_box(p + Vector3(0, .1, 0), Vector3(5, .3, 7), Color("655840"), true)
		for row in range(4):
			for col in range(3):
				var h: float = 1.8 if i == 0 else .5
				_box(p + Vector3(-1.5 + col * 1.2, .3 + h / 2, -2.5 + row * 1.4), Vector3(.35, h, .35), Color("80b365") if i == 0 else Color("dab462"))
		_marker("switch" + str(i), p + Vector3(0, 0, 5), ["Caña · agua [E]", "Hierro · palanca [E]", "Cultivos · semillas [E]"][i])
	for row in range(5):
		_box(Vector3(10, 1 + row * 1.1, .5), Vector3(5.6, .18, .2), Color("d7e4e7"))
		_box(Vector3(10, .6 + row * 1.1, .6), Vector3(4.8, .75, .18), Color("6c9d62"))
	for x in [7.2, 12.8]:
		_box(Vector3(x, 3, .5), Vector3(.2, 6, .2), Color("d7e4e7"))
	_box(Vector3(17, 5, -4), Vector3(6, 1, 6), Color("848b92"))
	_box(Vector3(17, 2.5, -4), Vector3(.6, 5, .6), Color("696c73"), true)
	_label(Vector3(17, 7, -4), "Granja de hierro")
	_box(Vector3(27, 9, -13), Vector3(8, 1, 8), Color("464b56"))
	_box(Vector3(27, 4, -13), Vector3(2, 8, 2), Color("686b73"), true)
	_label(Vector3(27, 11, -13), "Granja de mobs")
	_box(Vector3(4, -.35, -10), Vector3(12, .5, 7), Color("363840"), true)
	_box(Vector3(-2.2, 2, -10), Vector3(.5, 4, 7), Color("e3e0d6"), true)
	_box(Vector3(10.2, 2, -10), Vector3(.5, 4, 7), Color("e3e0d6"), true)
	for x in [-1, 2, 5, 8]:
		_box(Vector3(x, 2, -13), Vector3(2.5, 4, .5), Color("e3e0d6"), true)
		_box(Vector3(x, .8, -12.6), Vector3(1.4, 1, .5), Color("a46b43"), true)
		_avatar(Vector3(x, .6, -11), Color("967458"), Color("796048"))
	_box(Vector3(4, 4.5, -10), Vector3(13, .5, 8), Color("e3e0d6"))
	_marker("villager", Vector3(4, 0, -6), "Salón de aldeanos [E]")

func _cave() -> void:
	for x in range(-24, -5, 3):
		_box(Vector3(x, 3, -22), Vector3(3, 6 + (x % 3), 5), Color("777f86"), true)
	_box(Vector3(-15, 3, -19), Vector3(2.5, 6, .25), Color("65a4bf"))
	_box(Vector3(-15, .05, -15), Vector3(8, .2, 5), Color("65a4bf"))
	for x in [-22, -9]:
		_box(Vector3(x, 2.5, -12), Vector3(2, 5, 14), Color("676975"), true)
	_box(Vector3(-15.5, 5, -12), Vector3(15, .7, 14), Color("737680"))
	_marker("portal", Vector3(-15, 0, -18), "Portal entre la cascada [E]")
	for i in range(3):
		_spawn_enemy(Vector3(-19 + i * 3, 0, -10 - i * 2), "cave")

func _end_island() -> void:
	_box(Vector3(75, -.8, 0), Vector3(40, 1.5, 40), Color("3a304a"))
	_box(Vector3(75, -.2, 0), Vector3(32, 1, 32), Color("d6cd98"), true)
	_box(Vector3(50, -.2, 0), Vector3(8, 1, 9), Color("d6cd98"), true)
	_marker("bridge", Vector3(50, 0, 0), "Esta vez, puente con barandas [E]")
	for x in [64, 86]:
		for z in [-11, 11]:
			_box(Vector3(x, 4, z), Vector3(2, 8, 2), Color("3d354d"), true)
	boss = _avatar(Vector3(76, 0, -6), Color("302b43"), Color("302b43"))
	boss.scale = Vector3.ONE * 1.7
	for x in [-.13, .13]:
		var eye := _box(Vector3(x, 1.74, -.28), Vector3(.12, .08, .03), Color("eefcff"), false, boss)
		var glow := StandardMaterial3D.new()
		glow.albedo_color = Color("eefcff")
		glow.emission_enabled = true
		glow.emission = Color("bddfff")
		eye.material_override = glow
	danger_ring = MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 3.8
	torus.outer_radius = 4.0
	torus.rings = 24
	torus.ring_segments = 8
	danger_ring.mesh = torus
	danger_ring.material_override = _mat("warning_ring", Color("eaa085"))
	danger_ring.position = boss.position + Vector3(0, .1, 0)
	danger_ring.visible = false
	add_child(danger_ring)
	_label(Vector3(76, 5, -6), "EL OLVIDADO")
	cage = Node3D.new()
	add_child(cage)
	cage.position = Vector3(75, 0, -10)
	for x in [-1, 1]:
		for z in [-1, 1]:
			_box(Vector3(x, 1.6, z), Vector3(.18, 3.2, .18), Color("af8aca"), false, cage)
	_avatar(Vector3(75, 0, -10), Color("343940"), Color("46352c"))
	_marker("guillermo", Vector3(75, 0, -9), "Guillermo [E]")
	for i in range(4):
		var p := Vector3(69 if i % 2 == 0 else 81, 0, -3 if i < 2 else 6)
		_box(p + Vector3(0, .7, 0), Vector3(1.5, 1.4, 1.5), Color("8a779a"), true)
		_box(p + Vector3(0, 1.6, 0), Vector3(.7, .35, .7), Color("dfb873"))
		_marker("memory" + str(i), p, ["Diploma", "Gyoza", "Bandana", "Galleta"][i] + " [E]")

func _spawn_enemy(pos: Vector3, area: String) -> void:
	var e := _avatar(pos, Color("4d445d"), Color("373245"))
	enemies.append({"node": e, "hp": 2, "timer": 2.0, "area": area})

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
	sword.rotation.z = sin(attack_timer * 12) * 1.2
	sword.rotation.y = player_art.rotation.y
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
	if direction.length_squared() > .01:
		player_art.rotation.y = atan2(-direction.x, -direction.z)
		player_art.position.y = sin(time * 13) * .05
	else:
		player_art.position.y = 0
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
		cat.position = cat.position.move_toward(Vector3(4, 0, -6), delta * 2.5)
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
	_update_atmosphere()
	_emit_goal()

func _update_atmosphere() -> void:
	if not world_environment:return
	if quest_index>=7:
		world_environment.background_color=Color("302b46")
		world_environment.ambient_light_color=Color("b1a3cf")
		world_environment.ambient_light_energy=.65
		daylight.light_color=Color("c9bce5")
		daylight.light_energy=.75
	else:
		world_environment.background_color=Color("b5cfde")
		world_environment.ambient_light_color=Color("ffe4d0")
		world_environment.ambient_light_energy=.7
		daylight.light_color=Color("ffdfbc")
		daylight.light_energy=1.2

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
	respawn = Vector3(50, 1, 2) if quest_index >= 7 else Vector3(-15, 1, -5) if quest_index >= 5 else Vector3(0, 1, 8)
	_update_atmosphere()
	_emit_goal()
