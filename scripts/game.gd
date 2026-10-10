extends Node
## Shared progression, dialogue, menus, settings and durable chapter checkpoints.
const MemoryWorld = preload("res://scripts/memory_world.gd")
const VoxelWorld = preload("res://scripts/voxel_world.gd")
const SAVE_PATH := "user://adventure_save.json"
const SETTINGS_PATH := "user://settings.cfg"
var save_path := SAVE_PATH
var settings_path := SETTINGS_PATH
const GOLD := Color("ebc48a")
const INK := Color("152331")
const CREAM := Color("f5ead6")
var story: Dictionary = {}
var chapter_index := 0
var scene_index := 0
var unlocked := 0
var keepsakes: Array = []
var stage := "menu"
var scene_completed := false
var memory: Node2D
var voxel: Node3D
var ui: Control
var canvas: CanvasLayer
var hud: Control
var modal: Control
var dialog_panel: Control
var dialog_text: Label
var speaker_label: Label
var portrait: TextureRect
var choices: VBoxContainer
var advance_button: Button
var objective_label: Label
var health_label: Label
var toast_label: Label
var lines: Array = []
var line_index := 0
var dialog_done: Callable
var revealed := 0.0
var text_speed := 45.0
var volume := .65
var fullscreen := false
var low_graphics := true
var is_paused := false
var minigame_kind := ""
var minigame_step := 0
var minigame_prompt: Label
var music: AudioStreamPlayer
var effects: AudioStreamPlayer
var current_theme := ""
var total_play_seconds := 0.0
var objective := ""
var autosave_pending := false
var last_autosave := 0.0
var test_mode := false
var pixel_font: FontFile
var capture_directory := "res://docs/screenshots"

func _ready() -> void:
	story = JSON.parse_string(FileAccess.get_file_as_string("res://data/story.json"))
	if ResourceLoader.exists("res://assets/fonts/PixelifySans.ttf"):
		pixel_font=load("res://assets/fonts/PixelifySans.ttf")
		pixel_font.antialiasing=TextServer.FONT_ANTIALIASING_NONE
	test_mode = OS.get_cmdline_user_args().has("--self-test") or OS.get_cmdline_user_args().has("--capture")
	_load_settings()
	_read_unlocks()
	canvas = CanvasLayer.new()
	add_child(canvas)
	ui = Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(ui)
	music = AudioStreamPlayer.new()
	effects = AudioStreamPlayer.new()
	add_child(music)
	add_child(effects)
	_apply_audio()
	show_menu()
	if OS.get_cmdline_user_args().has("--capture"): call_deferred("_capture_gallery")

func _process(delta: float) -> void:
	if stage != "menu" and not is_paused: total_play_seconds += delta
	if is_instance_valid(dialog_panel) and dialog_panel.visible and line_index < lines.size():
		revealed += delta * text_speed
		dialog_text.visible_characters = int(revealed)
		choices.visible = revealed >= dialog_text.text.length()
	if is_instance_valid(voxel) and stage == "voxel" and is_instance_valid(health_label):
		var distance: float=voxel.player.position.distance_to(voxel.current_target())
		health_label.text = "SALUD  %d / 100   ·   Clic: espada   ·   Objetivo: %d m" % [int(voxel.health),int(distance)]
		if is_instance_valid(toast_label):toast_label.text=voxel.get_prompt()
		if voxel.quest_index >= 8 and current_theme != "boss": _play_music("boss")
	if autosave_pending and is_instance_valid(voxel) and not is_paused:
		autosave_pending = false
		save_game()
	last_autosave += delta
	if last_autosave >= 20 and stage != "menu" and not test_mode:
		last_autosave = 0
		save_game()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE:
			if stage != "menu": _toggle_pause()
			get_viewport().set_input_as_handled()
			return
		if is_paused: return
		if minigame_kind == "dance":
			_dance_key(event.physical_keycode)
			return
		if is_instance_valid(dialog_panel) and dialog_panel.visible:
			if event.physical_keycode in [KEY_E, KEY_SPACE, KEY_ENTER]: _advance_dialogue()
			elif event.physical_keycode in [KEY_1,KEY_2,KEY_3]: _choose(int(event.physical_keycode-KEY_1))
			get_viewport().set_input_as_handled()
			return
		if event.physical_keycode == KEY_E:
			if stage == "voxel" and is_instance_valid(voxel): voxel.interact(); _sfx("interact")
			elif is_instance_valid(memory): memory.interact()
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and stage == "voxel" and not is_paused and not _dialogue_open():
		voxel.attack()
		_sfx("swing")

