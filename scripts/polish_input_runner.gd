extends "res://scripts/baking_input_runner.gd"
## Native UESS/restaurant input, plus action-frame and durable-state regressions.
var actor_trace: Array = []
var portrait_samples: Dictionary = {}
var gui_meals: Array = []

func _process(delta: float) -> void:
	super._process(delta)
	if capture and not motion_saving and is_instance_valid(game.memory) and game.memory.scene_id=="lunch":
		var staging: Node2D=game.memory.staging
		var meal: int=int(staging.state.gui_meal)
		if gui_meals.is_empty() or int(gui_meals[-1].meal)!=meal:gui_meals.append({"meal":meal,"position":[game.memory.companion_position.x,game.memory.companion_position.y]})
		if staging.gui_gesture>0:
			var key: String="guillermo_serving_%d_%d"%[staging.gui_serving,int((1-staging.gui_gesture/.7)*4)]
			if not motion_samples.has(key):
				motion_samples[key]=true;motion_saving=true
				await RenderingServer.frame_post_draw
				var result: Error=get_viewport().get_texture().get_image().save_png(directory.path_join(key+".png"))
				verify(result==OK,"Guillermo serving frame saved");motion_saving=false
	if not capture or motion_saving or not game._dialogue_open():return
	var speaker: String=game.speaker_label.text
	if not preload("res://scripts/supporting_cast.gd").SPEAKERS.has(speaker) or portrait_samples.has(speaker):return
	portrait_samples[speaker]=true;motion_saving=true
	await RenderingServer.frame_post_draw
	var error: Error=get_viewport().get_texture().get_image().save_png(directory.path_join("portrait_"+speaker.validate_filename()+".png"))
	verify(error==OK,"actual supporting portrait viewport saved");motion_saving=false

func drain() -> void:
	while is_instance_valid(game.memory) and game.memory.seating:await get_tree().process_frame
	var guard:=0
	while (game._dialogue_open() or game.cinema.running) and guard<100:
		guard+=1
		if capture and game._dialogue_open() and preload("res://scripts/supporting_cast.gd").SPEAKERS.has(game.speaker_label.text) and game.revealed<game.dialog_text.text.length():
			await tap(KEY_E);await shot("speaking_"+game.speaker_label.text.validate_filename())
		await tap(KEY_1 if game._dialogue_open() and game.lines[game.line_index].has("choices") else KEY_E)
	verify(guard<100,"dialogue / cinematic releases input")

func scene(chapter: int,index: int) -> void:
	game.chapter_index=chapter;game.scene_index=index;game.start_scene()
	await get_tree().create_timer(1.0).timeout

func use_target(name: String) -> void:
	var target: Dictionary=game.memory.mandatory_target()
	await walk(Vector2(target.position[0],target.position[1]))
	verify(game.memory.context_target().get("id","")==target.id,"physical approach selects "+target.id)
	verify(game.memory.prompt().begins_with("E · "),"contextual E prompt before "+name)
	await shot(name+"_prompt");await tap(KEY_E);await shot(name+"_response")

