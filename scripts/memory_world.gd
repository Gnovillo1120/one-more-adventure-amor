extends Node2D
## Small top-down memory stage. Artwork and animations use nearest filtering.
signal interacted
signal exited
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
	queue_redraw()

func _process(delta: float) -> void:
	clock += delta
	effect_time=maxf(0,effect_time-delta)
	moving = false
	if active:
		var motion := Vector2(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W)))
		if motion.length_squared() > 0:
			moving = true
			direction = 2 if motion.x > 0 else 1 if motion.x < 0 else 3 if motion.y < 0 else 0
			var step := motion.normalized() * 205.0 * delta
			var next := player_position + Vector2(step.x,0)
			if not _blocked(next): player_position.x = clampf(next.x,110,1190)
			next = player_position + Vector2(0,step.y)
			if not _blocked(next): player_position.y = clampf(next.y,225,560)
	queue_redraw()

func _blocked(p: Vector2) -> bool:
	for area in blockers:
		if area.grow(10).has_point(p): return true
	return false

func interact() -> void:
	if not active: return
	if completed and player_position.distance_to(Vector2(1145,410)) < 85:
		exited.emit()
	elif not completed and player_position.distance_to(companion_position) < 95:
		interacted.emit()

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
	var sitting: bool=(location in ["beach","pool"] and (person=="guillermo" or seated)) or (location=="dining" and seated)
	if sitting:
		draw_texture_rect_region(sprites[person],Rect2(snapped-Vector2(32,66),Vector2(64,70)),Rect2(column*32,row*48,32,35))
	else:
		draw_texture_rect_region(sprites[person],Rect2(snapped-Vector2(32,90),Vector2(64,96)),Rect2(column*32,row*48,32,48))

func apply_line(speaker: String, text: String) -> void:
	if location=="phone":
		phone_messages.append({"speaker":speaker,"text":text})
		if phone_messages.size()>3:phone_messages.pop_front()
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
	if location=="phone": _draw_phone()
	if location in ["beach","party","pool"]:
		for i in range(18):
			var p := Vector2(fmod(i*89+clock*6,1280),140+sin(clock*.2+i)*50)
			draw_rect(Rect2(p,Vector2(3,3)),Color(1,.85,.6,.35))
	if location == "beach":
		for i in range(10):
			draw_line(Vector2(i*145+sin(clock+i)*15,350+i%3*10),Vector2(i*145+85+sin(clock+i)*15,350+i%3*10),Color(1,.83,.64,.35),2)
	_sprite("guillermo",companion_position,0,(int(clock*4)%4) if dancing else 0)
	_sprite("anami",player_position,direction,(int(clock*8)%4) if moving or dancing else 0)
	if effect_time>0:
		if effect=="ouch":
			draw_string(ThemeDB.fallback_font,player_position+Vector2(-10,-100),"¡AY!",HORIZONTAL_ALIGNMENT_LEFT,-1,28,Color("f5c58b"))
		elif effect=="heart":
			var center:=player_position+Vector2(15,-105-(2.5-effect_time)*12)
			draw_rect(Rect2(center-Vector2(8,0),Vector2(6,6)),Color("d56581"));draw_rect(Rect2(center,Vector2(6,6)),Color("d56581"));draw_rect(Rect2(center-Vector2(6,-6),Vector2(10,4)),Color("d56581"));draw_rect(Rect2(center-Vector2(3,-10),Vector2(4,4)),Color("d56581"))
		elif effect=="diploma":
			draw_texture_rect(load("res://assets/art/sprites/diploma.png"),Rect2(player_position+Vector2(20,-45),Vector2(40,40)),false)
	var target := Vector2(1145,410) if completed else companion_position
	var distance := player_position.distance_to(target)
	var pulse := .75+sin(clock*4)*.15
	draw_arc(target+Vector2(0,4),30,0,TAU,24,Color(.96,.76,.42,pulse),3)
	draw_string(ThemeDB.fallback_font,target+Vector2(-10,-115),"E" if distance<95 else "↓",HORIZONTAL_ALIGNMENT_LEFT,-1,25,Color("ffe1a0"))
	if completed:
		draw_string(ThemeDB.fallback_font,Vector2(1070,465),"Siguiente recuerdo",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("ffe1a0"))
	elif distance<95:
		draw_string(ThemeDB.fallback_font,companion_position+Vector2(-75,40),interaction_label,HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("fff0cf"))

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
