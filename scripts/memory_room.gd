extends Node2D
## Fictional scrapbook hub. Collision and interaction anchors are distinct from art.
const Actor = preload("res://scripts/memory_actor.gd")
var director: Node
var clock := 0.0
var player_position := Vector2(665,550)
var direction := 3
var active := true
var title_mode := false
var actor: Node2D
var book: Sprite2D
var displays: Array[Sprite2D] = []
var background: Texture2D
var prompt: Label
var blockers: Array[Rect2] = [Rect2(536,350,260,125)]

func _ready() -> void:
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	background=load("res://assets/art/directors/memory_room.png")
	var depth:=Node2D.new();depth.y_sort_enabled=true;add_child(depth)
	for page in director.data.pages:
		var display:=Sprite2D.new();display.texture=load(page.art if director.recovered(int(page.chapter)) else "res://assets/art/directors/locked_photo.png");display.position=Vector2(page.display[0],page.display[1]);display.scale=Vector2(64,64)/Vector2(display.texture.get_size());depth.add_child(display);displays.append(display)
		blockers.append(Rect2(float(page.display[0])-42,170,84,75))
	book=Sprite2D.new();book.texture=load("res://assets/art/directors/book_open.png");book.position=Vector2(665,385);book.scale=Vector2(145,100)/Vector2(book.texture.get_size());depth.add_child(book)
	actor=Actor.new();actor.world=self;actor.person="anami";actor.texture=load("res://assets/art/sprites-v2/anami_casual.png");depth.add_child(actor)
	actor.visible=not title_mode
	prompt=Label.new();prompt.position=Vector2(340,626);prompt.size=Vector2(600,45);prompt.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;prompt.add_theme_font_size_override("font_size",20);prompt.add_theme_color_override("font_color",Color("ffe0af"));add_child(prompt)
	refresh();sync_actor(false)

func refresh() -> void:
	for i in range(displays.size()):
		var restored: bool=director.recovered(i)
		displays[i].texture=load(director.data.pages[i].art if restored else "res://assets/art/directors/locked_photo.png")
		displays[i].scale=Vector2(64,64)/Vector2(displays[i].texture.get_size())
		displays[i].modulate=Color.WHITE if restored else Color(.55,.45,.6,.5)
	if director.state.recovered.size()>=5:book.texture=load("res://assets/art/directors/book_restored.png")

func legal(p: Vector2) -> bool:
	if not Rect2(185,270,930,370).has_point(p):return false
	for block in blockers:
		if block.grow(12).has_point(p):return false
	return true

func move_by(step: Vector2) -> void:
	var steps:=maxi(1,int(ceil(step.length()/6)))
	for _i in range(steps):
		var piece:=step/steps
		if legal(player_position+Vector2(piece.x,0)):player_position.x+=piece.x
		if legal(player_position+Vector2(0,piece.y)):player_position.y+=piece.y

func nearest() -> int:
	var result: int=-1;var best: float=player_position.distance_to(Vector2(665,495))
	for i in range(director.data.pages.size()):
		var page: Dictionary=director.data.pages[i]
		var distance:=player_position.distance_to(Vector2(page.anchor[0],page.anchor[1]))
		if distance<best:best=distance;result=i
	return result if best<105 else -2

func interact() -> void:
	if not active or director.game.is_paused or is_instance_valid(director.game.modal):return
	var target:=nearest()
	if target==-1:director.scrapbook()
	elif target>=0:director.inspect_page(target)

func sync_actor(moving: bool) -> void:
	if not is_instance_valid(actor):return
	actor.position=player_position;actor.row=direction;actor.column=int(clock*8)%4 if moving else 0

func _process(delta: float) -> void:
	if director.game.is_paused:return
	clock+=delta
	var moving:=false
	if active and not title_mode and not is_instance_valid(director.game.modal):
		var motion:=Vector2(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W)))
		if motion.length_squared()>0:
			direction=2 if motion.x>0 else 1 if motion.x<0 else 3 if motion.y<0 else 0
			var old:=player_position;move_by(motion.normalized()*190*delta);moving=old!=player_position
	sync_actor(moving)
	var target:=nearest()
	prompt.text="" if title_mode or not active else "E · Abrir el scrapbook" if target==-1 else "E · "+str(director.data.pages[target].keepsake) if target>=0 else "WASD · Explorar   ·   Libro: centro de la habitación"
	queue_redraw()

func _draw() -> void:
	if background:draw_texture_rect(background,Rect2(0,0,1280,720),false)
	if not director.game.reduced_motion:
		for i in range(12):
			var p:=Vector2(410+i*48+sin(clock*.3+i)*9,335+sin(clock*.4+i*2)*45)
			draw_rect(Rect2(p,Vector2(2,2)),Color(1,.8,.4,.12+.08*sin(clock+i)))
	var strength: float=0.0 if director.state.recovered.size()>=5 else .12+director.state.recovered.size()*.035
	for i in range(4):draw_rect(Rect2(Vector2(790+i*3,73+i*15),Vector2(3,9)),Color(.5,.27,.65,strength))
