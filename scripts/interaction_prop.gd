extends Node2D
## Registered scene object; its ground anchor is the interaction point.
var descriptor: Dictionary = {}
var required := false
var enabled := false
var texture: Texture2D
var time := 0.0
var visual_kind := ""
var interaction_area: Area2D
var interaction_radius := 72.0
var environment_object: Node2D
var actor_visual: Node2D

func _ready() -> void:
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	visual_kind=descriptor.get("kind","")
	var path: String=descriptor.get("art","")
	if path!="" and ResourceLoader.exists(path):texture=load(path)
	interaction_area=Area2D.new();interaction_area.monitoring=false;interaction_area.collision_layer=0;interaction_area.collision_mask=0
	var shape:=CollisionShape2D.new();var circle:=CircleShape2D.new();circle.radius=interaction_radius;shape.shape=circle;interaction_area.add_child(shape);add_child(interaction_area)
	queue_redraw()

func _process(delta: float) -> void:
	time+=delta;queue_redraw()

func has_representation() -> bool:
	if descriptor.has("fixture"):return is_instance_valid(environment_object) and environment_object.get_meta("rendered_fixture",false)
	return texture!=null or visual_kind in ["door","gate","arch","lectern","chair","phone","notice","table","companion","badge","document","letter"]

func _pixel(rect: Rect2, color: String) -> void:draw_rect(rect,Color(color))

func _draw() -> void:
	if descriptor.has("fixture") or is_instance_valid(actor_visual):return
	if visual_kind in ["companion","player"]:return # Registered to the existing animated actor.
	if texture:
		var actor: bool=visual_kind=="npc"
		var size:=Vector2(64,96) if actor else Vector2(48,48)
		var lift:=0.0 if actor or not enabled else roundf(sin(time*2)*2)*2
		draw_texture_rect(texture,Rect2(Vector2(-size.x/2,-size.y+6-lift),size),false)
	else:
		match visual_kind:
			"door","gate","arch":
				_pixel(Rect2(-32,-88,64,88),"44372f")
				_pixel(Rect2(-28,-84,56,80),"aa8257")
				_pixel(Rect2(-20,-76,40,76),"243f48" if enabled else "4d4f52")
				for x in [-16,0,16]:_pixel(Rect2(x,-72,4,68),"78a6a1" if enabled else "716652")
				_pixel(Rect2(-32,-8,64,8),"d4ba86")
				_pixel(Rect2(-20,-62,40,16),"253440")
				# EXIT is baked into the sign, not a floating giant label.
				draw_string(ThemeDB.fallback_font,Vector2(-17,-49),"SALIDA",HORIZONTAL_ALIGNMENT_LEFT,40,10,Color("f4dda2"))
				if visual_kind=="arch":
					_pixel(Rect2(-24,-88,48,8),"c38a98")
					_pixel(Rect2(-16,-96,32,8),"e5bd98")
				if visual_kind=="gate":_pixel(Rect2(-40,-28,80,8),"ac875d")
			"lectern":
				_pixel(Rect2(-24,-40,48,12),"d5b57b");_pixel(Rect2(-20,-28,40,20),"87643f");_pixel(Rect2(-12,-8,24,8),"5c4732")
				_pixel(Rect2(-12,-44,24,8),"f2e2bc");_pixel(Rect2(8,-60,4,20),"31424d")
			"chair":
				_pixel(Rect2(-24,-44,48,12),"d7bc8a");_pixel(Rect2(-24,-32,8,36),"947350");_pixel(Rect2(16,-32,8,36),"947350");_pixel(Rect2(-20,-16,40,12),"b5a486")
			"phone":
				_pixel(Rect2(-16,-52,32,52),"293947");_pixel(Rect2(-12,-44,24,32),"78a7a4");_pixel(Rect2(-8,-36,16,4),"e5d8b8");_pixel(Rect2(-8,-24,12,4),"e5d8b8");_pixel(Rect2(-4,-8,8,4),"acbcb8")
			"notice":
				_pixel(Rect2(-28,-60,56,44),"8c6c45");_pixel(Rect2(-24,-56,48,36),"e2cf9d");_pixel(Rect2(-4,-16,8,20),"695236")
				for y in [-48,-40,-32]:_pixel(Rect2(-16,y,32,4),"7f795f")
			"badge":
				_pixel(Rect2(-16,-64,8,36),"4d7e9c");_pixel(Rect2(8,-64,8,36),"4d7e9c");_pixel(Rect2(-16,-64,32,8),"4d7e9c")
				_pixel(Rect2(-20,-36,40,32),"eadbbb");_pixel(Rect2(-16,-32,16,12),"8da49a");_pixel(Rect2(4,-32,12,4),"5c6572");_pixel(Rect2(4,-24,12,4),"5c6572")
			"document","letter":
				_pixel(Rect2(-28,-16,56,16),"a5825c");_pixel(Rect2(-20,-56,40,44),"efe0be")
				for y in [-44,-36,-28]:_pixel(Rect2(-12,y,24,4),"8e8878")
				if visual_kind=="letter":_pixel(Rect2(8,-20,8,8),"b76e82")
			"table":
				_pixel(Rect2(-28,-32,56,16),"cfa473");_pixel(Rect2(-20,-16,8,16),"72563c");_pixel(Rect2(12,-16,8,16),"72563c")
	if enabled and required:
		# Small corner glints support the real object, never substitute for it.
		var y: float=-110 if visual_kind=="npc" else -92 if visual_kind in ["door","gate","arch"] else -60
		_pixel(Rect2(-5,y,10,4),"f6dc9b");_pixel(Rect2(-2,y-3,4,10),"f6dc9b")
