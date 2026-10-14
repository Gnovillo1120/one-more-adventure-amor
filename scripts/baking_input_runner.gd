extends Node
## End-to-end input regression. No station/key/act/interact methods are called.
signal finished(checks: int, failures: int)
var game: Node
var directory := ""
var checks := 0
var failures := 0
var events: Array = []
var input_label: Label
var capture := false

func verify(ok: bool, message: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error("BAKING_INPUT: "+message);get_tree().quit(1)

func inject(code: int, pressed: bool) -> void:
	var event:=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=pressed
	Input.parse_input_event(event);Input.flush_buffered_events()
	events.append({"physical_key":OS.get_keycode_string(code),"pressed":pressed,"phase":phase(),"inventory":inventory().duplicate(),"time_ms":Time.get_ticks_msec()})
	if is_instance_valid(input_label):input_label.text="Godot InputEventKey · %s %s"%[OS.get_keycode_string(code),"↓ press" if pressed else "↑ release"]

func phase() -> String:
	return str(game.challenge.session.state.phase) if is_instance_valid(game.challenge) else "dialogue" if game._dialogue_open() else "world"

func inventory() -> Array:
	return game.challenge.session.state.pantry if is_instance_valid(game.challenge) else []

func tap(code: int) -> void:
	inject(code,true);await get_tree().process_frame;inject(code,false);await get_tree().process_frame

func shot(name: String) -> void:
	if not capture:return
	await get_tree().create_timer(.15).timeout;await RenderingServer.frame_post_draw
	var result: Error=get_viewport().get_texture().get_image().save_png(directory.path_join(name+".png"))
	verify(result==OK,"native frame written: "+name)

func axis(code: int, coordinate: int, goal: float) -> void:
	inject(code,true)
	var deadline: int=Time.get_ticks_msec()+12000
	while absf(game.memory.player_position[coordinate]-goal)>2 and Time.get_ticks_msec()<deadline:
		await get_tree().process_frame
		var forward: bool=game.memory.player_position[coordinate]<goal
		var next_code: int=(KEY_D if forward else KEY_A) if coordinate==0 else (KEY_S if forward else KEY_W)
		if next_code!=code:inject(code,false);code=next_code;inject(code,true)
	inject(code,false);await get_tree().process_frame
	verify(absf(game.memory.player_position[coordinate]-goal)<=3,"walking key reaches waypoint: %s goal %s axis %d active %s"%[game.memory.player_position,goal,coordinate,game.memory.active])

func walk(point: Vector2) -> void:
	if DisplayServer.get_name()=="headless":
		# Headless DisplayServer cannot map physical polling keys; test routing there.
		# The native/export runner below actually walks using held input events.
		game.memory.player_position=game.memory.safe_position(point);await get_tree().process_frame;return
	var nav: RefCounted=load("res://scripts/memory_navigation.gd").new();nav.scan(game.memory)
	var path: Array=nav.path_to(point)
	verify(not path.is_empty(),"walkable route to station")
	for p in path:
		var delta: Vector2=p-game.memory.player_position
		if absf(delta.x)>2:await axis(KEY_D if delta.x>0 else KEY_A,0,p.x)
		delta=p-game.memory.player_position
		if absf(delta.y)>2:await axis(KEY_S if delta.y>0 else KEY_W,1,p.y)

func station(id: String, evidence: String = "") -> void:
	var positions: Dictionary={"pantry":Vector2(1160,335),"fridge":Vector2(280,310),"sink":Vector2(595,305),"counter":Vector2(640,555),"oven":Vector2(945,315),"rack":Vector2(975,555)}
	await walk(positions[id])
	var target: Dictionary=game.memory.context_target()
	verify(target.get("id","")=="baking:"+id,"displayed target is "+id)
	verify(game.memory.prompt().begins_with("E · "),"E prompt is visible")
	if evidence!="":await shot(evidence+"_before_E")
	inject(KEY_E,true);await get_tree().process_frame
	if evidence!="":await shot(evidence+"_E_pressed")
	inject(KEY_E,false);await get_tree().process_frame
	if evidence!="":await shot(evidence+"_after_E")
	events.append({"station":id,"prompt_target":target.get("id",""),"phase_after":phase(),"inventory_after":inventory().duplicate(),"station_after":game.challenge.session.state.station if is_instance_valid(game.challenge) else "","feedback":game.memory.living.note.text})

func hold_until(code: int, field: String, target: float) -> void:
	inject(code,true)
	var deadline: int=Time.get_ticks_msec()+12000
	while float(game.challenge.session.state[field])<target and Time.get_ticks_msec()<deadline:await get_tree().process_frame
	inject(code,false);await get_tree().process_frame
	verify(float(game.challenge.session.state[field])>=target,"held key advances "+field)

func run() -> void:
	capture=DisplayServer.get_name()!="headless" and directory!=""
	if capture:
		DirAccess.make_dir_recursive_absolute(directory)
		var layer:=CanvasLayer.new();layer.layer=50;add_child(layer)
		input_label=Label.new();input_label.position=Vector2(30,635);input_label.size=Vector2(1220,30);input_label.add_theme_color_override("font_color",Color("f5ead6"));input_label.add_theme_color_override("font_shadow_color",Color("152331"));input_label.add_theme_constant_override("shadow_offset_x",2);input_label.add_theme_constant_override("shadow_offset_y",2);input_label.add_theme_font_size_override("font_size",20);layer.add_child(input_label)
	Engine.max_fps=120
	game.chapter_index=3;game.scene_index=0;game.chapter_state={};game.start_scene()
	await get_tree().create_timer(1.1).timeout
	await walk(Vector2(975,535));await tap(KEY_E)
	var guard:=0
	while (game.cinema.running or game._dialogue_open()) and guard<70:
		guard+=1
		await tap(KEY_1 if game._dialogue_open() and game.lines[game.line_index].has("choices") else KEY_E)
	verify(phase()=="intro","real memory input opens prep quiz")
	await tap(KEY_ENTER)
	for i in range(3):await tap(KEY_1)
	verify(phase()=="gather" and game.memory.active and game.modal==null,"real quiz events release kitchen controls")
	await station("counter","00_counter_missing")
	verify(phase()=="gather" and game.memory.living.note.text.contains("faltan"),"counter explains missing ingredients")
	await station("pantry","01_pantry")
	verify(inventory().has("flour") and inventory().has("oats") and inventory().size()==10,"physical E collects dry ingredients")
	await station("fridge","02_fridge")
	verify(inventory().has("eggs") and inventory().has("butter") and inventory().size()==12,"physical E collects eggs and butter")
	await station("sink","03_sink")
	verify(inventory().has("water") and game.challenge.session.state.tools,"physical E collects water and tools")
	await station("counter","04_counter")
	verify(phase()=="measure" and game.modal==game.challenge and not game.memory.active,"physical E opens ready counter")
	if DisplayServer.get_name()=="headless":
		print("BAKING_INPUT_QA: %d checks; %d failures; quiz-to-gather through Input.parse_input_event"%[checks,failures]);finished.emit(checks,failures);return
	while phase()=="measure":
		await hold_until(KEY_SPACE,"fill",1.0);await tap(KEY_ENTER)
	for expected in ["dry","cream"]:
		verify(phase()==expected,"mix phase "+expected);await hold_until(KEY_SPACE,"mix",1.0);await tap(KEY_ENTER)
	for egg in range(2):await tap(KEY_G);await tap(KEY_T);await tap(KEY_T);await tap(KEY_ENTER)
	verify(phase()=="combine" and game.challenge.session.state.shells==0,"real egg controls incorporate two eggs")
	for expected in ["combine","oats"]:
		for i in range(3):await tap(KEY_A)
		await hold_until(KEY_SPACE,"mix",1.0);await tap(KEY_ENTER)
	verify(phase()=="chill" and game.memory.active,"dough returns to walkable kitchen")
	await station("oven","05_oven_too_soon")
	verify(game.memory.living.note.text.contains("frigorífico"),"wrong station explains chilling requirement")
	await station("fridge","06_chill");await tap(KEY_ENTER)
	verify(phase()=="preheat","fridge E and Enter chill dough")
	await station("oven","07_preheat");await tap(KEY_2);await tap(KEY_ENTER)
	verify(phase()=="tray","oven E and Enter preheat")
	await station("counter","08_tray");await tap(KEY_S)
	for i in range(7):await tap(KEY_ENTER)
	verify(phase()=="flatten","real tray controls form portions")
	for i in range(6):await tap(KEY_D);await tap(KEY_ENTER)
	verify(phase()=="oven" and game.memory.active,"fork controls finish tray")
	await station("oven","09_insert");await tap(KEY_ENTER);await tap(KEY_M)
	await tap(KEY_TAB)
	verify(game.memory.active and game.modal==null,"real Tab releases close-up focus")
	await tap(KEY_ESCAPE);var minutes: float=game.challenge.session.state.minutes
	await get_tree().create_timer(.2).timeout
	verify(is_equal_approx(minutes,game.challenge.session.state.minutes),"pause freezes baking timer")
	await tap(KEY_ESCAPE)
	await station("oven")
	while game.challenge.session.state.minutes<4:await get_tree().process_frame
	await tap(KEY_S)
	while game.challenge.session.state.minutes<8.5:await get_tree().process_frame
	await shot("10_perfect_window");await tap(KEY_ENTER)
	verify(phase()=="cool" and game.challenge.session.state.swapped,"physical oven controls remove timed batch")
	await station("rack","11_cooling")
	while game.challenge.session.state.cool<5:await get_tree().process_frame
	await tap(KEY_ENTER);await station("rack");await tap(KEY_ENTER)
	verify(phase()=="result" and game.challenge.session.state.passed and game.challenge.session.state.score>=95,"full input bake reaches good result")
	await shot("12_result");await tap(KEY_ENTER)
	guard=0
	while game._dialogue_open() and guard<70:guard+=1;await tap(KEY_E)
	verify(game.scene_completed and game.keepsakes.has(game._chapter().keepsake),"real input completes cookie chapter")
	if capture:
		var file:=FileAccess.open(directory.path_join("INPUT_TRACE.json"),FileAccess.WRITE);file.store_string(JSON.stringify({"checks":checks,"failures":failures,"input_events":events},"  "));file.close()
	print("BAKING_INPUT_QA: %d checks; %d failures; complete workflow through Input.parse_input_event"%[checks,failures])
	finished.emit(checks,failures)
