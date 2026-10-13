extends Node2D
## Run scenes/dev/animation_preview.tscn. Never wired into player menus/exports.
const Anim = preload("res://scripts/character_animation.gd")
const Actor = preload("res://scripts/memory_actor.gd")
const OUTFITS = ["anami_casual","anami_formal","anami_halloween","anami_swimwear","guillermo_casual","guillermo_formal","guillermo_halloween"]
var clock := 0.0
var outfits: OptionButton
var actions: OptionButton
var details: Label
var cards: Array = []
var labels: Array = []
var playing := true
var modes: Array[String] = []

func _ready() -> void:
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	var back:=ColorRect.new();back.size=Vector2(1280,720);back.color=Color("182b38");add_child(back)
	var title:=Label.new();title.text="DEVELOPER · CHARACTER ANIMATION INSPECTOR";title.position=Vector2(40,30);title.add_theme_font_size_override("font_size",26);add_child(title)
	outfits=OptionButton.new();outfits.position=Vector2(40,90);outfits.size=Vector2(290,45);add_child(outfits)
	for value in OUTFITS:outfits.add_item(value)
	actions=OptionButton.new();actions.position=Vector2(350,90);actions.size=Vector2(270,45);add_child(actions)
	outfits.item_selected.connect(func(_i: int):rebuild());actions.item_selected.connect(func(_i: int):clock=0)
	var pause:=Button.new();pause.text="Pause / resume";pause.position=Vector2(640,90);pause.size=Vector2(180,45);pause.pressed.connect(func():playing=not playing);add_child(pause)
	var step:=Button.new();step.text="Step 1/8 s";step.position=Vector2(840,90);step.size=Vector2(150,45);step.pressed.connect(func():playing=false;clock+=.125);add_child(step)
	details=Label.new();details.position=Vector2(40,160);details.size=Vector2(1190,80);details.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;add_child(details)
	for direction in range(4):
		var actor: Node2D=Actor.new();actor.world=self;actor.scale=Vector2(3,3);actor.position=Vector2(190+direction*295,565);add_child(actor);cards.append(actor)
		var label:=Label.new();label.position=Vector2(70+direction*295,590);label.size=Vector2(265,90);label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;add_child(label);labels.append(label)
	rebuild()
	if OS.get_cmdline_user_args().has("--capture-preview"):call_deferred("capture_preview")

func capture_preview() -> void:
	DirAccess.make_dir_recursive_absolute("res://docs/animation/preview")
	for i in range(OUTFITS.size()):
		outfits.select(i);rebuild();actions.select(1)
		await get_tree().create_timer(.3).timeout;await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://docs/animation/preview/%s.png"%OUTFITS[i])
	outfits.select(3);rebuild();actions.select(2)
	await get_tree().create_timer(.3).timeout;await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://docs/animation/preview/four_direction_swimming.png")
	print("ANIMATION_PREVIEW_CAPTURE_OK");get_tree().quit()

func rebuild() -> void:
	clock=0;actions.clear();modes.assign(["idle","walk"])
	var outfit: String=OUTFITS[outfits.selected]
	if outfit=="anami_swimwear":modes.append_array(["swim","swim_idle","enter_pool","exit_pool"])
	elif outfit=="anami_casual":modes.append_array(["phone","drink","sit","surprise"])
	elif outfit=="anami_formal":modes.append("fountain")
	elif outfit=="anami_halloween":modes.append_array(["dance","affection","outfit"])
	elif outfit=="guillermo_halloween":modes.append("poolside_affection")
	for mode in modes:actions.add_item(mode)
	for actor in cards:actor.texture=load("res://assets/art/living/anami_swimwear.png" if outfit=="anami_swimwear" else "res://assets/art/sprites-v2/%s.png"%outfit)

func _process(delta: float) -> void:
	if playing:clock+=delta
	if cards.is_empty():return
	var mode: String=modes[actions.selected]
	for direction in range(4):
		var actor: Node2D=cards[direction];actor.row=direction;actor.column=Anim.walk_frame(clock,mode=="walk");actor.action_row=-1;actor.action_cell=Vector2(32,48)
		if mode in ["swim","swim_idle","enter_pool","exit_pool"]:
			var swim: String=Anim.swim_state(direction,true) if mode=="swim" else mode
			actor.action_texture=Anim.SWIM;actor.action_row=Anim.SWIM_ROWS[swim];actor.action_cell=Vector2(48,48);actor.action_frame=Anim.swim_frame(swim,fmod(clock,1.3) if mode in ["enter_pool","exit_pool"] else clock)
		elif mode not in ["idle","walk"]:
			actor.action_texture=load("res://assets/art/living/guillermo_affection.png" if mode=="poolside_affection" else "res://assets/art/living/anami_fountain.png" if mode=="fountain" else "res://assets/art/living/anami_actions.png")
			actor.action_row=0 if mode in ["fountain","poolside_affection"] else ["phone","drink","sit","swim","dance","surprise","affection","outfit"].find(mode)
			actor.action_frame=0 if mode=="sit" else 1 if mode=="phone" else int(clock*6)%4
		var cell: Vector2=actor.action_cell if actor.action_row>=0 else Vector2(32,48)
		var row: int=actor.action_row if actor.action_row>=0 else actor.row
		var frame: int=actor.action_frame if actor.action_row>=0 else actor.column
		labels[direction].text="%s · row %d / frame %d\ncell %dx%d"%[Anim.DIRECTIONS[direction],row,frame,int(cell.x),int(cell.y)]
	details.text="%s · %s\nFour direction cards use the same MemoryActor renderer as gameplay. Actions without directional art repeat their authored pose; treading is front-facing. Pause and step to inspect bounds and frame ordering."%[OUTFITS[outfits.selected],mode]
