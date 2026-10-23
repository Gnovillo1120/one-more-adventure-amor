extends Node
## Optional personal objects and fictional hub; chapter progress remains independent.
const Room = preload("res://scripts/memory_room.gd")
var game: Node
var data: Dictionary
var state: Dictionary = {}
var room: Node2D
var cinema: CanvasLayer
var cinema_tween: Tween
var cinema_done: Callable
var inspected := ""
var art_view: TextureRect
var art_clock := 0.0
var book_visible := false
var book_music := ""

func _ready() -> void:
	data=JSON.parse_string(FileAccess.get_file_as_string("res://data/directors_cut.json"))
	reset()

func reset() -> void:
	state={"recovered":[],"seen":[],"repaired":[],"hub_position":[665,550],"intro_seen":false,"bookmark":{},"notes":{}}

func recovered(index: int) -> bool:return state.recovered.has(index)

func snapshot() -> Dictionary:
	if is_instance_valid(room) and game.stage=="hub":state.hub_position=[room.player_position.x,room.player_position.y]
	return state.duplicate(true)

func restore(saved: Dictionary, legacy: Dictionary) -> void:
	reset()
	for key in state:
		if saved.has(key) and typeof(saved[key])==typeof(state[key]):state[key]=saved[key].duplicate(true) if saved[key] is Array or saved[key] is Dictionary else saved[key]
	state.recovered=state.recovered.filter(func(v):return (v is int or v is float) and int(v) in range(6))
	state.seen=state.seen.filter(func(v):return v is String)
	state.repaired=state.repaired.filter(func(v):return v is String)
	var p: Array=state.hub_position
	if p.size()!=2 or not (p[0] is float or p[0] is int) or not (p[1] is float or p[1] is int):state.hub_position=[665,550]
	var bookmark: Dictionary=state.bookmark
	if not bookmark.is_empty() and (not bookmark.has_all(["chapter","scene","unlocked","completed","keepsakes","chapter_state"]) or not bookmark.get("chapter_state",{}) is Dictionary or not bookmark.get("keepsakes",[]) is Array):state.bookmark={}
	for kind in state.notes.keys():
		if not state.notes[kind] is Dictionary or not state.notes[kind].has_all(["first","latest"]):state.notes.erase(kind)
	# Legacy saves enter their original scene, without replacing local gameplay state.
	for i in range(clampi(int(legacy.get("unlocked",0)),0,5)):
		if not recovered(i):state.recovered.append(i)
	if legacy.get("stage","")=="credits" and not recovered(5):state.recovered.append(5)

func clear_room() -> void:
	book_visible=false;book_music="";art_view=null;inspected=""
	if is_instance_valid(room):game.remove_child(room);room.queue_free()
	room=null

func cancel_cinematic() -> void:
	if cinema_tween:cinema_tween.kill()
	if is_instance_valid(cinema):cinema.queue_free()
	cinema=null;cinema_done=Callable()

func skip_cinematic() -> void:
	if not is_instance_valid(cinema):return
	var done:=cinema_done
	cancel_cinematic()
	if done.is_valid():done.call()

func handle_input(event: InputEvent) -> bool:
	if not event is InputEventKey or not event.pressed or event.echo:return false
	if is_instance_valid(cinema) and event.physical_keycode in [KEY_E,KEY_SPACE,KEY_ESCAPE]:skip_cinematic();return true
	if book_visible and event.physical_keycode==KEY_ESCAPE:close_book();return true
	if game.stage=="hub" and not game.is_paused and event.physical_keycode==KEY_E:
		if is_instance_valid(room):room.interact()
		return true
	return false

func title_room() -> void:
	room=Room.new();room.director=self;room.title_mode=true;room.active=false;game.add_child(room)

func new_game() -> void:
	reset();show_room();game.stage="opening";room.active=false
	room.player_position=Vector2(665,620)
	film("La última página","Recuerdos recreados · aventura mágica ficticia",4.5,func():state.intro_seen=true;show_room())
	if game.reduced_motion:room.player_position=Vector2(665,510)
	game.save_game()

