extends Node
var game: Node
var directory := ""
var baseline := false
var proof: Dictionary = {}
func image_file(name: String) -> void:
	await get_tree().process_frame;await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var error: int=game.get_viewport().get_texture().get_image().save_png(directory+"/"+name+".png")
	if error!=OK:push_error("Capture failed: "+name);get_tree().quit(1)
func scene(c: int, s: int) -> void:game.chapter_index=c;game.scene_index=s;game.start_scene()
func key(code: int, pressed: bool) -> void:
	var e:=InputEventKey.new();e.physical_keycode=code;e.keycode=code;e.pressed=pressed;Input.parse_input_event(e);Input.flush_buffered_events()
func run() -> void:
	if not OS.get_cmdline_user_args().has("--self-test"):get_tree().quit(2);return
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):directory=arg.trim_prefix("--out=")
		if arg.begins_with("--baseline="):
			baseline=true
			if not ProjectSettings.load_resource_pack(arg.trim_prefix("--baseline="),true):get_tree().quit(1);return
	if directory=="":get_tree().quit(2);return
	DirAccess.make_dir_recursive_absolute(directory)
	await get_tree().process_frame
	game.test_mode=true;game.director.state.seen=["yoda_keychain","a_necklace","first_photo","mun_diploma","oatmeal_recipe"]
	game.director.show_room();await get_tree().create_timer(.15).timeout;await image_file("01_memory_room")
	scene(0,2);await get_tree().create_timer(.2).timeout;await image_file("02_lobby_after_room")
	scene(0,0);game.memory.player_position=Vector2(650,395);await get_tree().create_timer(.1).timeout;await image_file("03_document_prompt")
	scene(0,2);game.memory.player_position=Vector2(1020,570);await get_tree().create_timer(.1).timeout
	key(KEY_E,true);await get_tree().process_frame;key(KEY_E,false)
	var last:=0.0
	for time in [.12,.45,.9,1.32,1.8,2.3]:
		await get_tree().create_timer(time-last).timeout;last=time
		await image_file("photo_%02d" % int(time*100))
		if not baseline:proof["pose_%d" % int(time*100)]={"frame":game.memory.living.photo_action.pose_frame,"busy":game.memory.living.busy,"unlocked":game.memory.living.state.photo}
	proof.native_photo_unlocked=game.memory.living.state.photo
	game._store_memory_state();game._toggle_pause();game.director.scrapbook();await get_tree().create_timer(.1).timeout;await image_file("04_scrapbook")
	if not baseline:game.director.book_visible=false;game._album(game.director.scrapbook);await get_tree().create_timer(.1).timeout;await image_file("05_conference_album")
	for index in [3,7]:
		game.chapter_state.erase("date")
		scene(1,2);game._open_challenge("guillermo");game.challenge.act("start")
		for i in range(index):
			game.challenge.act("answer",int(game.challenge.session.data.questions[i].answer));game.challenge.act("next")
		if game.challenge.session.state.phase=="hard_mode":await image_file("06_hard_mode");game.challenge.act("hard_mode")
		await get_tree().create_timer(.4).timeout;await image_file("quiz_%d" % (index+1));game.challenge.act("answer",2);await get_tree().create_timer(.4).timeout;await image_file("quiz_%d_C_feedback" % (index+1))
	scene(5,1);var card: Dictionary=game.memory.mandatory_target();game.memory.player_position=Vector2(card.position[0],card.position[1])+Vector2(-30,15);await get_tree().create_timer(.1).timeout;await image_file("07_beach_card")
	DisplayServer.window_set_size(Vector2i(960,540));await get_tree().create_timer(.2).timeout;await image_file("08_beach_card_960")
	DisplayServer.window_set_size(Vector2i(1280,720));key(KEY_E,true);await get_tree().process_frame;key(KEY_E,false);await get_tree().create_timer(.1).timeout;await image_file("09_letter_dialogue")
	proof.card_interaction=game._dialogue_open();proof.renderer=RenderingServer.get_video_adapter_name();proof.complete=true
	var file:=FileAccess.open(directory+"/proof.json",FileAccess.WRITE);file.store_string(JSON.stringify(proof,"\t"));file.close()
	print("PLAYTEST_NATIVE_CAPTURE_OK ",proof);get_tree().quit()