func _clear_ui() -> void:
	for child in ui.get_children():
		ui.remove_child(child)
		child.queue_free()
	hud = null; modal = null; dialog_panel = null

func _clear_world() -> void:
	for world in [memory, voxel]:
		if is_instance_valid(world):
			remove_child(world)
			world.queue_free()
	memory = null; voxel = null
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _label(parent: Node, text: String, rect: Rect2, size: int = 22, color: Color = CREAM) -> Label:
	var l := Label.new()
	l.text = text; l.position = rect.position; l.size = rect.size
	l.add_theme_font_size_override("font_size",size)
	l.add_theme_color_override("font_color",color)
	if pixel_font and size>=28:l.add_theme_font_override("font",pixel_font)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l

func _panel(parent: Node, rect: Rect2, alpha: float = .96) -> Panel:
	var p := Panel.new()
	p.position = rect.position; p.size = rect.size
	var box := StyleBoxFlat.new()
	box.bg_color = Color(INK,alpha)
	box.border_color = Color("8f7c70")
	box.set_border_width_all(2)
	box.set_corner_radius_all(4)
	p.add_theme_stylebox_override("panel",box)
	parent.add_child(p)
	return p

func _button(parent: Node, text: String, rect: Rect2, callback: Callable) -> Button:
	var b := Button.new()
	b.text = text; b.position = rect.position; b.size = rect.size
	b.add_theme_font_size_override("font_size",21)
	b.add_theme_color_override("font_color",CREAM)
	for state_name in ["normal","hover","pressed","focus"]:
		var box := StyleBoxFlat.new()
		box.bg_color = Color("30495a") if state_name in ["hover","focus"] else Color("203343")
		box.border_color = GOLD if state_name in ["hover","focus"] else Color("665e5d")
		box.set_border_width_all(2)
		box.set_content_margin_all(10)
		b.add_theme_stylebox_override(state_name,box)
	b.pressed.connect(func(): _sfx("menu"); callback.call())
	parent.add_child(b)
	return b

func _background(parent: Node, name: String) -> void:
	var p := "res://assets/art/backgrounds/%s.png" % name
	if ResourceLoader.exists(p):
		var tex := TextureRect.new()
		tex.texture = load(p); tex.position = Vector2.ZERO; tex.size = Vector2(1280,720)
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_SCALE
		tex.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(tex)
	else:
		var color := ColorRect.new(); color.color = INK; color.size = Vector2(1280,720);parent.add_child(color)

func show_menu() -> void:
	stage = "menu"; is_paused = false; minigame_kind = ""
	_clear_world(); _clear_ui()
	_background(ui,"beach")
	var shade := ColorRect.new(); shade.color=Color(.03,.08,.12,.67);shade.size=Vector2(640,720);ui.add_child(shade)
	_label(ui,"UNA HISTORIA PARA ANAMI",Rect2(85,80,480,30),17,GOLD)
	_label(ui,"One More\nAdventure, Amor",Rect2(80,125,500,140),49)
	_label(ui,"Un pie pisado. Un mensaje perdido.\nY todas las aventuras que todavía nos esperan.",Rect2(85,290,470,80),22)
	_button(ui,"Continuar",Rect2(85,405,390,48),load_game).disabled = _read_save().is_empty()
	_button(ui,"Nueva aventura",Rect2(85,463,390,48),_new_game)
	_button(ui,"Recuerdos / capítulos",Rect2(85,521,390,48),_chapter_menu)
	_button(ui,"Ajustes",Rect2(85,579,190,46),func(): _settings(show_menu))
	_button(ui,"Salir",Rect2(285,579,190,46),func(): get_tree().quit())
	_label(ui,"21 OCT 2023 — 21 OCT 2026\nHecho con amor · Diálogos dramatizados",Rect2(85,659,520,50),15,GOLD)
	_play_music("beach")

func _new_game() -> void:
	if FileAccess.file_exists(save_path):
		_clear_ui()
		var p := _panel(ui,Rect2(330,210,620,270))
		_label(p,"¿Comenzar otra aventura?",Rect2(30,25,560,45),30,GOLD)
		_label(p,"Reemplaza el punto de continuación. Los capítulos desbloqueados seguirán disponibles.",Rect2(30,85,560,80))
		_button(p,"Comenzar",Rect2(30,180,265,50),_start_fresh)
		_button(p,"Volver",Rect2(315,180,265,50),show_menu)
	else: _start_fresh()

