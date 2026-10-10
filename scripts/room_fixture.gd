extends Node2D
## Original pixel furniture. The same footprint feeds movement collision.
var kind := "desk"
var label := ""
var variant := "debate"
var width := 180.0
var footprint := Rect2()
var decor: Array = []
var textures: Dictionary = {}

func _ready() -> void:
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	set_meta("rendered_fixture",true)
	for item in decor:
		var path: String="res://assets/art/overhaul/%s.png" % item
		if ResourceLoader.exists(path):textures[item]=load(path)
	queue_redraw()

func p(x: float,y: float,w: float,h: float,color: String) -> void:
	draw_rect(Rect2(x,y,w,h),Color(color))

func _draw() -> void:
	match kind:
		"desk","table","counter":
			var half:=width/2
			p(-half-4,-18,width+8,30,"292b32")
			p(-half,-62,width,60,"564738")
			p(-half+4,-60,width-8,46,"d4c8a6" if variant=="dining" else "a87b54" if variant=="ikura" else "bcaa83")
			if kind=="table" and variant=="dining":
				# Stepped round linen tables echo the dining reference; dark cloth skirts.
				p(-half,-62,16,60,"b8aa8d");p(half-16,-62,16,60,"b8aa8d")
				p(-half+12,-58,width-24,48,"444b5c");p(-half+24,-66,width-48,12,"ebe0bf")
				p(-half+12,-58,width-24,36,"ddd2af");p(-half+24,-22,width-48,10,"c5b893")
				for x in range(int(-half+28),int(half-24),16):p(x,-12,4,18,"657080")
			p(-half+4,-16,width-8,10,"343e51" if variant=="dining" else "795937")
			p(-half+8,-4,8,16,"393332");p(half-16,-4,8,16,"393332")
			for x in range(int(-half+10),int(half-8),16):
				p(x,-50,10,2,"c1b697" if variant=="dining" else "b79167")
			if kind=="desk":
				p(-half+14,-52,26,18,"f0e3c1")
				for y in [-46,-40]:p(-half+18,y,16,2,"a69b7e")
				p(half-62,-62,36,26,"283c49");p(half-58,-58,28,18,"77a0a6")
				p(half-68,-36,44,6,"536570")
				p(half-16,-54,8,20,"537c9a");p(half-14,-58,4,4,"c5d0c6")
				p(-40,-18,80,16,"ecdfbb")
				draw_string(ThemeDB.fallback_font,Vector2(-38,-6),label,HORIZONTAL_ALIGNMENT_CENTER,76,10,Color("343f49"))
			else:
				# Octagonal place settings use hard pixel edges, not smooth ellipses.
				for x in [-half+30,half-30]:
					p(x-12,-48,24,20,"62717b");p(x-10,-50,20,24,"dfd5b5");p(x-6,-46,12,16,"aea78d")
				p(-10,-50,20,16,"526d56");p(-6,-58,12,12,"719369")
			for i in range(decor.size()):
				var item: String=decor[i]
				if textures.has(item):draw_texture_rect(textures[item],Rect2(-width/2+22+i*48,-58,40,40),false)
		"chair":
			var c: String="d7cbb0" if variant=="dining" else "704d37" if variant=="ikura" else "3b4652"
			p(-20,-66,40,44,"242c35");p(-16,-62,32,28,c)
			for x in [-12,-2,8]:p(x,-58,4,20,"f0e6cd" if variant=="dining" else "59636d")
			p(-20,-30,6,36,c);p(14,-30,6,36,c);p(-16,-20,32,16,c)
			p(-16,-4,6,14,"4c4238");p(10,-4,6,14,"4c4238")
		"plant":
			p(-16,-22,32,22,"986950");p(-20,-26,40,6,"c29b72")
			for i in range(5):
				p(-26+i*10,-50-abs(2-i)*8,12,30,"3f6250");p(-24+i*10,-56-abs(2-i)*8,8,20,"719075")
		"lamp":
			p(-6,-70,12,70,"75533b");p(-20,-78,40,8,"4b3b32");p(-16,-70,32,38,"e6b973")
			for x in [-12,0,12]:p(x,-70,4,38,"ab7b47")
			p(-20,-34,40,6,"6b4b35")
		"exit":
			p(-30,-90,60,90,"735842");p(-24,-84,48,78,"2f4b54");p(-18,-80,36,64,"6d9694")
			p(-2,-80,4,64,"334f56");p(-32,-8,64,8,"cbb788")
			p(-24,-65,48,16,"293c46")
			draw_string(ThemeDB.fallback_font,Vector2(-22,-52),"SALIDA",HORIZONTAL_ALIGNMENT_CENTER,44,12,Color("e9d9ab"))

