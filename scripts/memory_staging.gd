extends Node2D
## Serving-line and ceremony semantics survive saves; gestures are transient.
const Cast = preload("res://scripts/supporting_cast.gd")
const Actor = preload("res://scripts/memory_actor.gd")
class ServingCounter:
	extends Node2D
	var component := 0
	var choreography: Node2D
	func _ready() -> void:set_meta("rendered_fixture",true);texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	func _process(_delta: float) -> void:queue_redraw()
	func _draw() -> void:
		draw_rect(Rect2(-65,-47,130,45),Color("293c4b"));draw_rect(Rect2(-67,-61,134,22),Color("e6dfc7"))
		if component==0:
			for j in range(4):draw_rect(Rect2(-20,-67-j*4,40,6),Color("f6efdb"))
		else:
			draw_rect(Rect2(-43,-65,86,20),Color("92a5a0"));draw_rect(Rect2(-38,-63,76,14),Color(["eee4bd","8c5533","6b4832"][component-1]))
			for j in range(14):draw_rect(Rect2(-33+posmod(j*13,62),-61+posmod(j*7,10),4,2),Color("f5e9bb" if component==1 else "ad7548"))
		if choreography.gesture>0 and choreography.serving==component-1 and component>0:
			ladle(1-choreography.gesture/1.2,0)
		if choreography.gui_gesture>0 and choreography.gui_serving==component-1 and component>0:
			ladle(1-choreography.gui_gesture/.7,47)
	func ladle(f: float, side: float) -> void:
		var p:=Vector2(sin(f*PI)*side,-60+sin(f*PI)*55)
		draw_line(p+Vector2(15,-25),p,Color("b9c9bf"),4);draw_rect(Rect2(p-Vector2(8,3),Vector2(16,7)),Color("b9c9bf"))
		draw_rect(Rect2(p-Vector2(5,2),Vector2(10,5)),Color(["f5e9bb","8c5533","6b4832"][component-1]))
var world: Node2D
var game: Node
var state: Dictionary = {"meal":0,"gui_meal":0,"ceremony":"seat"}
var staff: Array = []
var counters: Array = []
var audience: Array = []
var time := 0.0
var gesture := 0.0
var serving := -1
var gui_serving := -1
var gui_gesture := 0.0
var seated_plates := false
var chair_origin := Vector2.ZERO
const STATIONS := [Vector2(240,335),Vector2(385,335),Vector2(530,335),Vector2(675,335)]
const NAMES := ["Recoger plato","Servir arroz","Servir menestra","Servir carne"]

func _ready() -> void:
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;game=world.get_parent()
	state.merge(game.chapter_state.get(world.scene_id,{}).get("staging",{}),true)
	var legacy: Dictionary=game.chapter_state.get(world.scene_id,{})
	if not legacy.has("staging"):
		if legacy.get("seated",false) or int(legacy.get("step",0))>0:state.meal=4
		if int(legacy.get("step",0))>0:state.ceremony="congratulate"
	if world.completed:state.meal=4;state.ceremony="congratulate"
	if not legacy.get("staging",{}).has("gui_meal"):state.gui_meal=state.meal
	if DisplayServer.get_name()=="headless" or world.completed:state.gui_meal=4
	set_meta("rendered_fixture",true)
	for id in ["staging:meal","staging:seat","staging:wait"]:
		var prop: Node2D=load("res://scripts/interaction_prop.gd").new()
		prop.descriptor={"kind":"companion" if id.ends_with("wait") else "table" if id.ends_with("meal") else "chair","fixture":"staged_object"}
		prop.environment_object=world.actors.guillermo if id.ends_with("wait") else self;world.depth_root.add_child(prop);world.target_visuals[id]=prop
		prop.position=world.companion_position if id.ends_with("wait") else STATIONS[mini(3,int(state.meal))] if id.ends_with("meal") else Vector2(620,490)
	if world.scene_id=="lunch":
		world.actors.guillermo.set_meta("rendered_fixture",true)
		world.companion_position=STATIONS[mini(3,int(state.gui_meal))]+Vector2(66,0) if int(state.gui_meal)<4 else Vector2(950,420)
		world.actors.guillermo.seated=world.seated or world.completed
		z_index=-1 # Countertops behind the receiving characters, not over their bodies.
		for p in STATIONS:world.blockers.append(Rect2(p+Vector2(-65,-55),Vector2(130,20)))
		for i in range(4):
			var counter:=ServingCounter.new();counter.component=i;counter.choreography=self;counter.position=STATIONS[i]-Vector2(0,35);world.depth_root.add_child(counter);counters.append(counter)
		for i in range(3):
			var actor: Node2D=Actor.new();actor.world=world;actor.npc=true;actor.texture=Cast.sprite([10,2,11][i]);actor.service_apron=true;actor.position=STATIONS[i+1]+Vector2(0,-85);world.depth_root.add_child(actor);staff.append(actor)
		for i in range(4):
			var actor: Node2D=Actor.new();actor.world=world;actor.npc=true;actor.texture=Cast.sprite(i+3);actor.position=Vector2(180,360+i*48);world.depth_root.add_child(actor)
	if world.scene_id=="award":
		for entry in world.population_actors:
			if entry.data.get("name","")=="Presidencia":entry.data.position=[645,450]
		# The diploma belongs to the handoff, not a second floating target prop.
		var main: Node2D=world.target_visuals.get("main")
		if is_instance_valid(main):
			main.descriptor={"fixture":"award_actor"};main.texture=null;main.environment_object=world.actors.guillermo
			world.actors.guillermo.set_meta("rendered_fixture",true)
		for y in range(3):
			for x in range(6):
				var actor: Node2D=Actor.new();actor.world=world;actor.npc=true;actor.texture=Cast.sprite((x+y*3)%8);actor.position=Vector2(185+x*170,300+y*60);actor.seated=true;actor.scale=Vector2(.85,.85);actor.idle_phase=x+y;world.depth_root.add_child(actor);audience.append(actor)
		if state.ceremony=="announcing":state.ceremony="seat";world.seated=false # Usable chair, never a locked tween.
		if state.ceremony=="congratulate":world.quest_step=1;world.companion_position=Vector2(770,500);world.actors.guillermo.has_diploma=true

