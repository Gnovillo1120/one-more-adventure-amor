extends Node2D
## Small top-down memory stage. Artwork and animations use nearest filtering.
signal interacted
signal exited
signal target_interacted(id: String)
const INTERACTION_RADIUS := 72.0
const PLAYER_HALF := Vector2(10, 6)
const WALK_BOUNDS := Rect2(110,225,1080,355)
const InteractionProp = preload("res://scripts/interaction_prop.gd")
const RoomLayer = preload("res://scripts/layered_room.gd")
const RoomFixture = preload("res://scripts/room_fixture.gd")
const MemoryActor = preload("res://scripts/memory_actor.gd")
const Navigation = preload("res://scripts/memory_navigation.gd")
var depth_root: Node2D
var layered := false
var fixtures: Dictionary = {}
var actors: Dictionary = {}
var population_actors: Array = []
var seating := false
var seating_tween: Tween
var target_visuals: Dictionary = {}
var scene_config: Dictionary = {}
var exit_position := Vector2(1080,550)
var quest_step := 0
var optional_seen: Array = []
var npc_art: Array[Texture2D] = []
var prop_art: Dictionary = {}
var phone_ui: Control
var phone_labels: Array[Label] = []
var phone_scroll: ScrollContainer
var phone_stack: VBoxContainer
var phone_revision := 0
var location: String = "debate"
var outfit: String = "formal"
var player_position := Vector2(230, 520)
var companion_position := Vector2(805, 490)
var active := true
var completed := false
var moving := false
var direction := 0
var clock := 0.0
var sprites: Dictionary = {}
var background: Texture2D
var blockers: Array[Rect2] = []
var interaction_label := "Hablar"
var scene_id := ""
var seated := false
var dancing := false
var effect := ""
var effect_time := 0.0
var waiter_actor: Node2D
var waiter_tween: Tween

func challenge_reaction(kind: String, points: int) -> void:
	var text:=Label.new();text.text="Comité: ¡buena intervención!" if kind=="debate" and points==2 else "Guillermo: hmm…" if points==0 else "¡Bien, Anami!"
	text.position=Vector2(650,230);text.add_theme_font_size_override("font_size",22);text.modulate=Color("ebc48a");add_child(text)
	var tween:=create_tween();tween.tween_property(text,"position:y",200.0,.5);tween.tween_property(text,"modulate:a",0.0,.8);tween.tween_callback(text.queue_free)

func waiter_movement(approach: bool) -> void:
	if is_instance_valid(waiter_tween):waiter_tween.kill()
	if not is_instance_valid(waiter_actor):
		waiter_actor=MemoryActor.new();waiter_actor.world=self;waiter_actor.npc=true
		if npc_art.size()>4:waiter_actor.texture=npc_art[4]
		waiter_actor.position=Vector2(1130,530) if approach else Vector2(1030,430)
		if is_instance_valid(depth_root):depth_root.add_child(waiter_actor)
		else:add_child(waiter_actor)
	waiter_tween=create_tween();waiter_tween.tween_property(waiter_actor,"position",Vector2(1030,430) if approach else Vector2(1130,530),1.0)
	if not approach:waiter_tween.tween_callback(waiter_actor.queue_free)
