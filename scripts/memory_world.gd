extends Node2D
## Small top-down memory stage. Artwork and animations use nearest filtering.
signal interacted
signal exited
signal target_interacted(id: String)
const INTERACTION_RADIUS := 72.0
const PLAYER_HALF := Vector2(10, 6)
const WALK_BOUNDS := Rect2(110,225,1080,355)
const InteractionProp = preload("res://scripts/interaction_prop.gd")
var target_visuals: Dictionary = {}
var scene_config: Dictionary = {}
var exit_position := Vector2(1080,550)
var quest_step := 0
var optional_seen: Array = []
var npc_art: Array[Texture2D] = []
var prop_art: Dictionary = {}
var phone_ui: Control
var phone_labels: Array[Label] = []
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
	if location=="phone":_build_phone()
	_register_target_visuals()
	queue_redraw()

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
		add_child(prop);target_visuals[target.id]=prop
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
	for i in range(phone_labels.size()):
		phone_labels[i].visible_characters=int((clock-phone_messages[i].get("time",0))*40)
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
			if phone_messages.size()>2:phone_messages.pop_front()
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
	if background:
		draw_texture_rect(background,Rect2(0,0,1280,720),false)
	else:
		_draw_room()
	if location=="yacht":_draw_yacht()
	_draw_population()
	if location in ["beach","party","pool"]:
		for i in range(18):
			var p := Vector2(fmod(i*89+clock*6,1280),140+sin(clock*.2+i)*50)
			draw_rect(Rect2(p,Vector2(3,3)),Color(1,.85,.6,.35))
	if location == "beach":
		for i in range(10):
			draw_line(Vector2(i*145+sin(clock+i)*15,350+i%3*10),Vector2(i*145+85+sin(clock+i)*15,350+i%3*10),Color(1,.83,.64,.35),2)
	if location not in ["phone","yacht"]:_sprite("guillermo",companion_position,0,(int(clock*4)%4) if dancing else 0)
	_sprite("anami",player_position,direction,(int(clock*8)%4) if moving or dancing else 0)
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

func _draw_phone() -> void:
	draw_rect(Rect2(370,140,540,310),Color("1d293d"))
	draw_rect(Rect2(385,157,510,45),Color("33485b"))
	draw_string(ThemeDB.fallback_font,Vector2(410,187),"MENSAJES · Moncayo",HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color("f1d2a0"))
	for i in range(phone_messages.size()):
		var item: Dictionary=phone_messages[i]
		draw_rect(Rect2(393,218+i*72,490,64),Color("364c60") if item.speaker=="Guillermo" else Color("566b71"))
		draw_string(ThemeDB.fallback_font,Vector2(407,240+i*72),item.speaker,HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("f1d2a0"))
		var excerpt: String=item.text.left(52)+("…" if item.text.length()>52 else "")
		draw_string(ThemeDB.fallback_font,Vector2(407,268+i*72),excerpt,HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("f5ead6"))

func _build_phone() -> void:
	phone_ui=Control.new();phone_ui.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(phone_ui)
	_refresh_phone()

func show_phone(value: bool) -> void:
	if value and not is_instance_valid(phone_ui):_build_phone()
	if is_instance_valid(phone_ui):phone_ui.visible=value

func _refresh_phone() -> void:
	if not is_instance_valid(phone_ui):return
	for child in phone_ui.get_children():phone_ui.remove_child(child);child.queue_free()
	phone_labels.clear()
	var frame:=ColorRect.new();frame.color=Color("142331");frame.position=Vector2(360,155);frame.size=Vector2(570,295);frame.mouse_filter=Control.MOUSE_FILTER_IGNORE;phone_ui.add_child(frame)
	var header:=Label.new();header.text="MENSAJES · "+("Guillermo" if scene_id=="reconnect" else "Conversación");header.position=Vector2(385,165);header.add_theme_font_size_override("font_size",20);header.add_theme_color_override("font_color",Color("ebc48a"));phone_ui.add_child(header)
	for i in range(phone_messages.size()):
		var item: Dictionary=phone_messages[i]
		var outgoing: bool=item.speaker=="Anami"
		var bubble:=ColorRect.new();bubble.color=Color("426764") if outgoing else Color("30475c");bubble.position=Vector2(410 if outgoing else 378,204+i*116);bubble.size=Vector2(495,108);bubble.mouse_filter=Control.MOUSE_FILTER_IGNORE;phone_ui.add_child(bubble)
		var sender:=Label.new();sender.text=item.speaker+" · "+("enviado" if outgoing else "recibido");sender.position=bubble.position+Vector2(10,4);sender.add_theme_font_size_override("font_size",15);sender.add_theme_color_override("font_color",Color("ebc48a"));phone_ui.add_child(sender)
		var content:=Label.new();content.text=item.text;content.position=bubble.position+Vector2(10,28);content.size=Vector2(475,74);content.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;content.add_theme_font_size_override("font_size",18);phone_ui.add_child(content);phone_labels.append(content)

func _draw_population() -> void:
	var npcs: Array=scene_config.get("npcs",[])
	for i in range(npcs.size()):
		var npc: Dictionary=npcs[i]
		var pos:=_point(npc.position)
		var registered:=false
		for prop in target_visuals.values():
			if prop.visual_kind=="npc" and prop.position.distance_to(pos)<1:registered=true;break
		if registered:continue
		var walk: float=float(npc.get("walk",0))
		var offset:=Vector2(sin(clock*.65+i)*walk,0)
		if walk>0 and can_stand(pos+offset):pos+=offset
		var sprite_index:=int(npc.sprite)
		if sprite_index<npc_art.size():
			var size:=Vector2(64,70) if npc.get("seated",false) else Vector2(64,96)
			var nod:=2.0 if int(clock+i)%7==0 else 0.0
			if walk>0:nod=roundf(sin(clock*5+i))*2
			draw_texture_rect(npc_art[sprite_index],Rect2(pos-Vector2(32,size.y-5+nod),size),false)
			if location=="debate" and int(clock+i*2)%11==0:
				draw_rect(Rect2(pos+Vector2(24,-42),Vector2(6,14)),Color("d9b78e"))
		if int(clock*.4+i)%9==0:
			draw_string(ThemeDB.fallback_font,pos+Vector2(-10,-105),"…",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("d6e2cd"))
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
