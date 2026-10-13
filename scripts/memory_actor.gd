extends Node2D
## Ground-anchored walking and seated compositions share the original character art.
var world: Node2D
var person := ""
var texture: Texture2D
var seated := false
var row := 0
var column := 0
var npc := false
var idle_phase := 0.0
var atlas_row := -1
var action_texture: Texture2D
var action_row := -1
var action_frame := 0
var action_cell := Vector2(32,48)
var action_offset_y := -90.0
var water_pose := false

func _ready() -> void:texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
func _process(_delta: float) -> void:queue_redraw()
func _draw() -> void:
	if texture==null:return
	var size:=Vector2(64,96)
	var nod:=2.0 if int(world.clock+idle_phase)%9==0 else 0.0
	if not water_pose:draw_rect(Rect2(-22,-2,44,6),Color(.07,.1,.13,.25))
	if action_row>=0 and action_texture!=null:
		draw_texture_rect_region(action_texture,Rect2(Vector2(-action_cell.x,action_offset_y),action_cell*2),Rect2(Vector2(action_frame,action_row)*action_cell,action_cell))
	elif atlas_row>=0:
		draw_texture_rect_region(texture,Rect2(-32,-90,64,96),Rect2(column*32,atlas_row*48,32,48))
	elif seated:
		# Bent knees/shoes support a shorter torso; table foreground occludes the lap.
		draw_rect(Rect2(-18,-20,14,12),Color("46505c"));draw_rect(Rect2(4,-20,14,12),Color("46505c"))
		draw_rect(Rect2(-18,-8,14,6),Color("25343e"));draw_rect(Rect2(4,-8,14,6),Color("25343e"))
		if npc:draw_texture_rect_region(texture,Rect2(-32,-88-nod,64,62),Rect2(0,0,32,31))
		else:draw_texture_rect_region(texture,Rect2(-32,-88-nod,64,62),Rect2(column*32,0,32,31))
	elif npc:draw_texture_rect(texture,Rect2(Vector2(-32,-90-nod),size),false)
	else:draw_texture_rect_region(texture,Rect2(-32,-90,64,96),Rect2(column*32,row*48,32,48))