func _start_fresh() -> void:
	chapter_index=0;scene_index=0;keepsakes=[];total_play_seconds=0
	start_scene()

func _chapter_menu() -> void:
	_clear_ui(); _background(ui,"beach")
	var p := _panel(ui,Rect2(290,80,700,570))
	_label(p,"Nuestros recuerdos",Rect2(35,25,630,50),34,GOLD)
	for i in range(story.chapters.size()):
		var b := _button(p,"%d · %s" % [i+1,story.chapters[i].title],Rect2(35,100+i*60,630,50),func(): _restart_chapter(i))
		b.disabled = i > unlocked
	_button(p,"Volver",Rect2(35,475,630,50),show_menu)

func _restart_chapter(index: int) -> void:
	chapter_index = index; scene_index = 0
	keepsakes = []
	for i in range(mini(index,4)): keepsakes.append(story.chapters[i].keepsake)
	start_scene()

func _chapter() -> Dictionary:
	return story.chapters[chapter_index]

func _scene() -> Dictionary:
	return _chapter().scenes[scene_index]

func start_scene(completed: bool = false, position_data: Array = []) -> void:
	_clear_world();_clear_ui()
	stage = "memory";scene_completed = completed;is_paused=false;minigame_kind=""
	var s := _scene()
	memory = MemoryWorld.new()
	memory.location=s.location
	memory.scene_id=s.id
	memory.outfit="formal" if chapter_index==0 else "halloween" if chapter_index==2 else "casual"
	memory.interaction_label=s.get("interact_label","Hablar")
	memory.completed=completed
	if s.location=="beach": memory.companion_position=Vector2(715,430);memory.player_position=Vector2(220,520)
	if s.location=="pool": memory.companion_position=Vector2(850,395)
	if position_data.size()==2: memory.player_position=Vector2(position_data[0],position_data[1])
	add_child(memory)
	memory.interacted.connect(_scene_interaction)
	memory.exited.connect(_next_scene)
	_build_hud()
	_set_objective("Recuerdo completo · Camina hacia la salida iluminada y pulsa E." if completed else s.objective)
	_play_music(["memory","date","halloween","date","mystery","beach"][chapter_index])
	save_game()
	_transition(_scene().title)

func _build_hud() -> void:
	hud = Control.new();hud.mouse_filter=Control.MOUSE_FILTER_IGNORE;ui.add_child(hud)
	var top := _panel(hud,Rect2(30,20,990,85),.88)
	_label(top,"%02d / 06   %s" % [chapter_index+1,_chapter().title],Rect2(20,10,940,30),23,GOLD)
	objective_label=_label(top,"",Rect2(20,43,940,35),19)
	_button(hud,"Ⅱ  Pausa",Rect2(1050,25,200,55),_toggle_pause)
	_panel(hud,Rect2(25,669,1230,39),.9)
	_label(hud,"WASD · Caminar     E · Interactuar / continuar     1–3 · Elegir     Esc · Pausa",Rect2(35,674,1110,30),17,CREAM)
	_panel(hud,Rect2(25,110,940,42),.75).visible=stage=="voxel"
	health_label=_label(hud,"",Rect2(35,115,900,35),19,GOLD)
	_panel(hud,Rect2(25,624,1070,40),.75).visible=stage=="voxel"
	toast_label=_label(hud,"",Rect2(35,627,1050,40),19,GOLD)
	for i in range(keepsakes.size()):
		var icon := TextureRect.new();icon.texture=load("res://assets/art/sprites/%s.png" % ["diploma","gyoza","bandana","cookie"][i]);icon.size=Vector2(36,36);icon.position=Vector2(1080+i*42,110);icon.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;hud.add_child(icon)
	dialog_panel=_panel(hud,Rect2(65,470,1150,190))
	dialog_panel.visible=false
	portrait=TextureRect.new();portrait.position=Vector2(10,0);portrait.size=Vector2(192,192);portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;portrait.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;dialog_panel.add_child(portrait)
	speaker_label=_label(dialog_panel,"",Rect2(200,16,850,28),22,GOLD)
	dialog_text=_label(dialog_panel,"",Rect2(200,52,910,94),24)
	choices=VBoxContainer.new();choices.position=Vector2(200,48);choices.size=Vector2(910,136);choices.add_theme_constant_override("separation",5);dialog_panel.add_child(choices)
	advance_button=_button(dialog_panel,"E  ›",Rect2(1045,140,80,35),_advance_dialogue)

