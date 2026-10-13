extends SceneTree
## Real movement, seating composition, phone containment and editable quiz QA.
var checks:=0
var failures:=0
var game: Node
func _initialize() -> void:call_deferred("run")
func verify(ok: bool, label: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func walk(p: Vector2) -> void:
	var nav: RefCounted=load("res://scripts/memory_navigation.gd").new();nav.scan(game.memory)
	var path: Array=nav.path_to(p);verify(not path.is_empty(),"clear route to "+str(p))
	for step in path:
		for axis in range(2):
			var delta: float=step[axis]-game.memory.player_position[axis]
			if absf(delta)<.01:continue
			var code: int=(KEY_D if delta>0 else KEY_A) if axis==0 else (KEY_S if delta>0 else KEY_W)
			var event:=InputEventKey.new();event.physical_keycode=code;event.pressed=true;Input.parse_input_event(event);Input.flush_buffered_events()
			game.memory._process(absf(delta)/205.0)
			event=InputEventKey.new();event.physical_keycode=code;event.pressed=false;Input.parse_input_event(event);Input.flush_buffered_events()
	verify(game.memory.player_position.distance_to(p)<.1,"production walking reaches "+str(p))
func run() -> void:
	if not OS.get_cmdline_user_args().has("--self-test"):quit(2);return
	game=load("res://scenes/main.tscn").instantiate();game.save_path="user://qa_redesign.json";root.add_child(game);await process_frame
	for scene_index in [0,1]:
		game.chapter_index=0;game.scene_index=scene_index;game.start_scene()
		verify(game.memory.layered and game.memory.depth_root.y_sort_enabled,"conference is layered and depth sorted")
		for target in game.memory.scene_config.optional:
			if target.id not in ["chad","brasil","france","kenia"]:continue
			walk(Vector2(target.position[0],target.position[1]))
			verify(game.memory.nearest_target().id==target.id,"normal-radius delegate prompt "+target.id)
	for chapter_scene in [[0,3],[1,2]]:
		game.chapter_index=chapter_scene[0];game.scene_index=chapter_scene[1];game.start_scene()
		walk(Vector2(885,420))
		verify(game.memory.fixtures.has("seat_anami") and game.memory.fixtures.has("couple_table"),"seat and tabletop share room fixtures")
		game.memory.seat_couple(func():pass)
		verify(game.memory.seated and game.memory.actors.anami.seated and game.memory.actors.guillermo.seated,"both characters visibly seated")
		verify(game.memory.actors.anami.position.y<game.memory.fixtures.couple_table.position.y,"table foreground covers lap by depth")
		verify(game.memory.actors.anami.position.distance_to(game.memory.actors.guillermo.position)<80,"couple occupies adjacent chairs")
		game._store_memory_state();game.start_scene();verify(game.memory.seated,"seated pose restores from chapter state")
	game.chapter_index=1;game.scene_index=1;game.start_scene()
	game.memory.show_phone(true)
	for i in range(8):game.memory.apply_line("Anami" if i%2==0 else "Guillermo","Mensaje %d: "%i+"¿Seguimos conversando después de revisar el documento? ".repeat(20))
	for i in range(5):await process_frame
	var phone: Node2D=game.memory
	verify(phone.phone_scroll.clip_contents,"phone clips scrolling contents")
	verify(phone.phone_stack.get_child_count()==8,"conversation history retained")
	verify(phone.phone_scroll.get_v_scroll_bar().max_value>phone.phone_scroll.size.y,"long conversation scrolls")
	for label in phone.phone_labels:
		verify(label.size.x<=phone.phone_scroll.size.x-36,"wrapped bubble fits clipped viewport")
		verify(label.size.y>100,"long text uses dynamic bubble height")
	phone.scroll_phone(KEY_HOME);verify(phone.phone_scroll.scroll_vertical==0,"keyboard Home reaches first message")
	phone.scroll_phone(KEY_END);verify(phone.phone_scroll.scroll_vertical>0,"keyboard End reaches latest message")
	game.chapter_index=1;game.scene_index=2;game.start_scene();game._open_challenge("guillermo");game.challenge.act("start")
	verify(game.challenge.session.data.questions.size()==10,"quiz loads complete editable question bank")
	for entry in game.challenge.session.data.questions:
		if game.challenge.session.state.phase=="hard_mode":game.challenge.act("hard_mode")
		game.challenge.act("answer",int(entry.answer));game.challenge.act("next")
	verify(game.chapter_state.date.challenge_sessions.guillermo.score==10,"data-driven quiz stores score")
	game.queue_free();await process_frame;await process_frame
	print("REDESIGN_PHASE_A_QA: ",checks," checks; ",failures," failures")
	quit(0 if failures==0 else 1)