func film(title: String, subtitle: String, duration: float, done: Callable) -> void:
	cancel_cinematic();cinema=CanvasLayer.new();cinema.layer=20;add_child(cinema);cinema_done=done
	var screen:=Control.new();screen.size=Vector2(1280,720);cinema.add_child(screen)
	var shade:=ColorRect.new();shade.color=Color(.04,.06,.1,.35);shade.size=screen.size;screen.add_child(shade)
	var panel: Panel=game._panel(screen,Rect2(225,35,830,120),.88)
	var heading: Label=game._label(panel,title,Rect2(20,15,790,45),32,game.GOLD);heading.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	var caption: Label=game._label(panel,subtitle,Rect2(20,70,790,35),18);caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	game._button(screen,"Saltar · Espacio",Rect2(985,630,245,50),skip_cinematic).grab_focus()
	cinema_tween=create_tween()
	if game.stage=="hub":
		var photo:=frame_art(screen,data.pages[game.chapter_index].art,Rect2(400,200,480,270))
		if not game.reduced_motion:
			cinema_tween.tween_property(photo,"position",Vector2.ZERO,1.2).set_trans(Tween.TRANS_SINE)
			cinema_tween.parallel().tween_property(photo,"size",Vector2(1280,720),1.2).set_trans(Tween.TRANS_SINE)
			screen.move_child(panel,screen.get_child_count()-1)
			screen.move_child(screen.get_child(1),screen.get_child_count()-1)
	cinema_tween.tween_interval(.5 if game.reduced_motion else duration);cinema_tween.tween_callback(skip_cinematic)

func show_room() -> void:
	cancel_cinematic();game._clear_world();game._clear_ui();game.stage="hub";game.is_paused=false;game.minigame_kind="";inspected=""
	room=Room.new();room.director=self;var p: Array=state.hub_position
	if p.size()==2 and room.legal(Vector2(p[0],p[1])):room.player_position=Vector2(p[0],p[1])
	game.add_child(room)
	game._panel(game.ui,Rect2(20,12,930,92),.78)
	game._label(game.ui,"La habitación de los recuerdos",Rect2(35,20,860,45),32,game.GOLD)
	game._label(game.ui,"%d / 6 páginas · Cinco objetos, una historia compartida" % state.recovered.size(),Rect2(38,70,900,35),20)
	game._button(game.ui,"Continuar la aventura",Rect2(30,660,335,45),enter_next)
	game._button(game.ui,"Abrir el libro",Rect2(380,660,235,45),scrapbook)
	game._button(game.ui,"Pausa · Esc",Rect2(1025,660,225,45),game._toggle_pause)
	game._play_music("memories_hub");game.save_game()

func enter_next() -> void:
	if is_instance_valid(cinema):return
	if is_instance_valid(game.modal) or game.is_paused:return
	state.hub_position=[room.player_position.x,room.player_position.y]
	room.active=false
	film(data.pages[game.chapter_index].title,"Una página se abre. Entramos en el recuerdo.",1.8,func():game.start_scene())

func complete(index: int) -> void:
	if not recovered(index):state.recovered.append(index)

func note(kind: String, result: Dictionary) -> void:
	if result.get("phase","")!="result":return
	var entry: Dictionary=state.notes.get(kind,{})
	if not entry.has("first"):entry.first=int(result.get("score",0))
	entry.latest=int(result.get("score",0));state.notes[kind]=entry

func remove_modal() -> void:
	inspected="";art_view=null;book_visible=false
	if is_instance_valid(game.modal):game.ui.remove_child(game.modal);game.modal.queue_free();game.modal=null

func close_book() -> void:
	remove_modal()
	if book_music!="":game._play_music(book_music);book_music=""
	if game.is_paused:game._return_pause()

func frame_art(parent: Node, path: String, rect: Rect2) -> TextureRect:
	var v:=TextureRect.new();v.texture=load(path);v.position=rect.position;v.size=rect.size;v.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;v.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;v.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;v.mouse_filter=Control.MOUSE_FILTER_IGNORE;parent.add_child(v)
	v.size=rect.size
	return v

func decorate_book(panel: Control, fold_x: float=275) -> void:
	var paper:=StyleBoxFlat.new();paper.bg_color=Color("eee0bf");paper.border_color=Color("9e7a54");paper.set_border_width_all(3);panel.add_theme_stylebox_override("panel",paper)
	for child in panel.get_children():
		if child is Label:child.add_theme_color_override("font_color",Color("594435") if child.get_theme_font_size("font_size")>=27 else Color("273845"))
	var fold:=ColorRect.new();fold.color=Color("c5ab82");fold.position=Vector2(fold_x,85);fold.size=Vector2(2,395);fold.mouse_filter=Control.MOUSE_FILTER_IGNORE;panel.add_child(fold)

func _book_music() -> void:
	if book_music=="":book_music=game.current_theme
	game._play_music("memories_hub")

func scrapbook() -> void:inspect_keepsake(0)