func _set_objective(text: String) -> void:
	objective=text
	if is_instance_valid(objective_label): objective_label.text=text

func _scene_interaction() -> void:
	if _dialogue_open() or minigame_kind != "": return
	_sfx("interact")
	var s := _scene()
	if s.task=="sit":
		memory.seated=true;memory.player_position=memory.companion_position+Vector2(-55,0)
	var scene_lines: Array = s.lines.duplicate(true)
	if chapter_index==5 and s.id=="letter":
		scene_lines=[]
		if story.personal_letter.get("is_placeholder",true):
			scene_lines.append({"speaker":"Carta personal · borrador editable","text":story.personal_letter.title,"mood":"affectionate"})
		for paragraph in story.personal_letter.paragraphs:
			scene_lines.append({"speaker":"Guillermo","text":paragraph,"mood":"affectionate"})
		_scene_letter_intro(scene_lines)
	_show_dialogue(scene_lines,func(): _begin_task(s.task))

func _scene_letter_intro(scene_lines: Array) -> void:
	# Authored dramatic framing is not presented as Guillermo's private letter.
	scene_lines.push_front({"speaker":"Narrador","text":"Una llegada inesperada, una silla elegida, una cita, una bandana… Cada recuerdo abrió el camino a otra aventura juntos.","mood":"affectionate"})

func _show_dialogue(new_lines: Array, on_done: Callable) -> void:
	lines=new_lines;line_index=0;dialog_done=on_done
	if lines.is_empty(): on_done.call();return
	_set_world_active(false)
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	dialog_panel.visible=true
	_show_line()

func _show_line() -> void:
	var entry: Dictionary=lines[line_index]
	speaker_label.text=entry.get("speaker","Narrador")
	dialog_text.text=entry.get("text","")
	if is_instance_valid(memory):memory.apply_line(speaker_label.text,dialog_text.text)
	revealed=0;dialog_text.visible_characters=0
	for c in choices.get_children(): choices.remove_child(c);c.queue_free()
	var expression: String=entry.get("mood","neutral")
	var person: String="anami" if speaker_label.text=="Anami" else "guillermo" if speaker_label.text=="Guillermo" else ""
	var path: String="res://assets/art/portraits/%s_%s.png" % [person,expression]
	var variant: String="_formal" if chapter_index==0 else "_halloween" if chapter_index==2 else ""
	var variant_path: String="res://assets/art/portraits/%s_%s%s.png" % [person,expression,variant]
	if ResourceLoader.exists(variant_path):path=variant_path
	if person!="" and ResourceLoader.exists(path): portrait.texture=load(path)
	elif person!="":
		var atlas := AtlasTexture.new();atlas.atlas=load("res://assets/art/sprites/%s_%s.png" % [person,"halloween" if chapter_index==2 else "formal" if chapter_index==0 else "casual"]);atlas.region=Rect2(0,0,32,48);portrait.texture=atlas
	else: portrait.texture=null
	advance_button.visible=not entry.has("choices")
	if entry.has("choices"):
		dialog_panel.position.y=365;dialog_panel.size.y=295
		dialog_text.size.y=90;choices.position.y=145
		choices.size.y=125
		for i in range(entry.choices.size()):
			var b:=_button(choices,"%d · %s" % [i+1,entry.choices[i]],Rect2(0,0,850,31),func(): _choose(i))
			b.add_theme_font_size_override("font_size",17)
			b.custom_minimum_size.y=38
	else:
		dialog_panel.position.y=470;dialog_panel.size.y=190
		dialog_text.size.y=112
	choices.visible=false

func _dialogue_open() -> bool:
	return is_instance_valid(dialog_panel) and dialog_panel.visible

func _choose(index: int) -> void:
	if not _dialogue_open() or line_index>=lines.size(): return
	var entry: Dictionary=lines[line_index]
	if not entry.has("choices") or index>=entry.choices.size(): return
	_sfx("dialogue")
	var answer: String=entry.choices[index]
	lines.insert(line_index+1,{"speaker":"Anami","text":answer,"mood":"playful"})
	line_index+=1;_show_line()

