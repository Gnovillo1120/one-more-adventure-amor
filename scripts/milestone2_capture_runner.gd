extends Node
## Native viewport evidence, gated by both capture flag and self-test in game.gd.
var game: Node
var directory := ""
var failures := 0
func verify(ok: bool, message: String) -> void:
	if not ok:failures+=1;push_error(message)
func shot(name: String, delay: float = .45) -> void:
	await get_tree().create_timer(delay).timeout
	await RenderingServer.frame_post_draw
	var path:=directory.path_join(name+".png")
	var result: Error=get_viewport().get_texture().get_image().save_png(path)
	verify(result==OK,"Cannot save native frame: "+path)
	print("CAPTURE "+name)
func run() -> void:
	directory=ProjectSettings.globalize_path("res://docs/milestone2/source")
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="):directory=argument.trim_prefix("--capture-dir=")
	DirAccess.make_dir_recursive_absolute(directory)
	game.chapter_index=3;game.scene_index=0;game.chapter_state={};game.start_scene()
	await shot("01_kitchen",1.1)
	game._open_challenge("cookies");var v: Control=game.challenge
	v.act("start");await shot("02_recipe_quiz")
	for i in range(3):v.act("quiz",0)
	v.show_station("pantry");await shot("03_pantry")
	for item in v.session.data.ingredients:v.act("ingredient",item.id)
	v.act("gather");v.show_station("counter")
	for i in range(3):v.act("pour",.2)
	await shot("04_measuring")
	v.act("empty")
	while v.session.state.phase=="measure":
		for i in range(5):v.act("pour",.2)
		v.act("measure")
	for frame in range(2):
		for i in range(2):v.act("mix",.1)
		await shot("05_mix_%d"%frame,.25)
	v.act("mix",.1)
	await shot("05_mixing")
	for frame in range(2,5):
		for i in range(2):v.act("mix",.1)
		await shot("05_mix_%d"%frame,.25)
	v.act("mixed")
	for i in range(10):v.act("mix",.15)
	v.act("mixed");v.grabbed=true;v.act("tap");await shot("06_egg")
	for egg in range(2):
		if v.session.state.egg_taps==0:v.act("tap")
		v.act("tap");v.act("crack")
	for phase in ["combine","oats"]:
		for i in range(3):v.act("add")
		for i in range(10):v.act("mix",.15)
		v.act("mixed")
	v.show_station("fridge");await shot("07_reposo");v.act("chill")
	v.show_station("oven");v.act("preheat");v.show_station("counter");v.act("spray")
	for p in v.session.default_portions():v.act("portion",p)
	await shot("08_portions");v.act("portioned")
	for i in range(3):v.act("dip");v.act("flatten",i)
	await shot("09_fork")
	for i in range(3,6):v.act("dip");v.act("flatten",i)
	v.show_station("oven");v.act("insert");v.act("mitts");v.session.tick(34);v.act("swap")
	await shot("10_oven")
	v.leave_counter();game.memory.player_position=Vector2(945,335);await shot("11_live_oven")
	v.show_station("oven");v.act("pull");v.show_station("rack");v.session.tick(5);v.act("rack");v.show_station("rack");v.act("taste")
	await shot("12_result")
	verify(v.session.state.passed and v.session.state.score>=90,"physical batch did not reach good result")
	v.act("continue")
	while game._dialogue_open():game.revealed=9999;game._advance_dialogue()
	verify(game.scene_completed,"baking continuation did not complete memory")
	game.chapter_state={};game.chapter_index=0;game.scene_index=4;game.start_scene();game.cinema.play("award",Callable())
	await shot("13_award",1.3);game.cinema.finish();game.cinema.finish()
	verify(not game.cinema.running and game.memory.active,"award skip did not restore controls")
	game.chapter_index=1;game.scene_index=2;game.start_scene();game.memory.seated=true;game.memory.restore_pose();game.cinema.play("date",Callable())
	await shot("14_food_arrival",1.5);game.cinema.finish()
	game.chapter_index=2;game.scene_index=2;game.start_scene();game.cinema.play("pool",Callable())
	await shot("15_pool_seated",.5);await shot("16_pool_lean",1.0);await shot("17_first_kiss",1.0)
	game.cinema.finish();verify(not game.cinema.running and game.memory.active,"romantic skip did not restore controls")
	game.chapter_index=3;game.scene_index=0;game.start_scene();game._open_challenge("cookies")
	v=game.challenge;preload("res://scripts/baking_test_driver.gd").new().bake(v.session,false);v.show_station("rack")
	await shot("18_imperfect_batch")
	print("MILESTONE2_CAPTURE: native source/export interaction and skip checks passed" if failures==0 else "MILESTONE2_CAPTURE: %d failures"%failures)
	game.show_menu();get_tree().quit(0 if failures==0 else 1)
