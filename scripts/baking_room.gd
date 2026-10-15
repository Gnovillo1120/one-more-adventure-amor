extends Node2D
## Stateful countertop and oven props, with collision-aligned focus outlines.
var world: Node2D
var last_state: Dictionary = {}
const BOWL=preload("res://assets/art/baking/bowl.png")
const RACK=preload("res://assets/art/baking/rack.png")
const FOOTPRINTS := {"fridge":Rect2(225,85,115,198),"pantry":Rect2(1085,85,165,225),"sink":Rect2(525,155,160,125),"counter":Rect2(410,340,470,185),"oven":Rect2(880,150,145,132),"rack":Rect2(920,470,135,75)}

func _ready() -> void:
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	var chapters: Variant=world.get_parent().get("chapter_state")
	if chapters is Dictionary:
		var saved: Dictionary=chapters.get(world.scene_id,{}).get("challenge_sessions",{}).get("cookies",{})
		if not saved.is_empty():
			var model=preload("res://scripts/baking_session.gd").new()
			model.setup("cookies",JSON.parse_string(FileAccess.get_file_as_string("res://data/oatmeal_cookie_recipe.json")),saved);last_state=model.state
	for id in FOOTPRINTS:
		var anchor:=Node2D.new();anchor.position=FOOTPRINTS[id].get_center();anchor.set_meta("rendered_fixture",true);world.depth_root.add_child(anchor);world.fixtures["mixing" if id=="counter" else id]=anchor
func _process(_delta: float) -> void:
	if is_instance_valid(world.baking):last_state=world.baking.session.state
	queue_redraw()
func _draw() -> void:
	# The lit oven changes from empty to raw, golden, then overbaked.
	draw_rect(Rect2(904,220,80,38),Color("453a2d"))
	var live: bool=is_instance_valid(world.baking)
	if not live and last_state.is_empty():return
	var s: Dictionary=world.baking.session.state if live else last_state
	if live and world.baking.gather_time>0:
		var source: String=world.baking.gather_source
		var f: float=1-world.baking.gather_time/1.5
		var door: Rect2=FOOTPRINTS[source]
		var open: float=sin(f*PI)
		if source in ["pantry","fridge"]:
			draw_rect(door.grow(-8),Color("3b3c30"))
			for y in range(int(door.position.y+25),int(door.end.y-12),38):
				draw_rect(Rect2(door.position.x+12,y,door.size.x-24,4),Color("a9926c"))
				for x in range(int(door.position.x+18),int(door.end.x-12),24):draw_rect(Rect2(x,y-22,14,22),Color("d7c29a"))
			var width: float=door.size.x*(1-open*.8)
			draw_rect(Rect2(door.position,Vector2(width,door.size.y)),Color("aac0a6" if source=="fridge" else "936341"))
			draw_rect(Rect2(door.position+Vector2(width-12,60),Vector2(4,28)),Color("e6d7ae"))
		var origin: Vector2=door.get_center()
		var destination:=Vector2(640,385)
		var p: Vector2=origin.lerp(destination,smoothstep(.25,.9,f));p.y-=sin(f*PI)*55
		draw_rect(Rect2(p-Vector2(12,16),Vector2(24,32)),Color("f1dfb2"));draw_rect(Rect2(p-Vector2(14,20),Vector2(28,6)),Color("7a9b82"))
		var hand: Vector2=world.player_position+Vector2(15,-40)
		if s.phase=="gather":draw_line(hand,hand.lerp(origin,.25)*open+hand*(1-open),Color("dfaf84"),8)
	var selected: Dictionary=world.context_target()
	var id: String=str(selected.get("id","")).trim_prefix("baking:")
	if FOOTPRINTS.has(id):draw_rect(FOOTPRINTS[id].grow(3),Color("e4c78a"),false,2)
	draw_texture_rect(BOWL,Rect2(598,349,88,58),false)
	if s.phase not in ["intro","quiz","gather"]:
		for i in range(12):draw_rect(Rect2(540+posmod(i*31,160),402+posmod(i*7,30),4,4),Color("ecdbac"))
	if s.phase in ["tray","flatten","oven"]:
		draw_rect(Rect2(904,220,80,38),Color("ba7b35"))
		if s.inserted:
			for i in range(6):draw_rect(Rect2(913+(i%3)*22,229+(i/3)*12,14,8),Color("ebba6c" if s.minutes<=10 else "765034"))
		draw_rect(Rect2(875,298,160,10),Color("4c3c2b"))
		draw_rect(Rect2(875,298,160*minf(1,float(s.minutes)/15),10),Color("c68a52"))
		draw_rect(Rect2(875+160*8/15.0,298,160*2/15.0,10),Color("8ab17b"),false,2)
	if s.phase in ["cool","taste","result"]:
		draw_texture_rect(RACK,Rect2(920,470,135,75),false)
		for i in range(6):draw_rect(Rect2(935+(i%3)*36,483+(i/3)*26,23,16),Color("d6a362" if s.minutes<=10 else "765034"))