func run() -> void:
	capture=DisplayServer.get_name()!="headless" and directory!=""
	if capture:
		DirAccess.make_dir_recursive_absolute(directory)
		var layer:=CanvasLayer.new();layer.layer=50;add_child(layer)
		input_label=Label.new();input_label.position=Vector2(30,635);input_label.add_theme_font_size_override("font_size",18);layer.add_child(input_label)
	Engine.max_fps=120;game.chapter_state={}
	await scene(0,3)
	verify(game.memory.staging.state.meal==0 and not game.memory.seated,"lunch begins without meal or seat")
	if DisplayServer.get_name()!="headless":
		var saved_gui: int=int(game.memory.staging.state.gui_meal)
		var checkpoint: Dictionary=JSON.parse_string(JSON.stringify(game._save_payload()))
		game.chapter_state=checkpoint.chapter_state;game.start_scene(false,checkpoint.position);await get_tree().process_frame
		verify(int(game.memory.staging.state.gui_meal)==saved_gui,"NPC meal components survive reload mid-line")
	for i in range(4):
		await use_target("catering_%d"%i)
		verify(game.memory.staging.state.meal==i+1,"physical E advances meal component")
		verify(game.chapter_state.lunch.staging.meal==i+1,"meal stage saved")
		if i==1 and DisplayServer.get_name()!="headless":
			await tap(KEY_ESCAPE);var paused_serve: float=game.memory.staging.gesture;var paused_gui: float=game.memory.staging.gui_gesture
			await get_tree().create_timer(.2).timeout
			verify(is_equal_approx(paused_serve,game.memory.staging.gesture) and is_equal_approx(paused_gui,game.memory.staging.gui_gesture),"pause freezes both serving gestures")
			await tap(KEY_ESCAPE)
		while game.memory.staging.gesture>0:await get_tree().process_frame
		await get_tree().process_frame
		verify(game.memory.actors.anami.carrying==i+1,"plate composition follows meal stage")
		await shot("catering_%d_delivered"%i)
	if DisplayServer.get_name()!="headless":
		await walk(Vector2(725,550))
		for pair in [[KEY_W,3],[KEY_S,0],[KEY_A,1],[KEY_D,2]]:
			inject(pair[0],true)
			for i in range(2):
				await get_tree().create_timer(.06).timeout
				verify(game.memory.actors.anami.row==pair[1] and game.memory.actors.anami.carrying==4,"held walking plate keeps directional pose")
				await shot("plate_direction_%d_%d"%[pair[1],i])
			inject(pair[0],false);await get_tree().process_frame
		var deadline_gui: int=Time.get_ticks_msec()+10000
		while int(game.memory.staging.state.gui_meal)<4 and Time.get_ticks_msec()<deadline_gui:await get_tree().process_frame
		verify(int(game.memory.staging.state.gui_meal)==4,"Guillermo independently completes every serving counter")
		verify(gui_meals.map(func(item: Dictionary):return int(item.meal)).has(2) and gui_meals.map(func(item: Dictionary):return int(item.meal)).has(3),"Guillermo receives rice and menestra before meat")
	await use_target("sitting_together")
	var deadline: int=Time.get_ticks_msec()+15000
	while not game._dialogue_open() and Time.get_ticks_msec()<deadline:await get_tree().process_frame
	verify(game.memory.seated and game._dialogue_open(),"plate put down and couple seated before dialogue")
	await shot("couple_seated");await drain()
	var saved: Dictionary=game.chapter_state.lunch.staging.duplicate(true)
	game.start_scene();await get_tree().process_frame
	verify(game.memory.staging.state.meal==saved.meal,"served meal restored")
	await scene(0,4)
	verify(game.memory.staging.state.ceremony=="seat" and not game.cinema.running,"award waits for chair")
	await use_target("ceremony_chair")
	if DisplayServer.get_name()!="headless":
		verify(game.memory.seated and not game.memory.active,"chair E visibly seats before announcement")
		for i in range(8):await shot("ceremony_%02d"%i);await get_tree().create_timer(.42).timeout
		while game.memory.staging.state.ceremony=="announcing":await get_tree().process_frame
	verify(game.memory.active and game.memory.quest_step==1,"ceremony returns player for congratulations")
	verify(game.memory.staging.audience.size()>=18,"seated student audience")
	await use_target("congratulate");await drain()
	game.chapter_state.erase("award");game.reduced_motion=true
	await scene(0,4);await use_target("ceremony_skip_chair")
	if DisplayServer.get_name()!="headless":
		verify(game.memory.actors.anami.row==3,"seated Anami faces the announcement")
		await tap(KEY_ESCAPE);var paused_time: float=game.memory.staging.time
		var paused_pose: float=game.memory.staging.audience[0].pose_clock
		await get_tree().create_timer(.2).timeout
		verify(is_equal_approx(paused_time,game.memory.staging.time),"pause freezes ceremony choreography")
		verify(is_equal_approx(paused_pose,game.memory.staging.audience[0].pose_clock),"pause freezes audience gestures")
		await tap(KEY_ESCAPE);await tap(KEY_SPACE)
		verify(game.memory.active and game.memory.actors.guillermo.has_diploma,"skip restores control and held diploma")
		await shot("ceremony_skipped_diploma")
	game.reduced_motion=false
	await scene(0,2)
	for approach in [Vector2(440,540),Vector2(380,485),Vector2(500,485),Vector2(490,475)]:
		await walk(approach)
		verify(game.memory.context_target().get("id","")=="living:water","fountain prompt from approach")
		await shot("fountain_%d_prompt"%actor_trace.size());await tap(KEY_E)
		for i in range(5):
			await get_tree().create_timer(.18).timeout
			var actor: Node2D=game.memory.actors.anami
			verify(actor.action_frame==1 and actor.action_row==0,"fountain holds authored left view")
			verify(actor.action_texture.resource_path.ends_with("anami_fountain.png"),"formal drinking outfit")
			actor_trace.append({"approach":[approach.x,approach.y],"frame":actor.action_frame,"row":actor.action_row})
			await shot("fountain_%02d"%actor_trace.size())
		while game.memory.living.busy:await get_tree().process_frame
		verify(game.memory.active,"fountain returns movement")
	await scene(1,0)
	await use_target("moncayo_phone");await drain()
	await use_target("moncayo_speaking");await drain()
	var Cast=load("res://scripts/supporting_cast.gd")
	for speaker in ["Moncayo","Presidencia","Delegación de Chad","Catering","Mesero"]:
		verify(Cast.portrait(speaker)!=null,"supporting speaker mapped: "+speaker)
	await scene(1,2)
	for name in ["ikura_host","ikura_seat","ikura_order"]:
		await use_target(name);await drain()
	verify(is_instance_valid(game.challenge) and game.challenge.session.kind=="order","normal restaurant enters order")
	await tap(KEY_ENTER)
	await shot("ikura_menu_page_1");await tap(KEY_RIGHT);await shot("ikura_menu_page_2")
	verify(game.challenge.menu_page==1 and game.challenge.session.data.dishes.size()==12,"expanded menu keyboard paging")
	await tap(KEY_LEFT)
	await tap(KEY_Q);await tap(KEY_1);await tap(KEY_W);await tap(KEY_1);await tap(KEY_R);await tap(KEY_1);await tap(KEY_ENTER)
	verify(not game.challenge.session.state.passed,"wrong restaurant order permits retry")
	await shot("ikura_retry");await tap(KEY_ENTER)
	verify(game.challenge.session.state.phase=="play","actual Enter retries only the order")
	await tap(KEY_Q);await tap(KEY_1);await tap(KEY_W);await tap(KEY_2);await tap(KEY_R);await tap(KEY_3);await tap(KEY_ENTER)
	verify(game.challenge.session.state.passed,"original exact order retained")
	if capture:
		var file:=FileAccess.open(directory.path_join("POLISH_INPUT_TRACE.json"),FileAccess.WRITE)
		file.store_string(JSON.stringify({"checks":checks,"failures":failures,"events":events,"fountain_frames":actor_trace,"guillermo_meal_progress":gui_meals},"  "));file.close()
	print("POLISH_INPUT_QA: %d checks; %d failures"%[checks,failures]);finished.emit(checks,failures)