var phone_messages: Array = []

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for person in ["anami", "guillermo"]:
		var path: String="res://assets/art/sprites-v2/%s_%s.png" % [person,outfit]
		if not ResourceLoader.exists(path):path="res://assets/art/sprites/%s_%s.png" % [person,outfit]
		sprites[person] = load(path)
	var background_name: String="party" if location=="pool" else location
	var art_path := "res://assets/art/backgrounds/%s.png" % background_name
	if ResourceLoader.exists(art_path):
		background = load(art_path)
	match location:
		"debate": blockers = [Rect2(315,275,170,55),Rect2(560,275,170,55),Rect2(315,460,170,55),Rect2(560,460,170,55)]
		"dining": blockers = [Rect2(370,270,140,90),Rect2(595,460,140,70)]
		"ikura": blockers = [Rect2(365,270,140,75),Rect2(585,440,135,60)]
		"kitchen": blockers = [Rect2(200,250,450,55)]
		"pool", "party": blockers = [Rect2(870,200,270,155)]
		_: blockers = []
	if background:
		match location:
			"debate":blockers=[Rect2(60,250,448,190),Rect2(780,250,415,190)]
			"dining":blockers=[Rect2(50,150,180,210),Rect2(340,165,190,140),Rect2(660,240,150,130),Rect2(760,140,185,140),Rect2(990,140,180,180)]
			"auditorium":blockers=[Rect2(100,170,470,220),Rect2(700,170,480,220)]
			"ikura":blockers=[Rect2(40,260,205,240),Rect2(1030,260,205,240),Rect2(360,140,610,175)]
			"kitchen":blockers=[Rect2(180,160,1020,155),Rect2(40,310,130,245)]
			"party","pool":blockers=[Rect2(800,120,415,190)]
			_:pass
	if scene_config.has("spawn"):player_position=_point(scene_config.spawn)
	if scene_config.has("companion"):companion_position=_point(scene_config.companion)
	exit_position=_point(scene_config.get("exit",[1080,550]))
	for i in range(8):
		var path: String="res://assets/art/overhaul/npc_%d.png" % i
		if ResourceLoader.exists(path):npc_art.append(load(path))
	if location=="yacht":blockers=[Rect2(110,225,1080,120)]
	_build_layers()
	if location=="phone":_build_phone()
	_register_target_visuals()
	queue_redraw()

func _build_layers() -> void:
	depth_root=Node2D.new();depth_root.y_sort_enabled=true;add_child(depth_root)
	var layouts: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/room_layouts.json"))
	layered=layouts.has(location)
	if layered:
		background=null;blockers.clear()
		var room: Node2D=RoomLayer.new();room.location=location;room.z_index=-10;add_child(room)
		for entry in layouts[location].fixtures:
			var fixture: Node2D=RoomFixture.new();fixture.kind=entry.kind;fixture.variant=location;fixture.label=entry.get("label","");fixture.width=float(entry.get("width",180));fixture.decor=entry.get("decor",[])
			fixture.position=_point(entry.position);depth_root.add_child(fixture);fixtures[entry.id]=fixture
			if entry.has("collision"):
				var c: Array=entry.collision;blockers.append(Rect2(fixture.position+Vector2(c[0],c[1]),Vector2(c[2],c[3])))
	for person in ["anami","guillermo"]:
		var actor: Node2D=MemoryActor.new();actor.world=self;actor.person=person;actor.texture=sprites[person];depth_root.add_child(actor);actors[person]=actor
		if person=="guillermo":actor.visible=location not in ["phone","yacht"]
	for i in range(scene_config.get("npcs",[]).size()):
		var entry: Dictionary=scene_config.npcs[i]
		if int(entry.sprite)>=npc_art.size():continue
		var actor: Node2D=MemoryActor.new();actor.world=self;actor.npc=true;actor.texture=npc_art[int(entry.sprite)];actor.position=_point(entry.position);actor.seated=entry.get("seated",false);actor.idle_phase=i
		depth_root.add_child(actor);population_actors.append({"actor":actor,"data":entry})
		if layered and actor.seated:
			var chair: Node2D=RoomFixture.new();chair.kind="chair";chair.variant=location;chair.position=actor.position;depth_root.add_child(chair);depth_root.move_child(chair,0)
	_update_actors()

func _update_actors() -> void:
	if actors.is_empty():return
	actors.anami.position=player_position;actors.anami.row=direction;actors.anami.column=(int(clock*8)%4) if moving or dancing else 0;actors.anami.seated=seated
	actors.guillermo.position=companion_position;actors.guillermo.column=(int(clock*4)%4) if dancing else 0
	actors.guillermo.seated=location in ["dining","beach","pool"] or (location=="ikura" and seated)
	for entry in population_actors:
		var npc: Dictionary=entry.data;var actor: Node2D=entry.actor
		var base:=_point(npc.position);var offset:=Vector2(roundf(sin(clock*.65+actor.idle_phase)*float(npc.get("walk",0))),0)
		actor.position=base+offset if can_stand(base+offset) else base

