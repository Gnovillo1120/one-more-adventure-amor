extends Node2D
## Stateful countertop and oven props, with collision-aligned focus outlines.
var world: Node2D
const BOWL=preload("res://assets/art/baking/bowl.png")
const RACK=preload("res://assets/art/baking/rack.png")
const FOOTPRINTS := {"fridge":Rect2(225,85,115,198),"pantry":Rect2(1085,85,165,225),"sink":Rect2(525,155,160,125),"counter":Rect2(410,340,470,185),"oven":Rect2(880,150,145,132),"rack":Rect2(920,470,135,75)}

func _ready() -> void:
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	for id in FOOTPRINTS:
		var anchor:=Node2D.new();anchor.position=FOOTPRINTS[id].get_center();anchor.set_meta("rendered_fixture",true);world.depth_root.add_child(anchor);world.fixtures["mixing" if id=="counter" else id]=anchor
func _process(_delta: float) -> void:queue_redraw()
func _draw() -> void:
	# The lit oven changes from empty to raw, golden, then overbaked.
	draw_rect(Rect2(904,220,80,38),Color("453a2d"))
	if not is_instance_valid(world.baking):return
	var s: Dictionary=world.baking.session.state
	var selected: Dictionary=world.context_target()
	var id: String=str(selected.get("id","")).trim_prefix("baking:")
	if FOOTPRINTS.has(id):draw_rect(FOOTPRINTS[id].grow(3),Color("e4c78a"),false,2)
	draw_texture_rect(BOWL,Rect2(598,349,88,58),false)
	if s.phase not in ["intro","quiz","gather"]:
		for i in range(12):draw_rect(Rect2(540+posmod(i*31,160),402+posmod(i*7,30),4,4),Color("ecdbac"))
	if s.phase=="oven":
		draw_rect(Rect2(904,220,80,38),Color("ba7b35"))
		for i in range(6):draw_rect(Rect2(913+(i%3)*22,229+(i/3)*12,14,8),Color("ebba6c" if s.minutes<=10 else "765034"))
		draw_rect(Rect2(875,298,160,10),Color("4c3c2b"))
		draw_rect(Rect2(875,298,160*minf(1,float(s.minutes)/15),10),Color("c68a52"))
		draw_rect(Rect2(875+160*8/15.0,298,160*2/15.0,10),Color("8ab17b"),false,2)
	if s.phase in ["cool","taste","result"]:
		draw_texture_rect(RACK,Rect2(920,470,135,75),false)
		for i in range(6):draw_rect(Rect2(935+(i%3)*36,483+(i/3)*26,23,16),Color("d6a362" if s.minutes<=10 else "765034"))
