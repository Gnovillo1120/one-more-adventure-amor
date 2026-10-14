extends SceneTree
## Runtime regression runner; --self-test isolates real save/settings writes.
var game: Node
var checks := 0
var failures: Array[String] = []
var visited: Array[String] = []
var dialogue_count := 0
const QA_SLOT := "user://qa_slot_story.json"
var preserved: Dictionary = {}

func _initialize() -> void:
	call_deferred("_run")

func verify(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures.append(label)
		push_error("QA: " + label)

func drain_dialogue(choice_index: int = 0) -> void:
	var guard := 0
	while game._dialogue_open() and guard < 500:
		guard += 1
		dialogue_count += 1
		game.revealed = 100000
		if game.lines[game.line_index].has("choices"):
			game._choose(choice_index)
		else:
			game._advance_dialogue()
	verify(guard < 500, "dialogue terminates")

func buttons(parent: Node) -> Array[Button]:
	var result: Array[Button] = []
	for child in parent.get_children():
		if child is Button: result.append(child)
	return result

func persistence_roundtrip() -> void:
	var original: Dictionary = game._save_payload()
	var file := FileAccess.open(QA_SLOT, FileAccess.WRITE)
	verify(file != null, "isolated QA save writable")
	if file == null: return
	file.store_string(JSON.stringify(original))
	file.close()
	var decoded = JSON.parse_string(FileAccess.get_file_as_string(QA_SLOT))
	verify(decoded is Dictionary, "save payload parses")
	if not decoded is Dictionary: return
	verify(decoded.chapter == original.chapter and decoded.scene == original.scene, "chapter checkpoint roundtrip")
	verify(decoded.keepsakes == original.keepsakes, "keepsake checkpoint roundtrip")
	if original.has("voxel"):
		var phase := int(original.voxel.quest)
		game._start_voxel(decoded.voxel)
		verify(game.voxel.quest_index == phase, "voxel phase %d restored" % phase)
		verify(game.voxel.switches == decoded.voxel.switches, "switch checkpoint restored")
		verify(game.voxel.memories == decoded.voxel.memories, "pedestal checkpoint restored")
		verify(game.voxel.boss_health == decoded.voxel.boss_health, "boss health restored")
		verify(game.voxel.get_save_data().enemy_hp == decoded.voxel.enemy_hp, "enemy health restored")
		var v: Node3D = game.voxel
		v.player.position.y = -8
		v._physics_process(.016)
		verify(v.player.position.distance_to(v.respawn) < .05, "phase %d fall checkpoint safe" % phase)
		v.player.position = Vector3(decoded.voxel.position[0], decoded.voxel.position[1], decoded.voxel.position[2])
		v.player.velocity = Vector3.ZERO
	else:
		game.start_scene(decoded.completed, decoded.get("position", []))
		verify(game.scene_completed == original.completed, "memory completion restored")

func voxel_interact(target: String, expected_phase: int) -> void:
	game.voxel.player.position = game.voxel.targets[target] + Vector3(0, .1, 0)
	game.voxel.interact()
	drain_dialogue()
	verify(game.voxel.quest_index == expected_phase, "interaction %s advances to %d" % [target, expected_phase])
	persistence_roundtrip()

func combat(area: String, next_phase: int) -> void:
	var v: Node3D = game.voxel
	for enemy in v.enemies:
		if enemy.area != area or enemy.hp <= 0: continue
		v.player.position = enemy.node.position + Vector3(0, .1, .8)
		for hit in range(2):
			v.attack_timer = 0
			v.attack()
			await physics_frame
		verify(enemy.hp == 0, "%s enemy defeated by actual attack" % area)
	v._physics_process(.016)
	drain_dialogue()
	verify(v.quest_index == next_phase, "%s combat phase completed" % area)
	persistence_roundtrip()

func run_voxel() -> void:
	verify(game.keepsakes.size() == 4, "all memory keepsakes enter rescue")
	persistence_roundtrip()
	voxel_interact("fish", 1)
	voxel_interact("cat", 2)
	voxel_interact("villager", 3)
	# Out-of-order puzzle input must be recoverable and preserve its state.
	game.voxel.player.position = game.voxel.targets.switch2
	game.voxel.interact()
	drain_dialogue()
	verify(game.voxel.switches == [false, false, false], "farm order rejects premature seeds")
	voxel_interact("switch0", 3)
	voxel_interact("switch1", 3)
	voxel_interact("switch2", 4)
	voxel_interact("villager", 5)
	# Lethal combat restores a generous checkpoint rather than losing progress.
	game.voxel.health = 1
	game.voxel.hurt_timer = 0
	game.voxel._damage(8)
	drain_dialogue()
	verify(game.voxel.health == 100 and game.voxel.quest_index == 5, "lethal hit preserves quest and restores health")
	await combat("cave", 6)
	voxel_interact("portal", 7)
	voxel_interact("bridge", 8)
	await combat("boss", 9)
	for i in range(4): voxel_interact("memory" + str(i), 10 if i == 3 else 9)
	var v: Node3D = game.voxel
	v.player.position = v.boss.position + Vector3(0, .1, 1)
	for i in range(4):
		v.attack_timer = 0
		v.attack()
	drain_dialogue()
	verify(v.quest_index == 11 and not v.cage.visible and not v.boss.visible, "final sword attacks free crystal prisoner")
	persistence_roundtrip()
	game.voxel.player.position = game.voxel.targets.guillermo
	game.voxel.interact()
	verify(game.stage == "memory" and game.scene_index == 1 and game.chapter_index == 4, "rescue signal reaches authored reunion")

func minigame() -> void:
	if game.minigame_kind == "": return
	var kind: String = game.minigame_kind
	if is_instance_valid(game.challenge):
		var helper=load("res://scripts/memory_minigames_test.gd").new()
		while is_instance_valid(game.challenge):
			var session: RefCounted=game.challenge.session
			if session.state.phase=="intro":session.act("start")
			if session.kind=="order":
				for i in range(3):session.act("dish",[i,session.data.correct_order[i]])
				session.act("submit")
			elif session.kind=="cookies":helper.bake(session)
			else:helper.answer_all(session,10)
			game.challenge.act("continue")
		helper.free();drain_dialogue();return
	if kind == "dance":
		game._dance_key(KEY_X)
		verify(game.minigame_step == 0, "wrong dance key remains forgiving")
		for key in [KEY_W, KEY_A, KEY_S, KEY_D, KEY_W, KEY_D, KEY_S, KEY_A]: game._dance_key(key)
	elif kind=="food":
		game._activity_answer(3)
		verify(game.minigame_step==0,"wrong restaurant order permits correction")
		for i in range(3):game._activity_answer(i)
	else:
		buttons(game.modal)[1].pressed.emit()
		verify(game.minigame_step == 0, "%s incorrect answer permits retry" % kind)
		for i in range(3): buttons(game.modal)[0].pressed.emit()
	verify(game.minigame_kind == "", "%s minigame completes" % kind)
	drain_dialogue()

func alternate_choices() -> void:
	for chapter in game.story.chapters:
		for scene in chapter.scenes:
			for entry in scene.lines:
				if not entry.has("choices"): continue
				for index in range(entry.choices.size()):
					var completed := [false]
					game._show_dialogue([entry.duplicate(true)], func(): completed[0] = true)
					drain_dialogue(index)
					verify(completed[0], "%s choice %d converges" % [scene.id, index])

func _run() -> void:
	if not OS.get_cmdline_user_args().has("--self-test"):
		push_error("Pass -- --self-test to prevent real save writes.")
		quit(2)
		return
	for path in ["user://adventure_save.json", "user://adventure_save.json.bak", "user://settings.cfg"]:
		preserved[path] = FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else null
	var packed: PackedScene = load("res://scenes/main.tscn")
	game = packed.instantiate()
	game.test_mode = true
	root.add_child(game)
	await process_frame
	verify(game.test_mode, "test mode enabled")
	game._start_fresh()
	game.director.skip_cinematic();game.director.enter_next();game.director.skip_cinematic()
	alternate_choices()
	var guard := 0
	while game.stage != "credits" and guard < 30:
		guard += 1
		if game.stage=="hub":
			game.director.enter_next();game.director.skip_cinematic();continue
		if game.stage == "voxel":
			await run_voxel()
			await process_frame
			continue
		var id: String = game._scene().id
		visited.append("%s/%s" % [game._chapter().id, id])
		var world: Node2D = game.memory
		world.player_position = world.safe_position(Vector2(110, 550))
		world.interact()
		if world.location!="phone" and world.mandatory_target().id!="photos":verify(not game._dialogue_open(), "%s distant interaction rejected" % id)
		else:drain_dialogue()
		var step_guard:=0
		while not game.scene_completed and game.stage=="memory" and step_guard<8:
			step_guard+=1
			if id=="invitation" and game.memory.living.state.outfit_phase=="active":
				for piece in ["dress","bandana","sneakers"]:game.memory.living.perform("living:"+piece)
				drain_dialogue();continue
			var target: Dictionary=game.memory.mandatory_target()
			walk_to(Vector2(target.position[0],target.position[1]))
			game.memory.interact()
			if id=="foot":await create_timer(1.4).timeout
			verify(game._dialogue_open(), "%s hotspot starts dialogue" % id)
			drain_dialogue()
			if game.minigame_kind!="":break
		minigame()
		if game.stage == "credits" or game.stage == "voxel": continue
		verify(game.scene_completed, "%s scene completes" % id)
		persistence_roundtrip()
		walk_to(game.memory.exit_position)
		game.memory.interact()
		await process_frame
	verify(game.stage == "credits", "full natural progression reaches credits")
	verify(visited.size() == 17, "all seventeen consolidated story scenes traversed")
	verify(game.unlocked == 5, "all six chapters unlocked")
	game.show_menu()
	verify(game.stage == "menu", "credits returns to menu")
	for path in preserved:
		var now = FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else null
		verify(now == preserved[path], "real save/settings untouched: " + path)
	DirAccess.remove_absolute(QA_SLOT)
	print("STORY_QA: %d checks; %d failures; %d scenes; %d dialogue steps" % [checks, failures.size(), visited.size(), dialogue_count])
	for failure in failures: print("FAIL: " + failure)
	game.music.stop()
	game.effects.stop()
	game.music.stream = null
	game.effects.stream = null
	await create_timer(.1).timeout
	game.queue_free()
	await process_frame
	await process_frame
	quit(0 if failures.is_empty() else 1)

func walk_to(target: Vector2) -> void:
	var nav: RefCounted=load("res://scripts/memory_navigation.gd").new();nav.scan(game.memory)
	var path: Array=nav.path_to(target)
	verify(not path.is_empty(),"walkable path to "+str(target))
	for waypoint in path:
		game.memory.move_by(waypoint-game.memory.player_position)
	verify(game.memory.player_position.distance_to(target)<.1,"collision-valid walking reaches "+str(target))