func _advance_dialogue() -> void:
	if not _dialogue_open(): return
	if revealed < dialog_text.text.length(): revealed=dialog_text.text.length();return
	if lines[line_index].has("choices"): return
	line_index+=1
	if line_index<lines.size(): _show_line();return
	dialog_panel.visible=false
	_set_world_active(true)
	if stage=="voxel": Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
	var callback:=dialog_done
	dialog_done=Callable()
	if callback.is_valid(): callback.call()

func _begin_task(kind: String) -> void:
	if kind in ["food","dance","bake"]:
		minigame_kind=kind;minigame_step=0;_set_world_active(false)
		if kind=="dance" and is_instance_valid(memory):memory.dancing=true
		modal=_panel(ui,Rect2(320,180,640,390))
		_label(modal,{"food":"Una mesa para dos","dance":"Un baile sin examen","bake":"La gran discusión de las galletas"}[kind],Rect2(30,25,580,50),29,GOLD)
		minigame_prompt=_label(modal,"",Rect2(30,90,580,85),22)
		if kind=="dance":
			_label(modal,"Pulsa la tecla indicada. Sin límite de tiempo.\nSi te equivocas, seguimos bailando.",Rect2(30,230,580,95),20)
			_update_dance()
		else: _update_recipe()
	else: _finish_task()

func _update_recipe() -> void:
	for c in modal.get_children():
		if c is Button: modal.remove_child(c);c.queue_free()
	var orders: Array
	var question: String
	var correct: int
	if minigame_kind=="food":
		question=["¿Qué comparten para empezar?","¿Qué pidió Guillermo?","¿Qué pidió Anami?"][minigame_step]
		orders=[["Gyozas","Una moción diplomática","Sopa de galletas"],["Miso ramen","Sushi","Pescado para el gato"],["Sushi","Ramen","Veinte esmeraldas"]][minigame_step]
		correct=0
	else:
		question=["Esta vez seguimos la receta. Primero…","Ahora, con calma…","Por último…"][minigame_step]
		orders=[["Medir harina y azúcar","Echar lo que diga el corazón","Desafiar a la masa en Monopoly"],["Mezclar mantequilla y huevo","Añadir otra taza a ojo","Invocar un golem"],["Hornear con temporizador","Dejarlas hasta mañana","Declararlas patrimonio diplomático"]][minigame_step]
		correct=0
	minigame_prompt.text=question+"\nPaso %d de 3" % [minigame_step+1]
	for i in range(orders.size()):
		_button(modal,orders[i],Rect2(30,185+i*58,580,48),func():
			if i==correct:
				_sfx("collect");minigame_step+=1
				if minigame_step==3: _close_minigame()
				else: _update_recipe()
			else: minigame_prompt.text="Amor… esa opción suena divertida. Probemos otra.\n"+question)

func _update_dance() -> void:
	minigame_prompt.text="%s\nPaso %d de 8 · Tú marcas el ritmo." % [["W ↑","A ←","S ↓","D →","W ↑","D →","S ↓","A ←"][minigame_step],minigame_step+1]

func _dance_key(key: int) -> void:
	var sequence: Array=[KEY_W,KEY_A,KEY_S,KEY_D,KEY_W,KEY_D,KEY_S,KEY_A]
	if key==sequence[minigame_step]:
		_sfx("interact");minigame_step+=1
		if minigame_step==8: _close_minigame()
		else: _update_dance()

func _close_minigame() -> void:
	minigame_kind=""
	if is_instance_valid(memory):memory.dancing=false
	if is_instance_valid(modal): ui.remove_child(modal);modal.queue_free();modal=null
	_finish_task()

func _finish_task() -> void:
	var after: Array=_scene().get("after",[])
	if not after.is_empty(): _show_dialogue(after,_complete_scene)
	else: _complete_scene()

func _complete_scene() -> void:
	if chapter_index==4 and scene_index==0:
		_start_voxel()
		return
	if chapter_index==5 and scene_index==_chapter().scenes.size()-1:
		unlocked=5;save_game();_credits();return
	scene_completed=true
	if is_instance_valid(memory): memory.completed=true;memory.active=true
	_set_objective("Recuerdo completo · Camina hacia la salida iluminada y pulsa E.")
	_sfx("collect")
	save_game()