func seat_couple(on_done: Callable) -> void:
	if seating:return
	active=false;seating=true
	var destination:=_point(scene_config.get("seat",[companion_position.x-55,companion_position.y]))
	if DisplayServer.get_name()=="headless":
		player_position=destination;seated=true;seating=false;_update_actors();on_done.call();return
	seating_tween=create_tween()
	var nav: RefCounted=Navigation.new();nav.scan(self)
	var route: Array=nav.path_to(destination)
	if route.is_empty():
		seating=false;active=true;seating_tween.kill();return
	var previous:=player_position
	for waypoint in route:
		var distance: float=previous.distance_to(waypoint)
		if distance<.1:continue
		seating_tween.tween_method(func(p: Vector2):move_by(p-player_position);moving=true;direction=0;_update_actors(),previous,waypoint,maxf(.02,distance/180.0))
		previous=waypoint
	seating_tween.tween_callback(func():seated=true;moving=false;_update_actors())
	seating_tween.tween_interval(.25)
	seating_tween.tween_callback(func():seating=false;on_done.call())

func restore_pose() -> void:
	if seated and location in ["ikura","dining"]:
		seated=true;player_position=_point(scene_config.seat)
	_update_actors()

func all_targets() -> Array:
	var result: Array=scene_config.get("steps",[]).duplicate(true)
	if result.is_empty():result.append(mandatory_target())
	result.append_array(scene_config.get("optional",[]).duplicate(true))
	result.append({"id":"exit","label":"Siguiente recuerdo","position":[exit_position.x,exit_position.y],"visual":scene_config.get("exit_visual",{})})
	return result

func _register_target_visuals() -> void:
	for target in all_targets():
		var prop: Node2D=InteractionProp.new()
		prop.descriptor=target.get("visual",{}).duplicate(true)
		prop.interaction_radius=INTERACTION_RADIUS
		prop.position=_point(target.position)
		prop.name="Target_"+str(target.id)
		prop.required=target.id=="exit" or target.id in scene_config.get("steps",[]).map(func(t: Dictionary):return t.id)
		depth_root.add_child(prop);target_visuals[target.id]=prop
		if prop.descriptor.has("fixture"):
			prop.environment_object=fixtures.get(prop.descriptor.fixture)
		if prop.visual_kind=="npc":
			var actor: Node2D=MemoryActor.new();actor.world=self;actor.npc=true;actor.texture=prop.texture
			for entry in population_actors:
				if entry.actor.position.distance_to(prop.position)<1:
					actor.seated=entry.actor.seated;entry.actor.visible=false
			prop.add_child(actor);prop.actor_visual=actor
	_sync_target_visuals()

func _sync_target_visuals() -> void:
	var current: String="exit" if completed else str(mandatory_target().id)
	for id in target_visuals:
		var prop: Node2D=target_visuals[id]
		prop.enabled=id==current
		prop.visible=id!="exit" or completed
		if prop.visual_kind=="companion":prop.visible=location not in ["phone","yacht"]

func has_target_visual(id: String) -> bool:
	if not target_visuals.has(id):return false
	var prop: Node2D=target_visuals[id]
	if prop.visual_kind=="companion":
		return sprites.has("guillermo") and location not in ["phone","yacht"] and prop.position.distance_to(companion_position)<1
	return prop.has_representation()

func _point(value: Array) -> Vector2:
	return Vector2(value[0],value[1])

func mandatory_target() -> Dictionary:
	var steps: Array=scene_config.get("steps",[])
	if quest_step<steps.size():return steps[quest_step]
	return {"id":"main","label":interaction_label,"position":[companion_position.x,companion_position.y]}

func interaction_targets() -> Array:
	var result: Array=scene_config.get("optional",[]).duplicate()
	if completed:result.append({"id":"exit","label":"Siguiente recuerdo","position":[exit_position.x,exit_position.y],"visual":scene_config.get("exit_visual",{})})
	else:result.append(mandatory_target())
	return result

func nearest_target() -> Dictionary:
	var best: Dictionary={}
	var distance:=INTERACTION_RADIUS
	for target in interaction_targets():
		var d:=player_position.distance_to(_point(target.position))
		if d<distance:distance=d;best=target
	return best

func prompt() -> String:
	var target:=nearest_target()
	return "E · "+str(target.label) if not target.is_empty() else ""

func can_stand(p: Vector2) -> bool:
	if not WALK_BOUNDS.has_point(p):return false
	var feet:=Rect2(p-PLAYER_HALF,PLAYER_HALF*2)
	for area in blockers:
		if area.intersects(feet):return false
	return true