func target() -> Dictionary:
	if world.completed:return {}
	if world.scene_id=="lunch" and int(state.meal)<4:
		var p: Vector2=STATIONS[int(state.meal)]
		return {"id":"staging:meal","label":NAMES[int(state.meal)],"position":[p.x,p.y],"kind":"staging","visual":{"kind":"table"}}
	if world.scene_id=="lunch" and int(state.gui_meal)<4:return {"id":"staging:wait","label":"Guillermo termina de servirse","position":[world.companion_position.x,world.companion_position.y],"kind":"staging","visual":{"kind":"companion"}}
	if world.scene_id=="award" and state.ceremony=="seat":return {"id":"staging:seat","label":"Buscar asiento · sentarse","position":[620,490],"kind":"staging","visual":{"kind":"chair"}}
	return {}

func save() -> void:
	var local: Dictionary=game.chapter_state.get(world.scene_id,{})
	local.staging=state.duplicate(true);game.chapter_state[world.scene_id]=local
	game._refresh_objective();game.save_game()

func interact(id: String) -> void:
	if id=="staging:wait":world.living.announce("Mi plato está listo. Guillermo termina en la fila y nos sentamos juntos.");return
	if id=="staging:meal":
		if int(state.meal)>=4:return
		serving=int(state.meal)-1;gesture=1.2;state.meal+=1
		if DisplayServer.get_name()=="headless":gesture=0 # Semantic tests omit transient presentation, like seating/camera tests.
		elif serving>=0:world.active=false
		world.living.announce(["Un plato para empezar.","Arroz recién servido.","Menestra junto al arroz.","Listo. Ahora elige dónde sentarte."][int(state.meal)-1]);save()
	elif id=="staging:seat" and state.ceremony=="seat":
		chair_origin=world.player_position;world.direction=3;world.seated=true;world.active=false
		state.ceremony="announcing";time=0;save()
		world.living.announce("Presidencia: Mejor Delegado… Guillermo.")
		if DisplayServer.get_name()=="headless":finish_ceremony()

func finish_ceremony() -> void:
	state.ceremony="congratulate";world.quest_step=1;world.seated=false;world.active=true;world.companion_position=Vector2(770,500)
	world.actors.guillermo.has_diploma=true
	var local: Dictionary=game.chapter_state.get(world.scene_id,{})
	var seen: Array=local.get("cinematics",[])
	if not seen.has("award"):seen.append("award")
	local.cinematics=seen;game.chapter_state[world.scene_id]=local
	for actor in audience:actor.applause=false
	world.living.announce("Ahí está, con su diploma. Acércate para felicitarlo.");save()

