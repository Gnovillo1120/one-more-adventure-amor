extends SceneTree
const Session=preload("res://scripts/baking_session.gd")
const Driver=preload("res://scripts/baking_test_driver.gd")
var checks:=0
var failures:=0
var game: Node
var recipe: Dictionary
func _initialize() -> void:call_deferred("run")
func verify(ok: bool, message: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error(message)
func fresh() -> RefCounted:
	var s:=Session.new();s.setup("cookies",recipe);return s
func restored(s: RefCounted) -> void:
	var saved: Dictionary=JSON.parse_string(JSON.stringify(s.state));var r:=fresh();r.setup("cookies",recipe,saved)
	saved.station="";verify(r.state==saved,"physical state survives JSON: "+s.state.phase)
func run() -> void:
	if not OS.get_cmdline_user_args().has("--self-test"):quit(2);return
	recipe=JSON.parse_string(FileAccess.get_file_as_string("res://data/oatmeal_cookie_recipe.json"))
	var driver:=Driver.new()
	var perfect:=fresh();driver.bake(perfect)
	verify(perfect.state.phase=="result" and perfect.state.passed and perfect.state.score==100,"physical perfect bake scores 100")
	var under_mixed:=fresh();under_mixed.state=perfect.state.duplicate(true);under_mixed.state.mix_quality=[.25,.25,.25,.25]
	verify(under_mixed.evaluate_cookie()<perfect.state.score,"actual mixing execution contributes to quality")
	var poor:=fresh();driver.bake(poor,false)
	verify(poor.state.passed and poor.state.score<60,"shells, spacing, quantities and time reduce score without failure")
	for phase in ["intro","quiz","gather","measure","dry","cream","eggs","combine","oats","chill","preheat","tray","flatten","oven","cool","taste","result"]:
		var s:=fresh();s.state=perfect.state.duplicate(true);s.state.phase=phase;restored(s)
	var s:=fresh();s.act("start")
	verify(not s.act("pull") and not s.act("mixed"),"out of order actions rejected")
	for i in range(3):s.act("quiz",1)
	s.act("gather");s.act("pour",.4);restored(s)
	verify(s.state.fill==.4 and not s.act("portion",[.2,.2]),"partial pour persisted and tray unavailable")
	s.act("empty");verify(s.state.fill==0,"pour can be corrected without starting over")
	var legacy:=fresh();legacy.setup("cookies",recipe,{"phase":"result","score":42,"passed":true,"pantry":["flour"]})
	verify(legacy.state.score==42 and legacy.state.passed and legacy.state.phase=="result","completed legacy score preserved")
	legacy.setup("cookies",recipe,{"phase":"prepare","index":3,"measures":{"flour":2},"preparation":["whisk_dry","cream","eggs_vanilla"]})
	verify(legacy.state.phase=="combine" and legacy.state.measures.flour==2,"mid-recipe legacy progress adapted")
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.chapter_index=3;game.scene_index=0;game.start_scene();game._open_challenge("cookies")
	var view: Control=game.challenge
	view.act("start");for i in range(3):view.act("quiz",0)
	verify(game.modal==null and game.memory.active,"quiz returns to spatial kitchen")
	game._toggle_pause();game._toggle_pause();verify(game.memory.active,"pause returns to walking kitchen")
	var nav=load("res://scripts/memory_navigation.gd").new();nav.scan(game.memory)
	for target in view.targets():
		var point:=Vector2(target.position[0],target.position[1]);var reachable:=false
		var origin: Vector2=game.memory.player_position
		for cell in nav.parents:
			var approach: Vector2=nav.point(cell)
			game.memory.player_position=approach
			if approach.distance_to(point)<68 and game.memory.clear_interaction_line(point):reachable=true;break
		game.memory.player_position=origin
		verify(reachable,"station reachable: "+target.id)
	game.memory.player_position=Vector2(1160,350);game.memory.interact()
	verify(game.modal==view and view.session.state.station=="pantry","E opens nearby station")
	view.key(KEY_SPACE);verify(view.session.state.pantry.has(view.gather_ids[0]),"keyboard chooses pantry ingredient")
	view.leave_counter();verify(game.modal==null and game.memory.active,"Tab returns without losing actions")
	view.show_station("fridge");view.act("ingredient","eggs");view.leave_counter()
	verify(view.session.state.pantry.has("eggs"),"fridge selection retained")
	var payload: Dictionary=JSON.parse_string(JSON.stringify(game._save_payload()))
	game.chapter_state=payload.chapter_state;game.start_scene(false,payload.position)
	verify(game.challenge.session.state.pantry.has("eggs") and game.memory.active,"baking checkpoint loads into usable kitchen")
	view=game.challenge;view.act("gather");view.show_station("counter")
	var press:=InputEventMouseButton.new();press.button_index=MOUSE_BUTTON_LEFT;press.pressed=true;press.position=Vector2(300,310);view.pointer(press);view._process(.5)
	verify(view.session.state.fill>0,"mouse hold physically pours")
	press.pressed=false;view.pointer(press);verify(not view.pouring,"mouse release stops pouring")
	view.act("empty")
	game._toggle_pause();var fill: float=view.session.state.fill;view._process(4);verify(view.session.state.fill==fill,"pause freezes close-up simulation");game._toggle_pause()
	view.session.state.phase="dry";view.redraw();press.pressed=true;press.position=Vector2(720,355);view.pointer(press)
	var motion:=InputEventMouseMotion.new();motion.position=Vector2(640,440);view.pointer(motion)
	verify(view.session.state.mix>0,"circular mouse motion mixes dough")
	view.session.setup("cookies",recipe)
	driver.bake(game.challenge.session);game.challenge.act("continue")
	while game._dialogue_open():game.revealed=9999;game._advance_dialogue()
	verify(game.scene_completed and game.keepsakes.has(game._chapter().keepsake),"physical bake awards existing cookie keepsake")
	for id in ["award","goodbye","reconnect","pool","date","dance"]:
		game.chapter_index={"award":0,"goodbye":0,"reconnect":1,"pool":2,"date":1,"dance":2}[id]
		game.scene_index={"award":4,"goodbye":5,"reconnect":1,"pool":2,"date":2,"dance":1}[id];game.chapter_state={};game.start_scene()
		var called: Array=[0];game.cinema.play(id,func():called[0]+=1);game.cinema.finish();game.cinema.finish()
		verify(called[0]==1 and not game.cinema.running and game.memory.active,"skip idempotent: "+id)
	game.chapter_index=2;game.scene_index=2;game.chapter_state={"pool":{"cinematic_checkpoint":"pool"}};game.start_scene()
	verify(not game.chapter_state.pool.has("cinematic_checkpoint") and game.chapter_state.pool.cinematics==["pool"],"interrupted romantic staging resumes once")
	verify(game.memory.living.state.affection_frame==3 and not game.cinema.running,"restored kiss has final pose and usable continuation")
	verify(game._save_payload().get("version",1)==1,"outer save format remains compatible")
	print("MILESTONE2_QA: %d checks; %d failures"%[checks,failures])
	game.queue_free();await process_frame;quit(0 if failures==0 else 1)
