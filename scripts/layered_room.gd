extends Node2D
## Floor/wall layer only: furniture and actors are independent Y-sorted nodes.
var location := "debate"
var title := ""

func r(x: float,y: float,w: float,h: float,c: String) -> void:draw_rect(Rect2(x,y,w,h),Color(c))

func _draw() -> void:
	r(0,0,1280,720,"162733")
	r(70,110,1140,530,"62594b" if location=="debate" else "bdad8b" if location=="dining" else "704f3d")
	# Original 24px tiles, with deterministic small color differences and seams.
	for x in range(72,1210,24):
		for y in range(220,640,24):
			var tint: String
			if location=="debate":tint=["796e59","80745e","766b58"][(x/24+y/24)%3]
			elif location=="dining":tint=["c9bda0","cdbfa2","c4b598"][(x/24+y/24)%3]
			else:tint=["916747","986f4d","8b6347"][(x/24+y/24)%3]
			r(x,y,22,22,tint)
			if location=="ikura":r(x+2,y+14,16,2,"a77c55")
	r(70,108,1140,110,"6b594a" if location!="dining" else "a9ae9f")
	for x in range(78,1200,48):
		r(x,116,42,92,"88725a" if location=="debate" else "bcbca8" if location=="dining" else "604638")
		r(x+2,118,2,88,"ad9370" if location=="debate" else "cecbb3" if location=="dining" else "896448")
	r(70,212,1140,8,"433e38");r(70,220,1140,6,"d0b27f")
	if location=="debate":
		r(458,114,364,90,"35434b");r(466,120,348,76,"b4c5bb")
		for x in range(490,790,18):r(x,146+((x/18)%3)*6,12,24,"6e9584")
		draw_string(ThemeDB.fallback_font,Vector2(496,139),"UEES · MODELO DE NACIONES UNIDAS",HORIZONTAL_ALIGNMENT_CENTER,290,14,Color("344c51"))
		for x in [118,1046]:
			r(x,118,100,90,"4c6974");r(x+4,122,92,82,"8aa9a9")
			for k in range(3):r(x+6+k*30,122,4,82,"ded7b8")
	elif location=="dining":
		for x in [116,360,604,848]:
			r(x,120,188,84,"798b87");r(x+6,124,176,74,"b4ccc1")
			r(x+86,124,6,74,"e8e3c8");r(x+6,148,176,6,"e8e3c8")
	else:
		for x in range(140,1140,160):
			r(x,122,94,74,"2f3939");r(x+6,128,82,62,"8b7658")
			for k in range(4):r(x+14+k*18,132,4,52,"b8a080")
		draw_string(ThemeDB.fallback_font,Vector2(520,169),"IKURA · いくら",HORIZONTAL_ALIGNMENT_CENTER,230,24,Color("eac793"))
	# Low perimeter wall does not contain duplicated painted furniture.
	r(66,226,6,412,"433b34");r(1208,226,6,412,"433b34")
	r(70,636,1140,8,"463b31");r(70,644,1140,10,"b29266")