func handle(event: InputEvent) -> bool:
	if world.scene_id!="award" or state.ceremony!="announcing" or game.is_paused:return false
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode in [KEY_E,KEY_SPACE]:
		finish_ceremony();return true
	return false

func _process(delta: float) -> void:
	if not is_instance_valid(world) or game.is_paused:return
	world.target_visuals["staging:meal"].position=STATIONS[mini(3,int(state.meal))]
	world.target_visuals["staging:seat"].position=Vector2(620,490)
	var was_serving: bool=gesture>0
	gesture=maxf(0,gesture-delta)
	if world.scene_id=="lunch":
		world.target_visuals["staging:meal"].environment_object=counters[mini(3,int(state.meal))]
		if was_serving and serving>=0:world.active=gesture<=0 and not game._dialogue_open() and not world.seating
		var visible_meal: int=int(state.meal)-(1 if serving>=0 and gesture>.6 else 0)
		world.actors.anami.carrying=0 if world.seated or world.completed else visible_meal
		tick_guillermo(delta)
		world.target_visuals["staging:wait"].position=world.companion_position
		seated_plates=world.seated
		if world.seated:
			place_meal("anami",-30)
		if world.actors.guillermo.seated:place_meal("guillermo",35)
	if state.ceremony=="announcing" and world.scene_id=="award":
		time+=delta
		world.active=false
		if time<.6:world.player_position=chair_origin.lerp(Vector2(620,490),smoothstep(0,.6,time))
		for actor in audience:actor.applause=time>1.2
		if time>1.2:
			world.companion_position=Vector2(805,490).lerp(Vector2(700,450),clampf((time-1.2)/2,0,1))
			world.actors.guillermo.row=1;world.actors.guillermo.column=int(time*6)%4 if time<3.2 else 0
		if time>4:
			world.actors.guillermo.has_diploma=true
			world.companion_position=Vector2(700,450).lerp(Vector2(770,500),clampf(time-4,0,1))
			world.actors.guillermo.row=2;world.actors.guillermo.column=int(time*6)%4
		if time>5:finish_ceremony()
	queue_redraw()

func tick_guillermo(delta: float) -> void:
	var actor: Node2D=world.actors.guillermo
	if gui_gesture>0:
		gui_gesture=maxf(0,gui_gesture-delta);actor.row=1;actor.column=0
		if gui_gesture<=0:state.gui_meal+=1;gui_serving=-1;save()
	else:
		var destination: Vector2=STATIONS[mini(3,int(state.gui_meal))]+Vector2(66,0) if int(state.gui_meal)<4 else Vector2(950,420)
		var distance: float=world.companion_position.distance_to(destination)
		var step: Vector2=world.companion_position.direction_to(destination)*minf(delta*160,distance)
		if world.can_stand(world.companion_position+step):world.companion_position+=step
		actor.row=2 if step.x>0 else 1 if step.x<0 else 3 if step.y<0 else 0
		actor.column=int(world.clock*6)%4 if distance>1 else 0
		if distance<=1 and int(state.gui_meal)<4:
			if int(state.gui_meal)==0:state.gui_meal=1;actor.row=1;save()
			else:gui_serving=int(state.gui_meal)-1;gui_gesture=.7;actor.row=1
	actor.position=world.companion_position
	actor.seated=(world.seated or world.completed) and world.companion_position.distance_to(Vector2(950,420))<2
	actor.carrying=0 if actor.seated else int(state.gui_meal)+(1 if gui_gesture>0 and gui_gesture<.35 else 0)

func place_meal(person: String,x: float) -> void:
	var id: String="meal_placed_"+person
	if world.get_meta(id,false):return
	world.set_meta(id,true)
	var plate:=Sprite2D.new();plate.texture=load("res://assets/art/polish/meal.svg");plate.position=Vector2(x,-35);world.fixtures.couple_table.add_child(plate)

func _draw() -> void:
	if world.scene_id=="award":
		draw_rect(Rect2(596,447,48,10),Color("65716c"));draw_rect(Rect2(596,456,8,36),Color("abb3a5"));draw_rect(Rect2(636,456,8,36),Color("abb3a5"));draw_rect(Rect2(600,480,40,10),Color("7b8273"))
		if state.ceremony=="announcing" and time>3.2 and time<4:
			var p:=Vector2(665,410).lerp(world.companion_position+Vector2(-10,-45),clampf((time-3.2)/.6,0,1))
			draw_texture_rect(world.DIPLOMA,Rect2(p-Vector2(20,15),Vector2(40,30)),false)