func inspect_keepsake(index: int) -> void:
	_book_music()
	remove_modal();book_visible=true;var entry: Dictionary=data.keepsakes[index];inspected=entry.id;art_clock=0
	if not state.seen.has(entry.id):state.seen.append(entry.id)
	game.modal=game._panel(game.ui,Rect2(90,65,1100,570),.98)
	var panel: Control=game.modal
	game._label(panel,"Nuestro libro · Objetos que importan",Rect2(30,20,1020,45),30,game.GOLD)
	for i in range(data.keepsakes.size()):
		game._button(panel,["Yoda","La A dorada","La fotografía","El diploma","Las galletas"][i],Rect2(25,85+i*61,235,50),func():inspect_keepsake(i))
	art_view=frame_art(panel,entry.art,Rect2(300,145,224,224))
	game._label(panel,entry.title,Rect2(560,92,505,75),28,game.GOLD)
	game._label(panel,entry.description,Rect2(560,180,500,235),22)
	game._label(panel,entry.connection,Rect2(290,427,775,60),17,game.GOLD)
	if entry.id=="yoda_keychain":
		art_view.texture=load("res://assets/art/directors/box_closed.svg")
		game._button(panel,"Abrir la caja",Rect2(305,372,230,42),open_box)
	elif entry.id=="oatmeal_recipe":
		var score: Dictionary=state.notes.get("cookies",{})
		if score.is_empty():
			var legacy: Dictionary=game.chapter_state.get("improvise",{}).get("successful_challenges",{})
			if legacy.has("cookies"):score={"first":legacy.cookies,"latest":legacy.cookies}
		var text: String="Tu partida: aún no hemos horneado." if score.is_empty() else "En esta partida · primera tanda: %d%% · última: %d%%" % [int(score.first),int(score.latest)]
		game._label(panel,text,Rect2(290,372,770,48),19,game.GOLD)
	game._button(panel,"Páginas / capítulos",Rect2(25,503,320,43),func():inspect_page(game.chapter_index))
	var photo_unlocked: bool=game.chapter_state.values().any(func(s):return s.get("living",{}).get("photo",false))
	game._button(panel,"Fotos de la partida",Rect2(375,503,400,43),func():book_visible=false;art_view=null;inspected="";game._album(scrapbook)).disabled=not photo_unlocked
	game._button(panel,"Cerrar",Rect2(810,503,255,43),close_book).grab_focus()
	decorate_book(panel)
	game.save_game()

func open_box() -> void:
	if inspected!="yoda_keychain" or not is_instance_valid(art_view):return
	art_view.texture=load("res://assets/art/directors/box_open.svg")
	if not state.seen.has("yoda_box_open"):state.seen.append("yoda_box_open")
	var view:=art_view
	var tween:=create_tween();tween.tween_interval(.6 if game.reduced_motion else 1.3)
	tween.tween_callback(func():if is_instance_valid(view) and inspected=="yoda_keychain":view.texture=load("res://assets/art/directors/yoda_keychain.svg"))
	game.save_game()

func inspect_page(index: int) -> void:
	_book_music()
	remove_modal();book_visible=true;var page: Dictionary=data.pages[index]
	game.modal=game._panel(game.ui,Rect2(90,65,1100,570),.98);var panel: Control=game.modal
	game._label(panel,"Seis páginas de nuestra aventura",Rect2(30,20,1040,45),30,game.GOLD)
	for i in range(6):
		var b: Button=game._button(panel,"%d · %s" % [i+1,game.story.chapters[i].title],Rect2(25,85+i*60,335,48),func():inspect_page(i));b.disabled=i>game.unlocked and not recovered(i);b.clip_text=true;b.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;b.add_theme_font_size_override("font_size",18);b.size=Vector2(335,48);b.tooltip_text=game.story.chapters[i].title
	frame_art(panel,page.art,Rect2(390,95,300,170))
	game._label(panel,page.title,Rect2(725,95,340,100),27,game.GOLD)
	game._label(panel,page.note,Rect2(390,295,670,70),23)
	game._label(panel,"Capítulo recreado · Un juego del libro: recordar devuelve las letras." if index==0 and recovered(0) else "Capítulos recreados · Los objetos personales tienen sus propias páginas.",Rect2(390,425,670,60),17)
	if recovered(index) and game.stage=="hub":game._button(panel,"Revivir este recuerdo",Rect2(390,375,325,43),func():replay(index))
	elif index==game.chapter_index and game.stage=="hub":game._button(panel,"Entrar en el recuerdo",Rect2(390,375,325,43),func():remove_modal();enter_next())
	game._button(panel,"Los cinco objetos",Rect2(25,503,335,43),scrapbook)
	game._button(panel,"Cerrar",Rect2(810,503,255,43),close_book).grab_focus()
	if index==0 and recovered(0):
		var repaired: bool=state.repaired.has("guillermo")
		game._label(panel,"Guillermo" if repaired else "Guill…",Rect2(735,235,310,38),24,game.GOLD)
		if not repaired:game._button(panel,"Recordar su nombre",Rect2(735,375,325,43),func():state.repaired.append("guillermo");game.save_game();inspect_page(index))
	decorate_book(panel,375)

