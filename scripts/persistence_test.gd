extends SceneTree
const SLOT := "user://qa_production_persistence.json"
const CONFIG := "user://qa_production_settings.cfg"
var game: Node
var checks := 0
var failures: Array[String] = []
var originals: Dictionary = {}
var widest_height := 0.0

func _initialize() -> void: call_deferred("_run")

func verify(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures.append(label)
		push_error("PERSISTENCE_QA: " + label)

func key(code: int, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func check_text(text: String, label: String, size: int = 24, width: float = 910, height: float = 112) -> void:
	var measured: Vector2 = ThemeDB.fallback_font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, width, size)
	widest_height = maxf(widest_height, measured.y)
	verify(measured.y <= height, "text fits: %s (%.0f/%.0f px)" % [label, measured.y, height])

func _run() -> void:
	if not OS.get_cmdline_user_args().has("--self-test"):
		push_error("Pass -- --self-test. Isolated test refuses unguarded startup.")
		quit(2)
		return
	for path in ["user://adventure_save.json", "user://adventure_save.json.bak", "user://settings.cfg"]:
		originals[path] = FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else null
	for path in [SLOT, SLOT + ".bak", SLOT + ".tmp", CONFIG]: DirAccess.remove_absolute(path)
	game = load("res://scenes/main.tscn").instantiate()
	game.save_path = SLOT
	game.settings_path = CONFIG
	root.add_child(game)
	await process_frame
	verify(game.test_mode and game.save_path == SLOT, "startup save isolation")
	game.test_mode = false
	game._start_fresh()
	verify(FileAccess.file_exists(SLOT), "production new-game save created")
	game.chapter_index = 2
	game.scene_index = 1
	game.unlocked = 3
	game.keepsakes = [game.story.chapters[0].keepsake, game.story.chapters[1].keepsake]
	game.start_scene()
	game.memory.player_position = Vector2(301, 420)
	game.scene_completed = true
	game.memory.completed = true
	game.total_play_seconds = 123.5
	game.save_game()
	game.show_menu()
	game.load_game()
	verify(game.chapter_index == 2 and game.scene_index == 1 and game.unlocked == 3, "actual load chapter/scene/unlocks")
	verify(game.scene_completed and game.memory.completed, "actual load completed scene")
	verify(game.memory.player_position == Vector2(301, 420), "actual load memory position")
	verify(game.keepsakes.size() == 2 and game.total_play_seconds >= 123.5, "actual load keepsakes/play time")
	game.memory.player_position = Vector2(321, 430)
	game.save_game()
	game.memory.player_position = Vector2(341, 440)
	game.save_game()
	verify(FileAccess.file_exists(SLOT + ".bak"), "production backup exists")
	var broken := FileAccess.open(SLOT, FileAccess.WRITE)
	broken.store_string("{ deliberately corrupt QA slot")
	broken.close()
	game.show_menu()
	game.load_game()
	verify(game.memory.player_position == Vector2(321, 430), "corrupt primary falls back to actual backup")
	verify(JSON.parse_string(FileAccess.get_file_as_string(SLOT)) is Dictionary, "fallback load repairs primary through actual save")
	game.chapter_index = 4
	game.scene_index = 0
	game.keepsakes = []
	for i in range(4): game.keepsakes.append(game.story.chapters[i].keepsake)
	game._start_voxel()
	game.voxel.quest_index = 3
	game.voxel.switches = [true, false, false]
	game.voxel.player.position = Vector3(11, 1, 7)
	game.voxel.enemies[0].hp = 1
	game.voxel.health = 76
	game.save_game()
	game.show_menu()
	game.load_game()
	verify(game.stage == "voxel" and game.voxel.quest_index == 3, "actual load resumes voxel quest")
	verify(game.voxel.switches == [true, false, false], "actual load partial farm puzzle")
	verify(game.voxel.enemies[0].hp == 1 and game.voxel.enemies[1].hp == 2, "actual load living enemy health")
	verify(game.voxel.player.position == Vector3(11, 1, 7) and game.voxel.health == 76, "actual load voxel position/health")
	game.voxel.player.position = Vector3(0, 1, 8)
	await physics_frame
	await physics_frame
	key(KEY_D, true)
	await physics_frame
	await physics_frame
	key(KEY_D, false)
	verify(game.voxel.player.position.x > .05, "injected D key moves voxel Anami")
	var prior_yaw: float = game.voxel.yaw
	var motion := InputEventMouseMotion.new()
	motion.relative = Vector2(100, 20)
	game.voxel._unhandled_input(motion)
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		verify(game.voxel.yaw < prior_yaw, "mouse motion rotates third-person camera")
	else:
		print("PERSISTENCE_QA: mouse capture unavailable headless; mouse rotation requires GUI check")
	game.voxel._physics_process(.016)
	verify(is_equal_approx(game.voxel.pivot.rotation.y, game.voxel.yaw), "camera pivot receives yaw")
	game.volume = .37
	game.text_speed = 77
	game.low_graphics = false
	game.fullscreen = false
	game._save_settings()
	verify(FileAccess.file_exists(CONFIG), "actual settings file written")
	game.volume = .8
	game.text_speed = 30
	game.low_graphics = true
	game._load_settings()
	verify(is_equal_approx(game.volume, .37) and game.text_speed == 77 and not game.low_graphics, "actual ConfigFile settings roundtrip")
	game.chapter_index = 0
	game.scene_index = 0
	game.start_scene()
	game.memory.player_position = Vector2(180, 520)
	key(KEY_D, true)
	game.memory._process(.1)
	key(KEY_D, false)
	verify(game.memory.player_position.x > 195, "injected D key moves Anami")
	game.memory.player_position = Vector2(530, 300)
	key(KEY_A, true)
	game.memory._process(.1)
	key(KEY_A, false)
	verify(game.memory.player_position.x == 530, "held key blocked by desk collision")
	game.memory.player_position = game.memory.companion_position
	key(KEY_E, true)
	await process_frame
	key(KEY_E, false)
	verify(game._dialogue_open(), "injected E opens hotspot dialogue")
	var line_count := 0
	for chapter in game.story.chapters:
		for scene in chapter.scenes:
			for entry in scene.lines + scene.after:
				line_count += 1
				check_text(entry.text, scene.id)
				if entry.has("choices"):
					for choice in entry.choices: check_text(choice, scene.id + " choice", 17, 850, 31)
	for paragraph in game.story.personal_letter.paragraphs: check_text(paragraph, "personal letter")
	verify(line_count == 187, "all authored lines measured")
	game.test_mode = true
	for path in originals:
		var current = FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else null
		verify(current == originals[path], "real save untouched: " + path)
	for path in [SLOT, SLOT + ".bak", SLOT + ".tmp", CONFIG]: DirAccess.remove_absolute(path)
	game.music.stop()
	game.effects.stop()
	game.music.stream = null
	game.effects.stream = null
	await create_timer(.3).timeout
	game.queue_free()
	await process_frame
	await process_frame
	print("PERSISTENCE_QA: %d checks; %d failures; %d story lines; max dialogue height %.0f px" % [checks, failures.size(), line_count, widest_height])
	for failure in failures: print("FAIL: " + failure)
	quit(0 if failures.is_empty() else 1)