func safe_position(p: Vector2) -> Vector2:
	if can_stand(p):return p
	var best:=Vector2(265,550)
	var distance:=INF
	for x in range(110,1190,10):
		for y in range(225,580,10):
			var candidate:=Vector2(x,y)
			if can_stand(candidate) and p.distance_squared_to(candidate)<distance:
				best=candidate;distance=p.distance_squared_to(candidate)
	return best

func move_by(step: Vector2) -> void:
	# Substeps use exactly the same feet rectangle and bounds as navigation QA.
	var count:=maxi(1,int(ceil(step.length()/4.0)))
	var part:=step/float(count)
	for i in range(count):
		var next:=player_position+Vector2(part.x,0)
		if can_stand(next):player_position=next
		next=player_position+Vector2(0,part.y)
		if can_stand(next):player_position=next

func _process(delta: float) -> void:
	clock += delta
	_sync_target_visuals()
	effect_time=maxf(0,effect_time-delta)
	moving = false
	if active:
		var motion := Vector2(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W)))
		if motion.length_squared() > 0:
			moving = true
			direction = 2 if motion.x > 0 else 1 if motion.x < 0 else 3 if motion.y < 0 else 0
			var step := motion.normalized() * 205.0 * delta
			move_by(step)
			if seated:seated=false
	_update_actors()
	# Chat messages arrive complete; dialogue retains its own paced reveal.
	# Revealing inside a pre-shaped long bubble would scroll into blank text.
	queue_redraw()

func _blocked(p: Vector2) -> bool:
	return not can_stand(p)

func interact() -> void:
	if not active: return
	var target:=nearest_target()
	if target.is_empty():return
	if target.id=="exit":
		exited.emit()
	elif target.id=="main":
		interacted.emit()
	else:target_interacted.emit(target.id)

func _tile(rect: Rect2, base: Color, grain: Color, size: int = 32) -> void:
	draw_rect(rect,base)
	for x in range(int(rect.position.x),int(rect.end.x),size):
		for y in range(int(rect.position.y),int(rect.end.y),size):
			draw_rect(Rect2(x,y,size-1,size-1),grain,false,1)

func _furniture(pos: Vector2, kind: String) -> void:
	match kind:
		"desk":
			draw_rect(Rect2(pos+Vector2(4,8),Vector2(145,50)),Color("182432"))
			draw_rect(Rect2(pos,Vector2(145,40)),Color("aa8666"))
			draw_rect(Rect2(pos+Vector2(3,3),Vector2(139,5)),Color("dcc19a"))
			draw_rect(Rect2(pos+Vector2(14,13),Vector2(22,16)),Color("f2e7c6"))
		"plant":
			draw_rect(Rect2(pos+Vector2(-14,0),Vector2(28,25)),Color("b27863"))
			for i in range(5): draw_rect(Rect2(pos+Vector2(-22+i*8,-36+abs(2-i)*7),Vector2(15,32)),Color("56836f"))
		"table":
			draw_circle(pos+Vector2(3,8),66,Color("243442"))
			draw_circle(pos,64,Color("e3dac0"))
			draw_circle(pos,12,Color("649c83"))
			for off in [Vector2(-83,0),Vector2(83,0),Vector2(0,-80),Vector2(0,80)]:
				draw_rect(Rect2(pos+off-Vector2(16,18),Vector2(32,36)),Color("e2d3b1"))

func _sprite(person: String, pos: Vector2, row: int, column: int) -> void:
	if not sprites.has(person): return
	draw_ellipse_shadow(pos)
	var snapped := Vector2(roundf(pos.x/2)*2,roundf(pos.y/2)*2)
	var sitting: bool=(location in ["beach","pool"] and (person=="guillermo" or seated)) or (location in ["dining","ikura"] and seated)
	if sitting:
		draw_texture_rect_region(sprites[person],Rect2(snapped-Vector2(32,66),Vector2(64,70)),Rect2(column*32,row*48,32,35))
	else:
		draw_texture_rect_region(sprites[person],Rect2(snapped-Vector2(32,90),Vector2(64,96)),Rect2(column*32,row*48,32,48))

