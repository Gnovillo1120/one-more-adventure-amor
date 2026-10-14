extends Node2D
## Five authored phone-action poses over the existing outfit; shot commits once.
const POSES = preload("res://assets/art/living/photo_phone_poses.svg")
var living: Node2D
var elapsed := 0.0
var running := false
var shuttered := false
var subject := Vector2.ZERO
var focus_camera: Camera2D
var camera_previous: Camera2D
var pose_frame := 0
var original_canvas := Transform2D.IDENTITY
var original_viewport: Viewport
func start() -> void:
	running=true;elapsed=0;shuttered=false;pose_frame=0
	original_viewport=get_viewport();original_canvas=original_viewport.canvas_transform
	living.busy=true;living.world.moving=false
	subject=living.world.companion_position
	var delta: Vector2=subject-living.world.player_position
	living.world.direction=2 if absf(delta.x)>absf(delta.y) and delta.x>0 else 1 if absf(delta.x)>absf(delta.y) else 3 if delta.y<0 else 0
	queue_redraw()
func advance(delta: float) -> void:
	if not running:return
	elapsed+=delta
	pose_frame=0 if elapsed<.35 else 1 if elapsed<.65 else 2 if elapsed<1.25 else 3 if elapsed<1.6 else 4
	if elapsed>=.65 and not is_instance_valid(focus_camera) and not living.world.get_parent().reduced_motion:
		camera_previous=get_viewport().get_camera_2d();focus_camera=Camera2D.new();focus_camera.position=Vector2(640,360).lerp(subject,.06).round();focus_camera.zoom=Vector2(1.04,1.04);living.world.add_child(focus_camera);focus_camera.make_current()
	if elapsed>=1.25 and not shuttered:
		shuttered=true;living.state.photo=true;living.state.photo_count=1;living.changed.emit()
		living.world.get_parent()._sfx("camera_shutter");living.capture_photo()
	if elapsed>=2.1:
		running=false;living.busy=false;living.world.moving=false;living.world.actors.anami.column=0
		finish_camera()
		living.announce("Foto guardada · Libro → Fotos de la partida")
	queue_redraw()
func finish_camera() -> void:
	if is_instance_valid(focus_camera):focus_camera.enabled=false;focus_camera.queue_free();focus_camera=null
	if is_instance_valid(camera_previous):camera_previous.make_current()
	elif is_instance_valid(original_viewport):original_viewport.canvas_transform=original_canvas
func _exit_tree() -> void:
	if running:finish_camera()
func _draw() -> void:
	if not running:return
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	var row: int=living.world.direction+(4 if living.world.outfit=="halloween" else 0)
	draw_texture_rect_region(POSES,Rect2(-32,-90,64,96),Rect2(pose_frame*32,row*48,32,48))
	if elapsed>=.65 and elapsed<1.6:
		var offset: Vector2=subject-living.world.player_position
		for p in [Vector2(-39,-100),Vector2(33,-100),Vector2(-39,0),Vector2(33,0)]:
			draw_rect(Rect2(offset+p,Vector2(6,2)),Color("e6d6a9"));draw_rect(Rect2(offset+p,Vector2(2,6)),Color("e6d6a9"))
		if elapsed>=1.25 and elapsed<1.4 and not living.world.get_parent().reduced_motion:
			draw_rect(Rect2(offset+Vector2(-32,-90),Vector2(64,96)),Color(1,1,1,.16))
