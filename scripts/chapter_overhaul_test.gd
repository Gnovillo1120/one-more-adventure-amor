extends SceneTree
const SLOT := "user://qa_chapter_overhaul.json"
var game: Node
var checks:=0
var failures: Array[String]=[]
var saved: Dictionary={}

func _initialize() -> void:call_deferred("run")

func verify(value: bool, message: String) -> void:
	checks+=1
	if not value:failures.append(message);push_error(message)

func dialogue() -> void:
	var count:=0
	while game._dialogue_open() and count<100:
		count+=1;game.revealed=100000
		if game.lines[game.line_index].has("choices"):game._choose(2)
		else:game._advance_dialogue()
	verify(count<100,"dialogue terminates")

func walk(target: Vector2) -> void:
	var nav: RefCounted=load("res://scripts/memory_navigation.gd").new();nav.scan(game.memory)
	var path: Array=nav.path_to(target)
	verify(not path.is_empty(),"reachable "+str(target))
	for p in path:game.memory.move_by(p-game.memory.player_position)
	verify(game.memory.player_position.distance_to(target)<.1,"actual movement reaches target")

func at(target: Dictionary) -> void:
	walk(Vector2(target.position[0],target.position[1]));game.memory.interact();dialogue()

func run() -> void:
	if not OS.get_cmdline_user_args().has("--self-test"):quit(2);return
	for path in ["user://adventure_save.json","user://adventure_save.json.bak","user://settings.cfg"]:
		saved[path]=FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else null
	game=load("res://scenes/main.tscn").instantiate();game.save_path=SLOT;game.settings_path="user://qa_chapter_settings.cfg";root.add_child(game)
	await process_frame
	game._start_fresh()
	# All optional conversations on all revised scenes use real walk/interaction callbacks.
	for chapter in range(2):
		for index in range(game.story.chapters[chapter].scenes.size()):
			game.chapter_index=chapter;game.scene_index=index;game.start_scene()
			for target in game.memory.scene_config.get("optional",[]):
				if target.kind in ["trivia","drama","guillermo_quiz"]:continue
				at(target);verify(game.memory.optional_seen.has(target.id),"optional conversation tracked: "+target.id)
	# Optional quizzes: perfect/good/zero scores; exit midway; answered-save resume.
	for desired in [6,4,0]:
		game.chapter_index=0;game.scene_index=1;game.chapter_state.erase("caucus");game.start_scene()
		var trivia: Dictionary=game.memory.scene_config.optional.filter(func(t: Dictionary):return t.id=="trivia")[0]
		at(trivia);verify(game.minigame_kind=="trivia","prominent world target opens quiz")
		game._toggle_pause();verify(game.is_paused and not game.suspended_modal.visible,"activity suspends for pause")
		game._settings(game._return_pause)
		var back: Button=game.modal.get_children()[-1];back.pressed.emit()
		game._toggle_pause();verify(game.modal.visible and game.minigame_kind=="trivia","settings and pause preserve quiz")
		for i in range(6):
			var answer:=int(game.story.trivia[i].answer)
			if i>=desired:answer=(answer+1)%3
			if i%2==0:game._activity_key(KEY_1+answer)
			else:game.activity_buttons[answer].pressed.emit()
			verify(game.activity_answered,"quiz immediate feedback")
			game._activity_next()
		dialogue();verify(int(game.chapter_state.caucus.trivia_score)==desired,"score reaction tier "+str(desired))
		verify(not game.scene_completed,"optional quiz never skips mandatory story")
	game.chapter_state.erase("caucus");game.start_scene();game._open_activity("trivia");game._activity_answer(1)
	game.test_mode=false;game.save_game();game._leave_activity();game.show_menu();game.chapter_state={};game.load_game()
	game._open_activity("trivia");verify(game.activity_answered and game.activity_score==1,"saved quiz feedback and score resume")
	game._leave_activity();verify(game.memory.active,"optional quiz can be left without blocking")
	# Legacy v1 memory save without added keys: retain scene index and repair blocked old position.
	var legacy: Dictionary=game._save_payload();legacy.erase("chapter_state");legacy.erase("scene_id");legacy.chapter=1;legacy.scene=2;legacy.completed=true;legacy.position=[1145,410]
	var file:=FileAccess.open(SLOT,FileAccess.WRITE);file.store_string(JSON.stringify(legacy));file.close()
	game.load_game();verify(game.scene_index==2 and game.scene_completed,"legacy scene checkpoint compatible")
	verify(game.memory.can_stand(game.memory.player_position),"legacy blocked position recovered")
	walk(game.memory.exit_position);game.memory.interact();verify(game.chapter_index==2,"Ikura legacy exit naturally advances")
	# Revised restaurant mandatory progression and both input methods.
	game.chapter_index=1;game.scene_index=2;game.chapter_state.erase("date");game.start_scene()
	for i in range(3):at(game.memory.mandatory_target())
	verify(game.minigame_kind=="order","host, seat, date then ordering")
	game.challenge.act("start")
	for i in range(3):game.challenge.act("dish",[i,"yakitori"])
	game.challenge.act("submit");verify(not game.challenge.session.state.passed,"wrong full order is recoverable")
	game.challenge.act("retry");game.challenge.buttons[0].pressed.emit()
	verify(game.challenge.session.state.order[0]=="gyozas","mouse button orders gyozas")
	game.save_game();game.show_menu();game.chapter_state={};game.load_game()
	verify(game.challenge.session.state.order[0]=="gyozas","partial restaurant order resumes")
	game.challenge.category=1;game.challenge.redraw();game.challenge.key(KEY_2);game.challenge.key(KEY_3);game.challenge.key(KEY_ENTER);game.challenge.act("continue")
	verify(game.minigame_kind=="guillermo","order unlocks new quiz")
	game.challenge.act("start")
	for entry in game.challenge.session.data.questions:
		if game.challenge.session.state.phase=="hard_mode":game.challenge.act("hard_mode")
		game.challenge.act("answer",int(entry.answer));game.challenge.act("next")
	game.challenge.act("continue");dialogue()
	verify(game.scene_completed,"restaurant story completes")
	var nav: RefCounted=load("res://scripts/memory_navigation.gd").new();nav.scan(game.memory)
	verify(nav.path_to(Vector2(915,445)).is_empty(),"regression detector rejects rebuilt table footprint")
	for target in game.memory.scene_config.optional:
		if target.kind=="drama":
			at(target)
			for entry in game.story.drama:game._activity_answer(int(entry.answer));game._activity_next()
			dialogue();verify(game.chapter_state.date.drama_score==3,"anonymous school story game completes")
	walk(game.memory.exit_position);game.memory.interact();verify(game.chapter_index==2,"revised chapter2 ends using walking and E")
	game.unlocked=5;game.show_menu();game._chapter_menu()
	var panel: Node=game.ui.get_children()[-1]
	var chapter_buttons: Array=[]
	for child in panel.get_children():
		if child is Button:chapter_buttons.append(child)
	chapter_buttons[1].pressed.emit();verify(game.chapter_index==1 and game.memory.active,"chapter select returns to gameplay")
	game._toggle_pause();game._toggle_pause();verify(game.memory.active,"pause returns to gameplay")
	verify(not game.audio_director.track_available,"unavailable orchestral music honestly silent")
	game.test_mode=true
	for path in saved:verify((FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else null)==saved[path],"real save unchanged")
	for path in [SLOT,SLOT+".tmp",SLOT+".bak","user://qa_chapter_settings.cfg"]:DirAccess.remove_absolute(path)
	game.effects.stop();game.effects.stream=null
	await create_timer(.3).timeout
	game.queue_free();await process_frame;await process_frame
	print("CHAPTER_OVERHAUL_QA: ",checks," checks; ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