func apply_line(speaker: String, text: String) -> void:
	if location in ["phone","yacht"]:
		if speaker!="Narrador":
			phone_messages.append({"speaker":speaker,"text":text,"time":clock})
			if phone_messages.size()>100:phone_messages.pop_front()
			if is_instance_valid(phone_ui) and phone_ui.visible:_refresh_phone()
	if scene_id=="foot" and (text.contains("aterrizó") or text=="¡Ay!"):
		player_position=companion_position+Vector2(-38,0)
		effect="ouch";effect_time=1.5
	if text.contains("Anami kisses") or text.contains("besó") or text.contains("beso"):
		effect="heart";effect_time=2.5
	if scene_id=="award" and speaker=="Anami":effect="diploma";effect_time=3
	if scene_id=="pool" and (text.contains("novia") or text.contains("quiero")):
		seated=true;player_position=companion_position+Vector2(-48,0)

func draw_ellipse_shadow(pos: Vector2) -> void:
	draw_rect(Rect2(pos+Vector2(-23,-3),Vector2(46,9)),Color(0.07,0.1,0.16,.3))

func _draw() -> void:
	if layered:pass
	elif background:
		draw_texture_rect(background,Rect2(0,0,1280,720),false)
	else:
		_draw_room()
	if location=="yacht":_draw_yacht()
	if not layered:_draw_population()
	if location in ["beach","party","pool"]:
		for i in range(18):
			var p := Vector2(fmod(i*89+clock*6,1280),140+sin(clock*.2+i)*50)
			draw_rect(Rect2(p,Vector2(3,3)),Color(1,.85,.6,.35))
	if location == "beach":
		for i in range(10):
			draw_line(Vector2(i*145+sin(clock+i)*15,350+i%3*10),Vector2(i*145+85+sin(clock+i)*15,350+i%3*10),Color(1,.83,.64,.35),2)
	# Actors are children of depth_root, interleaved with the furniture by ground Y.
	if effect_time>0:
		if effect=="ouch":
			draw_string(ThemeDB.fallback_font,player_position+Vector2(-10,-100),"¡AY!",HORIZONTAL_ALIGNMENT_LEFT,-1,28,Color("f5c58b"))
		elif effect=="heart":
			var center:=player_position+Vector2(15,-105-(2.5-effect_time)*12)
			draw_rect(Rect2(center-Vector2(8,0),Vector2(6,6)),Color("d56581"));draw_rect(Rect2(center,Vector2(6,6)),Color("d56581"));draw_rect(Rect2(center-Vector2(6,-6),Vector2(10,4)),Color("d56581"));draw_rect(Rect2(center-Vector2(3,-10),Vector2(4,4)),Color("d56581"))
		elif effect=="diploma":
			draw_texture_rect(load("res://assets/art/sprites/diploma.png"),Rect2(player_position+Vector2(20,-45),Vector2(40,40)),false)
	for item in interaction_targets():
		var target:=_point(item.position)
		var required: bool=item.id=="exit" or item.id==mandatory_target().id
		var color:=Color("ffe1a0") if required else Color("9fbfbd")
		draw_arc(target+Vector2(0,3),19 if required else 12,0,TAU,16,Color(color,.7+sin(clock*3)*.15),2)
		if required:draw_string(ThemeDB.fallback_font,target+Vector2(-8,-100),"↓",HORIZONTAL_ALIGNMENT_LEFT,-1,23,color)
		elif not optional_seen.has(item.id):draw_string(ThemeDB.fallback_font,target+Vector2(-4,-85),"…",HORIZONTAL_ALIGNMENT_LEFT,-1,19,color)
	var text:=prompt()
	if text!="":
		draw_rect(Rect2(335,600,610,45),Color("152331"))
		draw_string(ThemeDB.fallback_font,Vector2(355,630),text,HORIZONTAL_ALIGNMENT_LEFT,570,21,Color("ffe1a0"))

func _build_phone() -> void:
	phone_ui=PanelContainer.new();phone_ui.position=Vector2(355,145);phone_ui.size=Vector2(580,305)
	phone_ui.mouse_filter=Control.MOUSE_FILTER_STOP;phone_ui.z_index=20;add_child(phone_ui)
	var style:=StyleBoxFlat.new();style.bg_color=Color("142331");style.border_color=Color("aa936f");style.set_border_width_all(4);style.set_content_margin_all(12);phone_ui.add_theme_stylebox_override("panel",style)
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",8);phone_ui.add_child(column)
	var header:=Label.new();header.text="MENSAJES · "+("Guillermo" if scene_id=="reconnect" else "Conversación");header.add_theme_font_size_override("font_size",20);header.add_theme_color_override("font_color",Color("ebc48a"));column.add_child(header)
	phone_scroll=ScrollContainer.new();phone_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;phone_scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;phone_scroll.custom_minimum_size.y=230;phone_scroll.focus_mode=Control.FOCUS_ALL;column.add_child(phone_scroll)
	phone_stack=VBoxContainer.new();phone_stack.size_flags_horizontal=Control.SIZE_EXPAND_FILL;phone_stack.add_theme_constant_override("separation",10);phone_scroll.add_child(phone_stack)
	_refresh_phone()