func _next_scene() -> void:
	scene_index+=1
	if scene_index>=_chapter().scenes.size():
		if chapter_index<4 and not keepsakes.has(_chapter().keepsake): keepsakes.append(_chapter().keepsake)
		chapter_index+=1;scene_index=0;unlocked=maxi(unlocked,chapter_index)
	start_scene()

func _start_voxel(saved: Dictionary = {}) -> void:
	_clear_world();_clear_ui();stage="voxel";scene_completed=false
	voxel=VoxelWorld.new()
	voxel.message_requested.connect(func(message: Array): _show_dialogue(message,func(): save_game()))
	voxel.objective_changed.connect(func(text: String): _set_objective(text);autosave_pending=true)
	voxel.finished.connect(_voxel_finished)
	add_child(voxel)
	_build_hud()
	_set_objective(voxel.goals[voxel.quest_index])
	if not saved.is_empty(): voxel.restore_save(saved)
	Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
	_play_music("mystery")
	save_game()
	_transition("Tus recuerdos no se borran.",true)

func _transition(title: String, glitch: bool=false) -> void:
	if test_mode:return
	var veil:=ColorRect.new();veil.color=Color(INK,1);veil.size=Vector2(1280,720);veil.mouse_filter=Control.MOUSE_FILTER_IGNORE;ui.add_child(veil)
	var caption:=_label(veil,title,Rect2(200,300,880,100),36,GOLD);caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	if glitch:
		for i in range(8):
			var stripe:=ColorRect.new();stripe.color=Color(.43,.29,.55,.45);stripe.position=Vector2(0,i*90+15);stripe.size=Vector2(1280,8+i%3*4);veil.add_child(stripe)
	var tween:=create_tween()
	tween.tween_interval(.65 if glitch else .4)
	tween.tween_property(veil,"modulate:a",0.0,.65)
	tween.tween_callback(func():if is_instance_valid(veil):veil.queue_free())

func _voxel_finished() -> void:
	# Scene 1 is the authored reunion. Keep controls on Anami throughout.
	scene_index=1
	start_scene()

func _set_world_active(value: bool) -> void:
	if is_instance_valid(memory): memory.active=value
	if is_instance_valid(voxel): voxel.set_active(value)

func _toggle_pause() -> void:
	if stage=="menu": return
	is_paused=not is_paused
	if is_paused:
		_set_world_active(false);Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
		modal=_panel(ui,Rect2(390,150,500,440))
		_label(modal,"Una pausa, amor",Rect2(30,25,440,55),34,GOLD)
		_button(modal,"Continuar",Rect2(30,105,440,50),_toggle_pause)
		_button(modal,"Guardar partida",Rect2(30,170,440,50),func(): save_game();_toast("Partida guardada"))
		_button(modal,"Ajustes",Rect2(30,235,440,50),func(): _settings(_return_pause))
		_button(modal,"Reiniciar capítulo",Rect2(30,300,440,50),func(): _restart_chapter(chapter_index))
		_button(modal,"Guardar y volver al menú",Rect2(30,365,440,50),func(): save_game();show_menu())
	else:
		if is_instance_valid(modal): ui.remove_child(modal);modal.queue_free();modal=null
		_set_world_active(not _dialogue_open() and minigame_kind=="")
		if stage=="voxel" and not _dialogue_open(): Input.mouse_mode=Input.MOUSE_MODE_CAPTURED

func _return_pause() -> void:
	is_paused=false;_toggle_pause()

func _settings(on_back: Callable) -> void:
	if is_instance_valid(modal):ui.remove_child(modal);modal.queue_free()
	modal=_panel(ui,Rect2(340,150,600,430))
	_label(modal,"Ajustes",Rect2(30,25,540,50),34,GOLD)
	_label(modal,"Volumen",Rect2(30,100,170,35),22)
	var slider:=HSlider.new();slider.position=Vector2(205,108);slider.size=Vector2(340,30);slider.min_value=0;slider.max_value=1;slider.step=.01;slider.value=volume;modal.add_child(slider)
	slider.value_changed.connect(func(value: float):volume=value;_apply_audio();_save_settings())
	_label(modal,"Velocidad del texto",Rect2(30,165,240,35),22)
	var speed:=HSlider.new();speed.position=Vector2(280,172);speed.size=Vector2(265,30);speed.min_value=20;speed.max_value=110;speed.value=text_speed;modal.add_child(speed)
	speed.value_changed.connect(func(value: float):text_speed=value;_save_settings())
	var screen:=CheckButton.new();screen.text="Pantalla completa";screen.position=Vector2(30,230);screen.button_pressed=fullscreen;modal.add_child(screen)
	screen.toggled.connect(func(value: bool):fullscreen=value;DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if value else DisplayServer.WINDOW_MODE_WINDOWED);_save_settings())
	var graphics:=CheckButton.new();graphics.text="Gráficos ligeros (recomendado)";graphics.position=Vector2(30,280);graphics.button_pressed=low_graphics;modal.add_child(graphics)
	graphics.toggled.connect(func(value: bool):low_graphics=value;get_viewport().scaling_3d_scale=.75 if value else 1.0;_save_settings())
	_button(modal,"Volver",Rect2(30,350,540,50),func():ui.remove_child(modal);modal.queue_free();modal=null;on_back.call())