func replay(index: int) -> void:
	if not recovered(index) or game.stage!="hub":return
	remove_modal();var bookmark: Dictionary=game._save_payload();bookmark.erase("directors_cut");state.bookmark=bookmark
	for scene in game.story.chapters[index].scenes:game.chapter_state.erase(scene.id)
	game.chapter_index=index;game.scene_index=0;game.start_scene()

func replaying() -> bool:return not state.bookmark.is_empty()

func finish_replay() -> void:
	if not replaying():return
	var original: Dictionary=state.bookmark.duplicate(true);state.bookmark={}
	game.chapter_index=int(original.chapter);game.scene_index=int(original.scene);game.unlocked=int(original.unlocked);game.keepsakes=original.keepsakes.duplicate();game.chapter_state=original.chapter_state.duplicate(true);game.scene_completed=bool(original.completed)
	show_room()

func _process(delta: float) -> void:
	if game.is_paused and not is_instance_valid(art_view):return
	art_clock+=delta
	if game.stage=="opening" and is_instance_valid(room) and not game.reduced_motion:
		room.player_position.y=move_toward(room.player_position.y,510,38*delta)
		room.sync_actor(room.player_position.y>510)
	if is_instance_valid(art_view) and inspected=="a_necklace":
		art_view.modulate=Color(1,1,1) if game.reduced_motion else Color(1,.92+.08*sin(art_clock*2),.78+.22*sin(art_clock*2))

func capture() -> void:
	game.test_mode=true
	var directory: String="res://docs/directors/source"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="):directory=argument.trim_prefix("--capture-dir=")
	game.capture_directory=directory;DirAccess.make_dir_recursive_absolute(directory)
	await game._capture_frame("01_menu")
	game._start_fresh()
	for i in range(12):
		await get_tree().create_timer(.12).timeout;await game._capture_frame("intro_%02d" % i)
	skip_cinematic();await game._capture_frame("02_hub")
	var start: Vector2=room.player_position
	var event:=InputEventKey.new();event.physical_keycode=KEY_D;event.keycode=KEY_D;event.pressed=true;Input.parse_input_event(event);Input.flush_buffered_events()
	await get_tree().create_timer(.5).timeout
	event=InputEventKey.new();event.physical_keycode=KEY_D;event.keycode=KEY_D;event.pressed=false;Input.parse_input_event(event);Input.flush_buffered_events()
	var movement: float=room.player_position.x-start.x
	print("DIRECTORS_NATIVE_WALK_OK" if movement>30 else "DIRECTORS_NATIVE_WALK_FAILED")
	room.player_position=Vector2(665,495)
	event=InputEventKey.new();event.physical_keycode=KEY_E;event.keycode=KEY_E;event.pressed=true;Input.parse_input_event(event);Input.flush_buffered_events();await get_tree().process_frame
	var book_opened: bool=is_instance_valid(game.modal)
	print("DIRECTORS_NATIVE_BOOK_OK" if book_opened else "DIRECTORS_NATIVE_BOOK_FAILED")
	event=InputEventKey.new();event.physical_keycode=KEY_E;event.keycode=KEY_E;event.pressed=false;Input.parse_input_event(event);Input.flush_buffered_events()
	await game._capture_frame("03_yoda_closed")
	open_box();await game._capture_frame("04_yoda_box_open")
	await get_tree().create_timer(1.4).timeout;await game._capture_frame("05_yoda_keychain")
	for i in range(1,5):inspect_keepsake(i);await game._capture_frame("keepsake_%d" % i)
	close_book();enter_next()
	for i in range(8):await get_tree().create_timer(.08).timeout;await game._capture_frame("page_%02d" % i)
	skip_cinematic();await game._capture_frame("06_uess")
	game.chapter_index=4;game.scene_index=0;state.recovered=[0,1,2,3];show_room();await game._capture_frame("07_restored_room")
	inspect_page(0);await game._capture_frame("08_missing_name");state.repaired.append("guillermo");inspect_page(0);await game._capture_frame("09_restored_name")
	remove_modal();game.show_menu();await game._capture_frame("10_evolved_title")
	var proof:=FileAccess.open(directory+"/proof.json",FileAccess.WRITE)
	if proof:proof.store_string(JSON.stringify({"godot":Engine.get_version_info().string,"renderer":"GL Compatibility","adapter":RenderingServer.get_video_adapter_name(),"logical_viewport":[1280,720],"native_walk_dx":movement,"native_walk_ok":movement>30,"native_e_book_ok":book_opened,"staged_restored_room":true,"capture_complete":true},"\t"));proof.close()
	print("DIRECTORS_NATIVE_CAPTURE_OK");get_tree().quit()