func show_phone(value: bool) -> void:
	if value and not is_instance_valid(phone_ui):_build_phone()
	if is_instance_valid(phone_ui):phone_ui.visible=value

func scroll_phone(key: int) -> void:
	if not is_instance_valid(phone_scroll):return
	if key==KEY_HOME:phone_scroll.scroll_vertical=0
	elif key==KEY_END:phone_scroll.scroll_vertical=int(phone_scroll.get_v_scroll_bar().max_value)
	else:phone_scroll.scroll_vertical+=-170 if key==KEY_PAGEUP else 170

func _refresh_phone() -> void:
	if not is_instance_valid(phone_stack):return
	phone_revision+=1
	for child in phone_stack.get_children():phone_stack.remove_child(child);child.queue_free()
	phone_labels.clear()
	for item in phone_messages:
		var outgoing: bool=item.speaker=="Anami"
		var row:=HBoxContainer.new();row.size_flags_horizontal=Control.SIZE_EXPAND_FILL;phone_stack.add_child(row)
		var spacer:=Control.new();spacer.custom_minimum_size.x=36
		if outgoing:row.add_child(spacer)
		var bubble:=PanelContainer.new();bubble.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(bubble)
		var style:=StyleBoxFlat.new();style.bg_color=Color("426764") if outgoing else Color("30475c");style.set_corner_radius_all(5);style.set_content_margin_all(12);bubble.add_theme_stylebox_override("panel",style)
		var column:=VBoxContainer.new();column.add_theme_constant_override("separation",4);bubble.add_child(column)
		var sender:=Label.new();sender.text=item.speaker+" · "+("enviado" if outgoing else "recibido");sender.add_theme_font_size_override("font_size",14);sender.add_theme_color_override("font_color",Color("ebc48a"));column.add_child(sender)
		var content:=Label.new();content.text=item.text;content.visible_characters_behavior=TextServer.VC_GLYPHS_AUTO;content.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;content.size_flags_horizontal=Control.SIZE_EXPAND_FILL;content.add_theme_font_size_override("font_size",18);column.add_child(content);phone_labels.append(content)
		if not outgoing:row.add_child(spacer)
	_scroll_latest.call_deferred(phone_revision)

func _scroll_latest(revision: int) -> void:
	if not is_inside_tree():return
	await get_tree().process_frame
	if not is_inside_tree():return
	await get_tree().process_frame
	if is_instance_valid(phone_scroll) and revision==phone_revision:
		phone_scroll.scroll_vertical=int(phone_scroll.get_v_scroll_bar().max_value)

func _draw_population() -> void:
	var npcs: Array=scene_config.get("npcs",[])
	if location=="debate":
		for item in npcs:
			var p:=_point(item.position)
			if item.get("seated",false):
				draw_rect(Rect2(p+Vector2(-30,3),Vector2(60,17)),Color("ede0be"))
				draw_string(ThemeDB.fallback_font,p+Vector2(-25,16),item.name,HORIZONTAL_ALIGNMENT_LEFT,60,11,Color("243340"))
				_draw_prop("conference",p+Vector2(38,0),32)
		# Speaking area is in the open central aisle, not on the seating tiers.
		draw_rect(Rect2(600,360,80,15),Color("a2835d"))
		draw_rect(Rect2(630,375,18,28),Color("725a46"))
	if location=="ikura":
		_draw_prop("lantern",Vector2(315,265),48)
		_draw_prop("lantern",Vector2(995,265),48)
		for p in [Vector2(145,325),Vector2(1130,365)]:_draw_prop("sushi",p,48)
		if seated:
			_draw_prop("gyozas",Vector2(775,430),48)
			_draw_prop("ramen",Vector2(845,425),40)
			_draw_prop("sushi",Vector2(705,425),40)
		# A passing tray and quiet kettle steam give the counter some activity.
		_draw_prop("gyozas",Vector2(980+roundf(sin(clock*.65)*20),465),32)
		for i in range(3):
			draw_rect(Rect2(Vector2(845+i*5,390-fmod(clock*12+i*10,25)),Vector2(2,5)),Color(1,1,.9,.35))

