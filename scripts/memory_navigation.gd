extends RefCounted
## Orthogonal reachability using production feet bounds and movement substeps.
const GRID := 10.0
var world: Node2D
var parents: Dictionary = {}
var start: Vector2i

func point(cell: Vector2i) -> Vector2:
	return Vector2(110,225)+Vector2(cell)*GRID

func cell(p: Vector2) -> Vector2i:
	return Vector2i(round((p.x-110)/GRID),round((p.y-225)/GRID))

func edge(a: Vector2, b: Vector2) -> bool:
	for i in range(6):
		var p:=a.lerp(b,float(i)/5.0)
		if not world.can_stand(p):return false
		# Avoid exact tangent routes: accumulated movement floats can cross the edge.
		for margin in [Vector2.ZERO,Vector2(.25,0),Vector2(-.25,0),Vector2(0,.25),Vector2(0,-.25)]:
			if world.WALK_BOUNDS.has_point(p+margin) and not world.can_stand(p+margin):return false
	return true

func scan(memory: Node2D) -> void:
	world=memory;parents.clear();start=cell(world.player_position)
	if not edge(world.player_position,point(start)):return
	var queue: Array[Vector2i]=[start];parents[start]=start
	var index:=0
	while index<queue.size():
		var current:=queue[index];index+=1
		for offset in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			var next: Vector2i=current+offset
			if parents.has(next) or not edge(point(current),point(next)):continue
			parents[next]=current;queue.append(next)

func path_to(target: Vector2) -> Array[Vector2]:
	var result: Array[Vector2]=[]
	if not world.can_stand(target):return result
	var goal:=cell(target)
	if not parents.has(goal) or not edge(point(goal),target):return result
	var reverse: Array[Vector2]=[target]
	var current:=goal
	while current!=start:reverse.append(point(current));current=parents[current]
	reverse.append(point(start));reverse.reverse();result.assign(reverse)
	return result
