extends SceneTree
const SLOT := "user://qa_directors_cut.json"
var game: Node
var checks := 0
var failures: Array[String] = []
func _initialize() -> void:call_deferred("run")
func verify(value: bool, label: String) -> void:
	checks+=1
	if not value:failures.append(label);push_error(label)
func run() -> void:
	if not OS.get_cmdline_user_args().has("--self-test"):quit(2);return
	game=load("res://scenes/main.tscn").instantiate();game.save_path=SLOT;root.add_child(game);await process_frame
	var d: Node=game.director
	verify(d.data.pages.size()==6 and d.data.keepsakes.size()==5,"six chapters, exactly five personal objects")
	verify(d.data.keepsakes.map(func(e):return e.id)==["yoda_keychain","a_necklace","first_photo","mun_diploma","oatmeal_recipe"],"canonical keepsake identities")
	for entry in d.data.keepsakes:
		verify(ResourceLoader.exists(entry.art),"real runtime illustration: "+entry.id)
		verify(not entry.description.to_lower().contains("bandana"),"no bandana symbolism: "+entry.id)
		verify(not entry.description.contains("2023"),"no fabricated gift date: "+entry.id)
		var tex: Texture2D=load(entry.art);verify(tex.get_image().get_format()==Image.FORMAT_RGBA8,"transparent asset: "+entry.id)
	game._start_fresh();verify(game.stage=="opening","new game begins in scrapbook opening")
	d.skip_cinematic();verify(game.stage=="hub" and d.state.intro_seen,"skip reaches same usable room")
	d.skip_cinematic();verify(game.stage=="hub","skip idempotent")
	d.inspect_page(0)
	for child in game.modal.get_children():
		if child is TextureRect:verify(child.size==Vector2(300,170),"large environment texture stays inside photo frame")
		if child is Button and child.position.x==25 and child.position.y<500:verify(child.size.x==335,"chapter text stays inside navigation column")
	var escape:=InputEventKey.new();escape.physical_keycode=KEY_ESCAPE;escape.pressed=true
	verify(d.handle_input(escape) and not is_instance_valid(game.modal),"Escape closes book without nesting pause")
	d.scrapbook();game.show_menu();verify(not d.book_visible,"scene/menu transitions clear stale book input state");d.show_room()
	verify(d.room.legal(Vector2(665,550)),"initial hub position walkable")
	verify(not d.room.legal(Vector2(665,390)),"reading desk blocks movement")
	verify(not d.room.legal(Vector2(10,10)),"room bounds enforced")
	d.room.player_position=Vector2(665,495);verify(d.room.nearest()==-1,"book reachable")
	for i in range(5):
		var anchor: Array=d.data.keepsakes[i].anchor;d.room.player_position=Vector2(anchor[0],anchor[1]);verify(d.room.nearest()==i,"personal display reachable: "+str(i))
	for i in range(5):d.inspect_keepsake(i);verify(d.state.seen.has(d.data.keepsakes[i].id),"optional inspection persists: "+str(i))
	d.inspect_keepsake(0);d.open_box();verify(d.state.seen.has("yoda_box_open"),"childhood box opening persisted")
	d.close_book();verify(not is_instance_valid(game.modal),"book closes cleanly")
	d.note("cookies",{"phase":"result","score":0,"passed":true});d.note("cookies",{"phase":"result","score":100,"passed":true})
	verify(d.state.notes.cookies.first==0 and d.state.notes.cookies.latest==100,"imperfect first batch preserved across replay")
	d.note("cookies",{"phase":"play","score":22});verify(d.state.notes.cookies.latest==100,"unfinished session never recorded as completed")
	game.test_mode=false;game.save_game();var saved: Dictionary=game._read_save();verify(saved.stage=="hub","real durable hub save")
	game.show_menu();game.load_game();verify(game.stage=="hub" and d.state.seen.has("yoda_box_open"),"Continue restores optional objects and hub")
	verify(d.state.notes.cookies.first==0,"actual disk roundtrip keeps original baking score")
	game.test_mode=true
	d.enter_next();d.skip_cinematic();verify(game.stage=="memory" and game._scene().id=="arrival","photograph transition enters real UESS scene")
	game.chapter_index=0;game.scene_index=5;game.scene_completed=true;game._next_scene();verify(game.stage=="hub" and game.chapter_index==1 and d.recovered(0),"chapter completion returns to hub exactly once")
	game.chapter_state={"reconnect":{"step":2}};game.keepsakes=[game.story.chapters[0].keepsake];var originals: Dictionary=game.chapter_state.duplicate(true)
	d.replay(0);verify(d.replaying() and game.chapter_index==0 and game.stage=="memory","completed chapter roundtrip replay begins")
	game.test_mode=false;game.save_game();game.show_menu();game.load_game();game.test_mode=true
	verify(d.replaying() and game.chapter_index==0 and game.stage=="memory","Continue during replay retains return checkpoint")
	game.chapter_state.arrival={"step":1};d.finish_replay();verify(game.chapter_index==1 and game.chapter_state.keys()==originals.keys() and int(game.chapter_state.reconnect.step)==int(originals.reconnect.step) and game.stage=="hub","abort replay restores main checkpoint without losing notes")
	d.replay(0);game.scene_index=5;game._next_scene();verify(game.chapter_index==1 and game.stage=="hub" and not d.replaying(),"whole chapter replay returns at natural exit")
	var legacy: Dictionary={"unlocked":3,"stage":"memory"};d.restore({},legacy);verify(d.recovered(0) and d.recovered(2) and not d.recovered(3),"legacy recovered chapters derived without forcing hub")
	game.chapter_index=2;game.scene_index=0;game.keepsakes=["Bandana roja"];game.start_scene();game.test_mode=false;game.save_game();game.show_menu();game.load_game()
	verify(game.keepsakes==["El comienzo de nosotros"] and game.stage=="memory","old bandana token migrates while Halloween checkpoint remains playable")
	verify(game.memory.outfit=="halloween" and game._scene().id=="invitation","Halloween outfit and getting-ready entry preserved")
	game.test_mode=true;game.chapter_index=0;game.scene_index=0;game._start_fresh();game.test_mode=false;game.save_game();game.show_menu();game.load_game();verify(game.stage=="hub" and not is_instance_valid(d.cinema),"interrupted opening save recovers without cutscene lock")
	game.test_mode=true;game.reduced_motion=true;game._start_fresh();verify(d.room.player_position==Vector2(665,510),"reduced motion uses stable introductory composition")
	d.skip_cinematic();d.state.hub_position=[1,1];d.show_room();verify(d.room.legal(d.room.player_position),"invalid saved room position repaired safely")
	verify(game.story.personal_letter.is_placeholder,"real personal letter never invented")
	d.restore({"hub_position":["bad"],"bookmark":{"unexpected":1},"notes":{"cookies":false},"recovered":[99,"bad",0]},{});verify(d.state.bookmark.is_empty() and d.state.notes.is_empty() and d.state.hub_position==[665,550] and d.state.recovered==[0],"malformed optional book data recovers without losing legacy route")
	for path in [SLOT,SLOT+".bak",SLOT+".tmp"]:DirAccess.remove_absolute(path)
	print("DIRECTORS_CUT_QA: %d checks; %d failures" % [checks,failures.size()]);game.queue_free();await process_frame;await process_frame;quit(0 if failures.is_empty() else 1)