func _draw_prop(id: String, pos: Vector2, size: float) -> void:
	var path: String="res://assets/art/overhaul/%s.png" % id
	# Keep textures alive until the render server consumes the drawing commands.
	if not prop_art.has(id) and ResourceLoader.exists(path):prop_art[id]=load(path)
	if prop_art.has(id):draw_texture_rect(prop_art[id],Rect2(pos-Vector2(size/2,size/2),Vector2(size,size)),false)

func _draw_yacht() -> void:
	if background:return
	draw_rect(Rect2(0,0,1280,345),Color("558a9a"))
	_tile(Rect2(0,345,1280,375),Color("d0b992"),Color("c5ac87"),48)
	for i in range(9):
		draw_line(Vector2(i*150+sin(clock+i)*6,290),Vector2(i*150+70+sin(clock+i)*6,290),Color("b4d3cf"),2)
	draw_rect(Rect2(0,335,1280,12),Color("e2d4b3"))

func _draw_room() -> void:
	draw_rect(Rect2(0,0,1280,720),Color("162a38"))
	if location == "beach":
		for i in range(18): draw_rect(Rect2(0,i*20,1280,20),Color("d78f7c").lerp(Color("655780"),float(i)/18))
		draw_circle(Vector2(780,260),55,Color("ffe0a2"))
		draw_rect(Rect2(0,330,1280,160),Color("647f9b"))
		_tile(Rect2(0,440,1280,280),Color("d8bc91"),Color("d1ad85"),64)
		return
	var floor_color := Color("8f7764")
	if location in ["party","pool"]: floor_color = Color("3e665c")
	_tile(Rect2(85,200,1110,390),floor_color,floor_color.lightened(.09),48)
	draw_rect(Rect2(70,108,1140,95),Color("d3c7ac"))
	draw_rect(Rect2(70,186,1140,15),Color("9b7f69"))
	for x in [150,460,900]:
		draw_rect(Rect2(x,118,170,58),Color("6c99aa"))
		draw_rect(Rect2(x+80,118,8,58),Color("d8cbb0"))
		draw_rect(Rect2(x,144,170,6),Color("d8cbb0"))
	_furniture(Vector2(142,255),"plant")
	_furniture(Vector2(1140,245),"plant")
	match location:
		"debate":
			for p in [Vector2(315,275),Vector2(560,275),Vector2(315,460),Vector2(560,460)]: _furniture(p,"desk")
			draw_rect(Rect2(800,117,245,60),Color("243b4d"))
			draw_string(ThemeDB.fallback_font,Vector2(870,157),"UEES · MUN",HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("e6c590"))
		"dining", "ikura":
			for p in [Vector2(440,320),Vector2(650,495),Vector2(910,280)]: _furniture(p,"table")
			if location == "ikura":
				for x in range(150,1100,150):
					draw_rect(Rect2(x,105,25,65),Color("c07862")); draw_rect(Rect2(x+3,130,19,4),Color("f5d49c"))
		"auditorium":
			for y in [260,335,485]:
				for x in range(230,1000,85): draw_rect(Rect2(x,y,45,45),Color("c5bdad"))
		"party", "pool":
			draw_rect(Rect2(870,200,270,155),Color("bfbbaa")); draw_rect(Rect2(890,217,230,120),Color("507d98"))
			for x in range(180,820,85): draw_circle(Vector2(x,180+sin(x)*12),5,Color("ecb685"))
		"kitchen":
			for x in range(200,640,80):
				draw_rect(Rect2(x,230,78,76),Color("dccbae"));draw_rect(Rect2(x+10,240,58,45),Color("ad8970"))
			_furniture(Vector2(550,410),"table")
		"phone":
			draw_rect(Rect2(320,230,340,90),Color("c1bda4")); draw_rect(Rect2(520,244,38,60),Color("263e54"))
		_: pass
