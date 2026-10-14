extends SceneTree
var game: Node
var checks := 0
var failures: Array[String] = []
const SLOT := "user://qa_playtest_fixes.json"
func _initialize() -> void:call_deferred("run")
func verify(ok: bool, label: String) -> void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
func has_keepsake(node: Node) -> bool:
	if node is TextureRect and node.texture!=null and node.texture.resource_path.contains("art/directors/"):return true
	for child in node.get_children():
		if has_keepsake(child):return true
	return false
func scene(chapter: int, index: int) -> void:game.chapter_index=chapter;game.scene_index=index;game.start_scene()
func run() -> void:
	if not OS.get_cmdline_user_args().has("--self-test"):quit(2);return
	game=load("res://scenes/main.tscn").instantiate();game.save_path=SLOT;root.add_child(game);await process_frame
	game._start_fresh();game.director.skip_cinematic()
	for i in range(5):game.director.inspect_keepsake(i)
	game.director.close_book();game.director.enter_next();game.director.skip_cinematic()
	for item in [[0,0],[0,1],[1,2],[2,1],[3,0],[5,1]]:
		scene(item[0],item[1]);verify(not has_keepsake(game.hud),"no decorative keepsake HUD in "+game._scene().id);verify(not is_instance_valid(game.director.room) and not is_instance_valid(game.director.cinema),"room/layer freed in "+game._scene().id)
	game._start_voxel();verify(not has_keepsake(game.hud),"no decorative keepsake HUD in voxel gameplay")
	game.director.show_room();verify(is_instance_valid(game.director.room) and game.director.room.displays.size()==5,"five hub display objects preserved")
	game.director.scrapbook();verify(has_keepsake(game.modal),"art reappears inside inspection");game.director.close_book()
	scene(0,2);verify(not game.memory.living.props.has("bench"),"lobby bench node removed")
	verify(game.memory.can_stand(Vector2(940,360)),"former bench area walkable")
	verify(not game.memory.interaction_targets().any(func(t):return t.id.contains("bench") or t.id=="living:sit"),"no invisible lobby bench interaction")
	for c in game.story.chapters:
		for s in c.scenes:
			for t in s.get("exploration",{}).get("steps",[])+s.get("exploration",{}).get("optional",[]):verify(t.get("visual",{}).get("kind","")!="notice","generic sign descriptor removed: "+s.id+"/"+t.id)
	scene(0,0);game.memory.player_position=Vector2(650,390);verify(game.memory.context_target().get("id","")=="paper","nearest valid object selected")
	game.memory.player_position=Vector2(1150,570);verify(game.memory.context_target().is_empty(),"indicator disappears out of range")
	game.memory.player_position=Vector2(500,500);game.memory.blockers.append(Rect2(525,450,10,100));verify(not game.memory.clear_interaction_line(Vector2(550,500)),"wall blocks interaction selection")
	scene(0,2);var world: Node2D=game.memory;world.player_position=Vector2(1020,540);var featured: Array=game.director.state.seen.duplicate()
	world.interact();verify(world.living.busy and world.living.photo_action.running and not world.living.state.photo,"photo starts action without early unlock")
	var p: Vector2=world.player_position;world.living.tick(.6);verify(not world.living.state.photo and not world.living.can_move(),"pocket/hold phases lock movement")
	world.living.tick(.7);verify(world.living.state.photo and world.living.state.photo_count==1,"shutter is authoritative unlock moment")
	verify(game.director.state.seen==featured,"conference photo never unlocks or replaces Instagram entry")
	world.living.tick(.9);verify(not world.living.busy and not world.living.photo_action.running and world.player_position==p,"lowering returns to idle without relocating hero")
	verify(root.canvas_transform==Transform2D.IDENTITY,"camera focus returns to original canvas")
	world.interact();world.living.tick(2.2);verify(world.living.state.photo_count==1,"repeat photo does not duplicate unlock")
	game._store_memory_state();game.test_mode=false;game.save_game();game.show_menu();game.load_game();game.test_mode=true
	verify(game.memory.living.state.photo and game.memory.living.state.photo_count==1 and not game.memory.living.busy,"actual save/load retains shot and safe idle")
	verify(not has_keepsake(game.hud),"no overlay after Continue with five inspected entries")
	var fixture:=Image.create(1280,720,false,Image.FORMAT_RGBA8);fixture.fill(Color("203343"));fixture.save_png("user://qa_playtest_photo.png")
	game.chapter_state.foot.living.photo_file="user://qa_playtest_photo.png";game.chapter_state.goodbye={"living":{"photo":true}}
	game._album(func():game.director.scrapbook())
	for child in game.modal.get_children():
		if child is TextureRect:verify(child.size==Vector2(275,155),"captured photo constrained to album preview")
		if child is Label and child.text.contains("Foto recreada"):verify(child.text.count("Foto recreada del modelo")==1,"conference album entry deduplicated across scenes")
	DirAccess.remove_absolute("user://qa_playtest_photo.png")
	game._restart_chapter(0);verify(not has_keepsake(game.hud),"no overlay after chapter select/restart")
	var config: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/guillermo_quiz.json"))
	verify(config.questions.size()==10 and config.pass_score==8 and config.hard_mode_index==7,"quiz structure/threshold unchanged")
	for index in [3,7]:
		for answer in [1,2]:
			var session: RefCounted=load("res://scripts/memory_challenge_session.gd").new();session.setup("guillermo",config);session.state.phase="play";session.state.index=index;session.act("answer",answer);verify(session.state.score==(1 if answer==2 else 0),"corrected fact scores C and rejects B: "+str(index))
	var legacy: RefCounted=load("res://scripts/memory_challenge_session.gd").new();legacy.setup("guillermo",config,{"phase":"feedback","index":3,"answers":[0,3,3,1],"score":4,"feedback":"¡Correcto! Cuatro ciudades."})
	verify(legacy.state.score==3 and legacy.state.feedback=="Esta no. Cinco ciudades.","cached Q4 feedback and score migrate to corrected facts")
	legacy.setup("guillermo",config,{"phase":"result","index":10,"answers":[0,3,3,1,1,2,1,1,0,0],"score":8,"passed":true})
	verify(legacy.state.score==6 and not legacy.state.passed,"legacy active result uses unchanged 8/10 threshold after correction")
	scene(5,1);world=game.memory;var target: Dictionary=world.mandatory_target();verify(Vector2(target.position[0],target.position[1])==Vector2(820,465),"letter belongs to its own ground anchor")
	world.player_position=Vector2(790,480);verify(world.prompt()=="E · Leer carta","letter uses unobtrusive HUD label")
	verify(not Rect2(335,600,610,45).intersects(Rect2(world.companion_position-Vector2(32,96),Vector2(64,96))),"card HUD avoids Guillermo")
	world.interact();verify(game._dialogue_open() and world.prompt()=="","letter interaction works and prompt hides during dialogue")
	verify(game.story.personal_letter.is_placeholder,"personal letter remains user-editable placeholder")
	scene(0,2);game.memory.player_position=Vector2(1020,570);game.memory.interact();game.memory.living.tick(.8);game.start_scene();await process_frame
	verify(root.canvas_transform==Transform2D.IDENTITY and not game.memory.living.busy,"restart during focus frees camera and unlocks controls")
	verify(not game.memory.living.state.photo,"restart before shutter cannot unlock an untaken photograph")
	for path in [SLOT,SLOT+".bak",SLOT+".tmp"]:DirAccess.remove_absolute(path)
	print("PLAYTEST_FIXES_QA: %d checks; %d failures" % [checks,failures.size()]);game.queue_free();await process_frame;await process_frame;quit(0 if failures.is_empty() else 1)
