extends SceneTree
var game: Node
var checks := 0
var failures := 0
func _initialize() -> void:call_deferred("run")
func verify(ok: bool,text: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error(text)
func key(code: int) -> void:
	for down in [true,false]:
		var event:=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=down
		Input.parse_input_event(event);Input.flush_buffered_events();await process_frame
func scene(c: int,s: int) -> void:game.chapter_index=c;game.scene_index=s;game.start_scene()
func run() -> void:
	if not OS.get_cmdline_user_args().has("--self-test"):quit(2);return
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	var Cast=load("res://scripts/supporting_cast.gd")
	var hashes: Array=[]
	for i in range(12):
		var texture: Texture2D=Cast.sprite(i)
		verify(texture.get_size()==Vector2(32,48),"cast frame has registered source dimensions")
		var hash: int=hash(texture.get_image().get_data())
		verify(not hashes.has(hash),"distinct student/staff silhouette pixels");hashes.append(hash)
	for name in Cast.SPEAKERS:
		verify(Cast.portrait(name)!=null,"portrait exists for named supporting speaker")
	verify(Cast.portrait("Unnamed guest").resource_path.ends_with("neutral.svg"),"neutral unnamed fallback")
	game.chapter_state={"lunch":{"seated":true},"award":{"step":1}}
	scene(0,3);verify(game.memory.staging.state.meal==4,"legacy seated lunch keeps meal ready")
	scene(0,4);verify(game.memory.staging.state.ceremony=="congratulate","legacy completed ceremony not repeated")
	verify(game.memory.actors.guillermo.has_diploma,"restored ceremony retains the held award")
	game.chapter_state={"award":{"staging":{"ceremony":"announcing"},"seated":true}}
	scene(0,4);verify(game.memory.active and not game.memory.seated and game.memory.staging.target().id=="staging:seat","interrupted ceremony restores usable seat without input lock")
	game.chapter_state={};scene(3,0);game._open_challenge("cookies")
	await key(KEY_ENTER)
	for i in range(3):await key(KEY_1)
	var view: Control=game.challenge
	for id in ["pantry","fridge","sink"]:
		var p: Array=view.STATIONS[id];game.memory.player_position=game.memory.safe_position(Vector2(p[0],p[1]));await key(KEY_E)
	game.memory.player_position=Vector2(640,555);await key(KEY_E)
	# This tests checkpoint semantics, not headless physical held-key polling.
	for i in range(5):view.session.act("pour",.2)
	await key(KEY_ENTER)
	verify(view.transition_pending and view.session.state.measures.has("flour"),"measurement committed before transfer animation finishes")
	var payload: Dictionary=JSON.parse_string(JSON.stringify(game._save_payload()))
	game.chapter_state=payload.chapter_state;game.start_scene(false,payload.position)
	verify(game.challenge.session.state.measures.flour==2 and game.challenge.session.state.index==1,"save during pouring animation retains completed ingredient")
	verify(not game.challenge.transition_pending and game.memory.active,"reload discards transient animation lock")
	var recipe: Dictionary=game.challenge.session.data
	var Session=load("res://scripts/baking_session.gd")
	var driver=load("res://scripts/baking_test_driver.gd").new()
	var good=Session.new();good.setup("cookies",recipe);driver.bake(good)
	var bad=Session.new();bad.setup("cookies",recipe);driver.bake(bad,false)
	verify(good.state.score==100 and bad.state.score<60 and bad.state.passed,"perfect and poor outcomes both advance")
	verify(good.quality()!=bad.quality(),"quality reactions differ")
	var qualities: Array=[]
	for score in [98,82,63,38]:
		good.state.score=score;good.state.minutes=9
		qualities.append(good.quality())
	verify(qualities.size()==4 and qualities.duplicate().reduce(func(unique: Array,item: String):
		if not unique.has(item):unique.append(item)
		return unique,[]).size()==4,"four distinct nonblocking batch quality outcomes")
	var elapsed: float=good.state.minutes;good.state.phase="oven";good.state.inserted=true
	good.tick(-4);verify(good.state.minutes==elapsed,"negative time cannot reverse bake")
	good.tick(.2);verify(is_equal_approx(good.state.minutes,elapsed+.05),"oven time remains recipe minutes, independent of animation duration")
	game.queue_free();await process_frame
	print("M2_POLISH_QA: %d checks; %d failures"%[checks,failures]);quit(0 if failures==0 else 1)
