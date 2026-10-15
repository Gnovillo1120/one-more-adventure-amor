extends Node2D
## Lightweight stepped-pixel steam attached to the actual served ramen bowl.
var world: Node2D
var clock := 0.0
func _process(delta: float) -> void:
	if not is_instance_valid(world) or world.get_parent().is_paused:return
	clock+=delta;queue_redraw()
func _draw() -> void:
	for i in range(3):
		var rise:=fposmod(clock*12+i*18,52)
		var p:=Vector2(-10+i*9+sin(clock+i)*4,-rise)
		for j in range(3):draw_rect(Rect2(p+Vector2(sin(j+i)*3,-j*4),Vector2(3,4)),Color(.95,.91,.75,(1-rise/52)*.65))