func _load_settings() -> void:
	var config:=ConfigFile.new()
	if config.load(settings_path)==OK:
		volume=config.get_value("audio","volume",.65);text_speed=config.get_value("accessibility","text_speed",45.0);fullscreen=config.get_value("graphics","fullscreen",false);low_graphics=config.get_value("graphics","low",true)
	if fullscreen:DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	get_viewport().scaling_3d_scale=.75 if low_graphics else 1.0

func _save_settings() -> void:
	if test_mode:return
	var config:=ConfigFile.new();config.set_value("audio","volume",volume);config.set_value("accessibility","text_speed",text_speed);config.set_value("graphics","fullscreen",fullscreen);config.set_value("graphics","low",low_graphics);config.save(settings_path)

func _apply_audio() -> void:
	if is_instance_valid(music):music.volume_db=linear_to_db(maxf(volume,.0001))
	if is_instance_valid(effects):effects.volume_db=linear_to_db(maxf(volume*.55,.0001))

func _play_music(theme: String) -> void:
	if current_theme==theme:return
	current_theme=theme
	var audio: AudioStreamWAV=load("res://assets/audio/%s.wav" % theme)
	audio.loop_mode=AudioStreamWAV.LOOP_FORWARD
	audio.loop_begin=0;audio.loop_end=audio.data.size()/2
	music.stream=audio;music.play()

func _sfx(name: String) -> void:
	if test_mode:return
	effects.stream=load("res://assets/audio/%s.wav" % name);effects.play()

func _toast(text: String) -> void:
	if is_instance_valid(toast_label):toast_label.text=text

func _save_payload() -> Dictionary:
	var payload: Dictionary={"version":1,"chapter":chapter_index,"scene":scene_index,"stage":stage,"completed":scene_completed,"unlocked":unlocked,"keepsakes":keepsakes,"play_seconds":total_play_seconds}
	if is_instance_valid(memory):payload.position=[memory.player_position.x,memory.player_position.y]
	if is_instance_valid(voxel):payload.voxel=voxel.get_save_data()
	return payload

func save_game() -> void:
	if test_mode or stage=="menu":return
	var payload:=JSON.stringify(_save_payload())
	var file:=FileAccess.open(save_path+".tmp",FileAccess.WRITE)
	if file==null:_toast("No se pudo guardar. Revisa el espacio disponible.");return
	file.store_string(payload);file.close()
	# Keep previous valid checkpoint as a recovery copy.
	if FileAccess.file_exists(save_path):DirAccess.copy_absolute(save_path,save_path+".bak")
	var result:=DirAccess.rename_absolute(save_path+".tmp",save_path)
	if result!=OK:
		var direct:=FileAccess.open(save_path,FileAccess.WRITE)
		if direct:direct.store_string(payload);direct.close()
		else:_toast("Error al guardar. La copia anterior está disponible.")

func _read_save() -> Dictionary:
	for p in [save_path,save_path+".bak"]:
		if FileAccess.file_exists(p):
			var parser:=JSON.new()
			if parser.parse(FileAccess.get_file_as_string(p))!=OK:continue
			var data=parser.data
			if data is Dictionary and data.get("version",0)==1 and int(data.get("chapter",-1)) in range(6) and data.get("keepsakes",[]) is Array:
				return data
	return {}

func _read_unlocks() -> void:
	var data:=_read_save();unlocked=clampi(int(data.get("unlocked",0)),0,5)

