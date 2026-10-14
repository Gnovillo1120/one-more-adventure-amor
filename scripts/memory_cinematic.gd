extends Node
## Concise reusable camera/actor staging. A single finish path handles skip and cancel.
var game: Node
var running := false
var tween: Tween
var camera: Camera2D
var bars: CanvasLayer
var callback: Callable
var world: Node2D
var shot := ""
var home := Vector2.ZERO
var target := Vector2.ZERO
var elapsed := 0.0
var total := 2.0
var finished := false
var cue := false

func play(id: String, done: Callable) -> void:
	cancel()
	world=game.memory;shot=id;callback=done;running=true;finished=false;elapsed=0;cue=false
	home=world.companion_position;target=home
	world.active=false
	if is_instance_valid(game.hud):game.hud.hide()
	var focus: Vector2=world.player_position.lerp(home,.5)
	match id:
		"award":target=world.safe_position(world.player_position+Vector2(65,0));total=3.0
		"goodbye":target=world.safe_position(Vector2(1120,550));total=2.4
		"date":total=2.6;world.waiter_movement(true)
		"pool":total=3.5;focus=world.companion_position+Vector2(-24,-35)
		"dance":total=2.4;world.dancing=true
		"foot":total=1.5
		_:total=2.0
	var local: Dictionary=game.chapter_state.get(world.scene_id,{})
	local["cinematic_checkpoint"]=id;game.chapter_state[world.scene_id]=local;game.save_game()
	if DisplayServer.get_name()=="headless":finish();return
	camera=Camera2D.new();camera.position=Vector2(640,360);camera.position_smoothing_enabled=false;world.add_child(camera);camera.make_current()
	bars=CanvasLayer.new();bars.layer=8;add_child(bars)
	for y in [0,682]:
		var bar:=ColorRect.new();bar.color=Color("182324");bar.position=Vector2(0,y);bar.size=Vector2(1280,38);bar.mouse_filter=Control.MOUSE_FILTER_IGNORE;bars.add_child(bar)
	var label:=Label.new();label.text="Espacio / E / Esc · saltar";label.position=Vector2(950,688);label.add_theme_font_size_override("font_size",17);bars.add_child(label)
	tween=create_tween().set_parallel(true)
	var factor:=1.0 if game.reduced_motion else 1.3 if id=="pool" else 1.18 if id=="award" else 1.12
	var aim: Vector2=Vector2(640,360).lerp(focus,.65)
	tween.tween_property(camera,"position",aim,.75).set_trans(Tween.TRANS_SINE)
	tween.tween_property(camera,"zoom",Vector2.ONE*factor,.75).set_trans(Tween.TRANS_SINE)
	tween.chain().tween_interval(maxf(.1,total-1.25))
	tween.chain().tween_property(camera,"zoom",Vector2.ONE,.5)
	tween.parallel().tween_property(camera,"position",Vector2(640,360),.5)
	tween.chain().tween_callback(finish)

func _process(delta: float) -> void:
	if not running or not is_instance_valid(world):return
	if game.is_paused:
		if is_instance_valid(tween):tween.pause()
		return
	if is_instance_valid(tween) and not tween.is_running():tween.play()
	elapsed+=delta
	world.companion_position=home.lerp(target,minf(1,elapsed/1.3))
	if target!=home:
		world.actors.guillermo.row=2 if target.x>home.x else 1;world.actors.guillermo.column=int(elapsed*7)%4
	if shot=="dance":world.living.pose("dance",.5)
	if shot=="invitation":world.living.pose("outfit",.5)
	if shot=="pool":
		world.seated=true;world.player_position=world.companion_position+Vector2(-48,0)
		world.living.state.romance=true;world.living.state.affection_frame=1 if elapsed<1.3 else 2 if elapsed<2.3 else 3
		world.living.pose("affection",1)
	if shot=="award":world.effect="diploma";world.effect_time=4
	if elapsed>.8 and not cue:
		cue=true
		game._sfx("applause" if shot=="award" else "notify" if shot=="reconnect" else "interact")
		if shot=="caucus":world.living.pose("surprise",1.2)
	if shot=="reconnect" and elapsed<.8:world.living.pose("phone",1.4)
	if shot=="date" and elapsed>1.1:world.deliver_food()

func finish() -> void:
	if not running or finished:return
	finished=true;running=false
	var done:=callback;callback=Callable()
	if is_instance_valid(world):
		world.companion_position=target;world.dancing=false
		if shot=="pool":world.seated=true;world.player_position=target+Vector2(-48,0);world.living.state.romance=true;world.living.state.affection_frame=3;world.living.pose("affection",3600)
		if shot=="date":world.deliver_food();world.waiter_movement(false)
		world.active=true
		var local: Dictionary=game.chapter_state.get(world.scene_id,{})
		local.erase("cinematic_checkpoint");var seen: Array=local.get("cinematics",[])
		if not seen.has(shot):seen.append(shot)
		local.cinematics=seen;game.chapter_state[world.scene_id]=local
	cleanup()
	if done.is_valid():done.call()
	game.save_game()

func handle(event: InputEvent) -> bool:
	if not running:return false
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode in [KEY_SPACE,KEY_E,KEY_ESCAPE]:finish();return true
	return true

func cleanup() -> void:
	if is_instance_valid(tween):tween.kill()
	if is_instance_valid(camera):camera.enabled=false;camera.queue_free()
	if is_instance_valid(bars):bars.queue_free()
	camera=null;bars=null
	if is_instance_valid(world):world.get_viewport().canvas_transform=Transform2D.IDENTITY
	if is_instance_valid(game.hud):game.hud.show()

func cancel() -> void:
	running=false;callback=Callable();cleanup();world=null
