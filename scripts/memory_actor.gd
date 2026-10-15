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
var carrying := 0
var applause := false
var walking := false
var sit_amount := 0.0
var eating := false
var has_diploma := false
var service_apron := false
var pose_clock := 0.0

func _ready() -> void:texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
func _process(delta: float) -> void:
	if is_instance_valid(world) and world.get_parent().get("is_paused")==true:return
	pose_clock+=delta
	sit_amount=move_toward(sit_amount,1.0 if seated else 0.0,delta*3)
	queue_redraw()
func _draw() -> void:
	if texture==null:return
	var size:=Vector2(64,96)
	var nod:=2.0 if int(pose_clock+idle_phase)%9==0 else 0.0
	if not water_pose:draw_rect(Rect2(-22,-2,44,6),Color(.07,.1,.13,.25))
	if carrying>0 and row==3:plate(Vector2(0,-49)) # Facing away: torso occludes the dish.
	if action_row>=0 and action_texture!=null:
		draw_texture_rect_region(action_texture,Rect2(Vector2(-action_cell.x,action_offset_y),action_cell*2),Rect2(Vector2(action_frame,action_row)*action_cell,action_cell))
	elif atlas_row>=0:
		draw_texture_rect_region(texture,Rect2(-32,-90,64,96),Rect2(column*32,atlas_row*48,32,48))
	elif seated:
		draw_set_transform(Vector2(0,6*sit_amount))
		# Bent knees/shoes support a shorter torso; table foreground occludes the lap.
		draw_rect(Rect2(-18,-20,14,12),Color("46505c"));draw_rect(Rect2(4,-20,14,12),Color("46505c"))
		draw_rect(Rect2(-18,-8,14,6),Color("25343e"));draw_rect(Rect2(4,-8,14,6),Color("25343e"))
		if npc:draw_texture_rect_region(texture,Rect2(-32,-88-nod,64,62),Rect2(0,0,32,31))
		else:draw_texture_rect_region(texture,Rect2(-32,-88-nod,64,62),Rect2(column*32,row*48,32,31))
	elif carrying>0 and not npc:
		# Walking legs retain their cycle; the torso and bent arms hold still.
		draw_texture_rect_region(texture,Rect2(-32,-26,64,32),Rect2(column*32,row*48+32,32,16))
		draw_texture_rect_region(texture,Rect2(-32,-90,64,64),Rect2(0,row*48,32,32))
	elif npc and walking:
		# A small two-leg rig keeps a new student's face and clothing stable.
		# Only the lower legs alternate; no cycling through directional portraits.
		draw_texture_rect_region(texture,Rect2(-32,-90,64,68),Rect2(0,0,32,34))
		for side in range(2):
			var step:=roundf(sin(pose_clock*9+idle_phase+side*PI)*2)*2
			draw_texture_rect_region(texture,Rect2(-32+side*32,-22+step,32,28),Rect2(side*16,34,16,14))
	elif npc:draw_texture_rect(texture,Rect2(Vector2(-32,-90-nod),size),false)
	else:draw_texture_rect_region(texture,Rect2(-32,-90,64,96),Rect2(column*32,row*48,32,48))
	draw_set_transform(Vector2.ZERO)
	if service_apron:
		draw_rect(Rect2(-12,-37,24,30),Color("3f6b58"))
		draw_rect(Rect2(-12,-18,24,3),Color("bed0ac"));draw_rect(Rect2(-7,-12,14,4),Color("2c5147"))
	if carrying>0:
		var p:=Vector2(-2,-35) if row==0 else Vector2(-19,-40) if row==1 else Vector2(19,-40) if row==2 else Vector2(0,-49)
		# Sleeves and bent forearms replace the arm swing at the held plate.
		for side in [-1,1]:
			draw_rect(Rect2(p+Vector2(side*18-5,-5),Vector2(10,13)),Color("32495c"))
			draw_rect(Rect2(p+Vector2(side*13-4,3),Vector2(8,7)),Color("d9a67e"))
		if row!=3:plate(p)
	if applause:
		var y: float=-38-4*sin(pose_clock*7+idle_phase)
		for side in [-1,1]:draw_rect(Rect2(side*(7+4*sin(pose_clock*7))-4,y,8,8),Color("d5a37c"))
	if eating and fmod(pose_clock+idle_phase,7)<1.8:
		var lift:=sin(fmod(pose_clock+idle_phase,7)*PI/1.8)*17
		draw_rect(Rect2(9,-36-lift,8,7),Color("d9a67e"))
		for x in [14,18]:draw_line(Vector2(x,-40-lift),Vector2(x+5,-25-lift),Color("b99662"),2)
	if has_diploma:draw_texture_rect(world.DIPLOMA,Rect2(4,-47,32,24),false)

func plate(p: Vector2) -> void:
	draw_rect(Rect2(p+Vector2(-23,6),Vector2(46,10)),Color("b9c4b8"));draw_rect(Rect2(p+Vector2(-20,2),Vector2(40,10)),Color("fff0d2"))
	if carrying>1:draw_rect(Rect2(p+Vector2(-16,2),Vector2(15,6)),Color("ede6bb"))
	if carrying>2:draw_rect(Rect2(p+Vector2(0,4),Vector2(14,5)),Color("925b37"))
	if carrying>3:draw_rect(Rect2(p+Vector2(6,-1),Vector2(12,6)),Color("684535"))