func load_game() -> void:
	var data:=_read_save()
	if data.is_empty():_start_fresh();return
	chapter_index=int(data.chapter);scene_index=clampi(int(data.get("scene",0)),0,_chapter().scenes.size()-1)
	unlocked=maxi(unlocked,int(data.get("unlocked",0)));keepsakes=data.get("keepsakes",[]);total_play_seconds=data.get("play_seconds",0.0)
	if data.get("stage","")=="voxel":_start_voxel(data.get("voxel",{}))
	else:start_scene(data.get("completed",false),data.get("position",[]))

func _credits() -> void:
	stage="credits";_clear_world();_clear_ui();_background(ui,"beach");_play_music("beach")
	var p:=_panel(ui,Rect2(210,120,860,485),.9)
	_label(p,"One More Adventure, Amor",Rect2(35,30,790,60),40,GOLD)
	_label(p,"Te amo, amor.\nFelices 3 años. ♥\n21 de octubre de 2023 — 21 de octubre de 2026",Rect2(35,115,790,115),28)
	_label(p,"Una aventura de Guillermo para Anami\nDesarrollo y arte original: Codex · Motor: Godot\nMúsica instrumental original sintetizada\nDiálogos dramatizados · Carta personal editable",Rect2(35,265,790,115),21)
	_button(p,"Volver al menú",Rect2(35,405,790,50),show_menu)

func _notification(what: int) -> void:
	if what==NOTIFICATION_WM_CLOSE_REQUEST:save_game();get_tree().quit()

func _capture_gallery() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="):capture_directory=argument.trim_prefix("--capture-dir=")
	DirAccess.make_dir_recursive_absolute(capture_directory)
	await _capture_frame("01_menu")
	chapter_index=0;scene_index=0;start_scene()
	await _capture_frame("02_uees")
	_scene_interaction();line_index=3;_show_line();revealed=9999
	await _capture_frame("03_dialogue")
	chapter_index=0;scene_index=1;start_scene();_scene_interaction();line_index=4;_show_line();revealed=9999
	await _capture_frame("03b_choices")
	chapter_index=0;scene_index=3;start_scene()
	await _capture_frame("03c_dining")
	chapter_index=0;scene_index=4;start_scene()
	await _capture_frame("03d_auditorium")
	chapter_index=1;scene_index=2;start_scene()
	await _capture_frame("04_ikura")
	_begin_task("food")
	await _capture_frame("04b_food")
	chapter_index=2;scene_index=1;start_scene()
	await _capture_frame("05_halloween")
	_scene_interaction();line_index=1;_show_line();revealed=9999
	await _capture_frame("05b_halloween_portrait")
	chapter_index=2;scene_index=2;start_scene()
	await _capture_frame("05c_pool")
	chapter_index=3;scene_index=1;start_scene()
	await _capture_frame("06_kitchen")
	chapter_index=4;scene_index=0;_start_voxel()
	# Verify mouse rotation in a rendered native window with cursor capture.
	var yaw_before: float=voxel.yaw
	var mouse:=InputEventMouseMotion.new();mouse.relative=Vector2(80,-20)
	Input.parse_input_event(mouse);Input.flush_buffered_events()
	await get_tree().process_frame
	print("NATIVE_CAMERA_ROTATION_OK" if absf(voxel.yaw-yaw_before)>.01 else "NATIVE_CAMERA_ROTATION_FAILED")
	voxel.yaw=0
	voxel.set_active(false);Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	await _capture_frame("07_voxel_house")
	voxel.player.position=Vector3(-15,1,-8);voxel.yaw=0
	await _capture_frame("08_voxel_cave")
	voxel.player.position=Vector3(75,1,7)
	voxel.quest_index=8;voxel._update_atmosphere()
	_set_objective(voxel.goals[voxel.quest_index])
	await _capture_frame("09_end")
	chapter_index=5;scene_index=0;start_scene()
	await _capture_frame("10_beach")
	_toggle_pause()
	await _capture_frame("10b_pause")
	_settings(_return_pause)
	await _capture_frame("10c_settings")
	_credits()
	await _capture_frame("11_credits")
	print("CAPTURE_GALLERY_OK")
	music.stop();music.stream=null;effects.stop();effects.stream=null
	await get_tree().create_timer(.3).timeout
	get_tree().quit()

func _capture_frame(name: String) -> void:
	await get_tree().process_frame
	await get_tree().create_timer(.25).timeout
	await RenderingServer.frame_post_draw
	var frame:=get_viewport().get_texture().get_image()
	frame.save_png("%s/%s.png" % [capture_directory,name])
