extends SceneTree

var world: Node3D
var failures: int = 0
var checked: int = 0
var floors: Dictionary = {}

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	await audit_memories()
	world = load("res://scripts/voxel_world.gd").new()
	root.add_child(world)
	world.set_active(false)
	await physics_frame
	await physics_frame
	world._box(Vector3(59, -.1, 0), Vector3(12, .8, 4), Color.WHITE, true)
	for z in [-2.2, 2.2]:
		world._box(Vector3(59, .8, z), Vector3(12, 1.4, .4), Color.WHITE, true)
	await physics_frame
	var space: PhysicsDirectSpaceState3D = world.get_world_3d().direct_space_state
	var capsule := CapsuleShape3D.new()
	capsule.radius = .38
	capsule.height = 1.8
	for x in range(-34, 93):
		for z in range(-27, 28):
			var ray := PhysicsRayQueryParameters3D.create(Vector3(x, .8, z), Vector3(x, -2, z))
			ray.exclude = [world.player.get_rid()]
			var ground := space.intersect_ray(ray)
			if ground.is_empty():
				continue
			var floor_y: float = ground.position.y
			var query := PhysicsShapeQueryParameters3D.new()
			query.shape = capsule
			query.transform.origin = Vector3(x, floor_y + .95, z)
			query.exclude = [world.player.get_rid()]
			if space.intersect_shape(query, 1).is_empty():
				floors[Vector2i(x, z)] = floor_y
	var mainland := flood(Vector2i(0, 8))
	for key in ["fish", "cat", "villager", "switch0", "switch1", "switch2", "portal"]:
		verify(key, world.targets[key], mainland)
	verify("house doorway", Vector3(-12, 0, 6), mainland, 1.5)
	verify("house interior", Vector3(-12, 0, 3), mainland, 1.5)
	var end := flood(Vector2i(50, 2))
	for key in ["bridge", "memory0", "memory1", "memory2", "memory3", "guillermo"]:
		verify(key, world.targets[key], end)
	verify("boss attack radius", world.boss.position, end)
	print("NAVIGATION_QA: ", checked, " checks; ", failures, " failures; ", mainland.size(), " mainland cells; ", end.size(), " End cells")
	world.queue_free()
	quit(0 if failures == 0 else 1)

func audit_memories() -> void:
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/story.json"))
	var destinations:=0
	for chapter in data.chapters:
		for scene in chapter.scenes:
			var memory: Node2D=load("res://scripts/memory_world.gd").new()
			memory.location=scene.location;memory.scene_id=scene.id;memory.scene_config=scene.get("exploration",{})
			if scene.location=="beach":memory.companion_position=Vector2(715,430)
			if scene.location=="pool":memory.companion_position=Vector2(850,395)
			root.add_child(memory);memory.active=false
			var nav: RefCounted=load("res://scripts/memory_navigation.gd").new();nav.scan(memory)
			var targets: Array=memory.scene_config.get("steps",[]).duplicate()
			if targets.is_empty():targets.append(memory.mandatory_target())
			targets.append_array(memory.scene_config.get("optional",[]))
			targets.append({"id":"exit","position":[memory.exit_position.x,memory.exit_position.y]})
			for target in targets:
				destinations+=1;checked+=1
				var pos:=Vector2(target.position[0],target.position[1])
				if nav.path_to(pos).is_empty():
					failures+=1;push_error("Unreachable memory target: %s/%s" % [scene.id,target.id])
				checked+=1
				if not memory.has_target_visual(target.id):
					failures+=1;push_error("Missing visual: %s/%s" % [scene.id,target.id])
				checked+=1
				if memory.target_visuals[target.id].position.distance_to(pos)>.01:
					failures+=1;push_error("Misaligned visual: %s/%s" % [scene.id,target.id])
			memory.queue_free();await process_frame
	print("MEMORY_NAVIGATION_QA: ",destinations," targets across 17 scenes; ",failures," failures")

func flood(start: Vector2i) -> Dictionary:
	var seen: Dictionary = {}
	var queue: Array[Vector2i] = [start]
	if not floors.has(start):
		return seen
	seen[start] = true
	var cursor := 0
	while cursor < queue.size():
		var at := queue[cursor]
		cursor += 1
		for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = at + offset
			if floors.has(next) and not seen.has(next) and absf(floors[next] - floors[at]) < .08:
				seen[next] = true
				queue.append(next)
	return seen

func verify(label: String, target: Vector3, reachable: Dictionary, radius: float = 2.7) -> void:
	checked += 1
	for cell in reachable:
		if Vector2(cell.x, cell.y).distance_to(Vector2(target.x, target.z)) < radius:
			print("PASS ", label)
			return
	failures += 1
	printerr("UNREACHABLE ", label)
