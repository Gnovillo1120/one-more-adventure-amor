extends Node2D
## Optional activities retain semantic state independently of their sprite frames.
signal changed
signal outfit_finished
const PEOPLE = preload("res://assets/art/living/ambient_people.png")
const ACTIONS = preload("res://assets/art/living/anami_actions.png")
const Actor = preload("res://scripts/memory_actor.gd")
const Anim = preload("res://scripts/character_animation.gd")
const PhotoAction = preload("res://scripts/photo_action.gd")
var photo_action: Node2D
const POOL = Rect2(365,310,560,215)
const BEDROOM = preload("res://assets/art/living/bedroom.png")
const CLUB_POOL = preload("res://assets/art/living/club_pool.png")
var world: Node2D
var state: Dictionary = {"zone":"main","swimwear":false,"swimming":false,"drink":false,"sitting":false,"pieces":[],"outfit_phase":"idle","remaining":75.0,"photo":false,"photo_count":0,"encounter":false,"unread":true,"photo_file":"","romance":false,"affection_frame":0}
var props: Dictionary = {}
var activities: Array = []
var guests: Array = []
var action := ""
var action_time := 0.0
var action_duration := 0.0
var frame := 0
var busy := false
var note: Label
var timer_label: Label
var chatter_wait := 8.0
var duration := 75.0
var phone_dim: ColorRect
var phone_open := false
var phone_tween: Tween
var phone_token := 0
var activity_tween: Tween
var note_tween: Tween
var pool_art: Dictionary = {}
var main_blockers: Array[Rect2] = []
var carried_drink: Sprite2D
var held_phone: Sprite2D
var swim_animation := "swim_idle"
var pool_transition := ""
var transition_time := 0.0
var transition_origin := Vector2.ZERO
var transition_destination := Vector2.ZERO
var splash_time := 0.0
var animation_clock := 0.0
var animation_key := ""

func _ready() -> void:
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	for id in ["changing_room","ladder","lounger","umbrella"]:pool_art[id]=load("res://assets/art/living/%s.png"%id)
	note=Label.new();note.position=Vector2(315,155);note.size=Vector2(670,54);note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;note.add_theme_font_size_override("font_size",20);note.modulate=Color("ffe0af");note.z_index=30;add_child(note)
	note.add_theme_color_override("font_shadow_color",Color("152331"));note.add_theme_constant_override("shadow_offset_x",2);note.add_theme_constant_override("shadow_offset_y",2)
	note.add_theme_font_override("font",load("res://assets/fonts/PixelifySans.ttf"))
	timer_label=Label.new();timer_label.position=Vector2(320,110);timer_label.size=Vector2(700,40);timer_label.add_theme_font_size_override("font_size",22);timer_label.z_index=30;add_child(timer_label)
	timer_label.add_theme_font_override("font",load("res://assets/fonts/PixelifySans.ttf"));timer_label.add_theme_color_override("font_color",Color("ffe0af"))
	carried_drink=Sprite2D.new();carried_drink.texture=load("res://assets/art/living/drink.png");carried_drink.position=Vector2(18,-34);carried_drink.scale=Vector2(.35,.35);world.actors.anami.add_child(carried_drink);carried_drink.hide()
	held_phone=Sprite2D.new();held_phone.texture=load("res://assets/art/living/phone.png");held_phone.position=Vector2(20,-38);held_phone.scale=Vector2(.28,.28);world.actors.anami.add_child(held_phone);held_phone.hide()
	photo_action=PhotoAction.new();photo_action.living=self;photo_action.z_index=3;world.actors.anami.add_child(photo_action)
	if world.location=="yacht":
		prop("bench",Vector2(390,410),Vector2(144,112));activity("sit","Sentarse / levantarse",Vector2(390,435))
		prop("bar",Vector2(1000,410),Vector2(190,140));activity("drink","Pedir / guardar bebida del club",Vector2(950,440))
		activity("sip","Dar un sorbito",Vector2(440,435))
		prop("changing_room",Vector2(1150,475),Vector2(100,150));activity("wing","Ir a la piscina",Vector2(1140,500))
		world.blockers.append(Rect2(335,345,110,55));world.blockers.append(Rect2(930,330,155,75));world.blockers.append(Rect2(1110,365,80,90))
	elif world.location=="lobby":
		prop("fountain",Vector2(440,470),Vector2(112,112));activity("water","Tomar agua",Vector2(440,485))
		activity("photo","Foto de recuerdo del modelo",Vector2(1020,540))
		world.blockers.append(Rect2(405,405,70,65))
	elif world.scene_id=="invitation":
		prop("bed",Vector2(345,350),Vector2(220,190));prop("wardrobe",Vector2(620,310),Vector2(190,170));prop("mirror",Vector2(890,350),Vector2(115,170));prop("desk",Vector2(1070,400),Vector2(170,160))
		prop("dress",Vector2(600,390),Vector2(68,68));prop("sneakers",Vector2(420,525),Vector2(68,68))
		prop("bandana",Vector2(865,365),Vector2(48,48),"res://assets/art/sprites/bandana.png")
		activity("dress","Buscar vestido de denim",Vector2(600,405));activity("bandana","Buscar bandana roja",Vector2(890,385));activity("sneakers","Buscar zapatillas blancas",Vector2(420,540))
		activity("distractor","Revisar ropa de invierno",Vector2(670,350));activity("mirror","Mirarse / volver a intentar",Vector2(925,405))
		for area in [Rect2(255,250,180,80),Rect2(550,225,140,75),Rect2(855,240,65,85),Rect2(1010,320,130,65)]:world.blockers.append(area)
		world.actors.guillermo.hide()
	elif world.scene_id=="reconnect":
		prop("desk",Vector2(360,495),Vector2(140,128))
		var draft: Node2D=world.target_visuals.get("draft")
		if is_instance_valid(draft):draft.descriptor={"fixture":"living_desk"};draft.environment_object=props.desk;draft.queue_redraw()
	elif world.location in ["party","pool"]:
		prop("bar",Vector2(355,360),Vector2(180,130));prop("bench",Vector2(1030,410),Vector2(144,110));prop("umbrella",Vector2(1130,350),Vector2(128,140))
		activity("party_photo","Foto de la fiesta",Vector2(390,460));activity("dance","Un baile extra",Vector2(675,500))
		world.blockers.append(Rect2(285,280,140,70))
	main_blockers.assign(world.blockers);populate()
	changed.connect(func():queue_redraw())

func prop(id: String, p: Vector2, size: Vector2, path: String="") -> void:
	var sprite:=Sprite2D.new();sprite.texture=load("res://assets/art/living/%s.png"%id if path=="" else path);sprite.position=p-Vector2(0,size.y/2-6);sprite.scale=size/Vector2(sprite.texture.get_size());sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	var anchor:=Node2D.new();anchor.position=p;anchor.set_meta("rendered_fixture",true);world.depth_root.add_child(anchor);sprite.position-=p;anchor.add_child(sprite);props[id]=anchor

func activity(id: String, label: String, p: Vector2) -> void:
	activities.append({"id":"living:"+id,"label":label,"position":[p.x,p.y],"kind":"living","lines":[]})

func targets() -> Array:
	if state.zone=="pool":
		return [{"id":"living:back","label":"Volver al paseo","position":[1130,550],"kind":"living"},{"id":"living:change","label":"Cambiarse","position":[280,430],"kind":"living"},{"id":"living:swim","label":"Entrar / salir por la escalera","position":[355,510],"kind":"living"}]
	var result: Array=activities.duplicate(true)
	if world.scene_id=="invitation" and state.outfit_phase!="active":
		result=result.filter(func(t: Dictionary):return t.id in ["living:mirror","living:distractor"])
	return result

func restore(saved: Dictionary) -> void:
	for key in state:
		if saved.has(key):state[key]=saved[key]
	state.pieces=state.pieces.duplicate()
	if state.photo:state.photo_count=1
	if state.swimming and (world.location!="yacht" or state.zone!="pool" or not state.swimwear):state.swimming=false
	if state.zone=="pool":state.sitting=false;world.seated=false
	if state.zone=="pool":world.blockers.clear()
	pool_transition="";busy=false
	update_outfit();update_visibility()

func snapshot() -> Dictionary:
	var result: Dictionary=state.duplicate(true);result["phone_open"]=phone_open;return result

func can_move() -> bool:
	return not busy and not phone_open and action not in ["phone","outfit","surprise"]

func start_pool_transition() -> void:
	if pool_transition!="":return
	phone(false);action="";state.sitting=false;world.seated=false;world.moving=false
	pool_transition="exit_pool" if state.swimming else "enter_pool"
	transition_time=0;busy=true
	# Semantic destination is saved immediately. Reload resolves to its legal bank.
	state.swimming=pool_transition=="enter_pool"
	transition_origin=Vector2(395,495) if pool_transition=="exit_pool" else Vector2(335,540)
	transition_destination=Vector2(395,495) if state.swimming else Vector2(335,540)
	world.player_position=transition_origin

func tick_pool_transition(delta: float) -> void:
	transition_time=minf(.85,transition_time+delta)
	world.player_position=transition_origin.lerp(transition_destination,smoothstep(0.0,.85,transition_time))
	if transition_time>=.85:
		world.player_position=transition_destination;pool_transition="";busy=false;world.active=true;splash_time=.65;changed.emit()

func update_visibility() -> void:
	for id in props:props[id].visible=state.zone=="main"
	for guest in guests:guest.actor.visible=state.zone=="main"
	for entry in world.population_actors:entry.actor.visible=state.zone=="main"
	for id in world.target_visuals:
		if state.zone!="main":world.target_visuals[id].hide()

func legal_position(p: Vector2) -> bool:
	if state.zone!="pool":return true
	if state.swimming:return POOL.grow(-14).has_point(p)
	return not POOL.grow(12).has_point(p) and not Rect2(195,240,160,145).has_point(p)

func announce(text: String) -> void:
	if is_instance_valid(note_tween):note_tween.kill()
	note.text=text;note.modulate.a=1
	note_tween=create_tween();note_tween.tween_interval(3.5);note_tween.tween_property(note,"modulate:a",0.0,.5)

func pose(value: String, seconds: float) -> void:
	action=value;action_time=0;action_duration=seconds

func perform(id: String) -> void:
	if busy:return
	if state.swimming and id.trim_prefix("living:")!="swim":return
	match id.trim_prefix("living:"):
		"sit":state.sitting=not state.sitting;world.seated=state.sitting;pose("sit",1.0);announce("Cinco minutos mirando el mar. Sin revisar el visto.")
		"drink":state.drink=not state.drink;pose("drink",1.6);announce("Una bebida del club, sin nombre histórico. La puedes llevar al agua." if state.drink else "La dejo en la barra.")
		"sip":
			if state.drink:pose("drink",1.8);announce("Un sorbito y el ruido del mar.")
			else:announce("Primero podemos pasar por la barra.")
		"wing":
			state.zone="pool";state.sitting=false;world.seated=false;action="";world.blockers.clear();world.player_position=Vector2(1100,550);update_visibility()
		"back":
			if state.swimwear:announce("Me cambio antes de volver al paseo.");return
			state.zone="main";world.blockers.assign(main_blockers);world.player_position=Vector2(1080,520);update_visibility()
		"change":
			if state.swimming:return
			state.swimwear=not state.swimwear;pose("outfit",.8);update_outfit();announce("Lista para la piscina." if state.swimwear else "De vuelta a mi ropa.")
		"swim":
			if not state.swimwear:announce("La caseta está a la izquierda. Primero el traje de baño.");return
			start_pool_transition()
		"water":
			if not world.optional_seen.has("water"):world.optional_seen.append("water")
			drink_fountain()
		"dress","bandana","sneakers":equip(id.trim_prefix("living:"))
		"distractor":announce("¡Suéter de invierno en Salinas! Mejor el vestido de denim.")
		"mirror":
			if state.outfit_phase=="failed":start_outfit()
			else:pose("outfit",1.3);announce("Denim, bandana roja y zapatillas blancas. Ese es el plan.")
		"photo","party_photo":
			phone(false);action="";world.seated=false;state.sitting=false;photo_action.start()
		"dance":pose("dance",5);announce("Un baile extra: pulsa espacio al ritmo. Y si no sale, nos reímos igual.");state["dance_started"]=world.clock;state["dance_hits"]=0
	changed.emit()

func capture_photo() -> void:
	if DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	if not is_inside_tree():return
	var path: String="user://living_photo_%s.png"%world.scene_id
	if world.get_parent().test_mode:path="user://qa_living_photo_%s.png"%world.scene_id
	if get_viewport().get_texture().get_image().save_png(path)==OK:state.photo_file=path;changed.emit()

func flash() -> void:
	var light:=ColorRect.new();light.size=Vector2(1280,720);light.color=Color(1,1,1,.7);light.mouse_filter=Control.MOUSE_FILTER_IGNORE;light.z_index=40;add_child(light)
	var tween:=create_tween();tween.tween_property(light,"modulate:a",0.0,.35);tween.tween_callback(light.queue_free)

func dance_beat() -> bool:
	if action!="dance":return false
	var beat: float=fmod(action_time,.65)
	if (beat<.16 or beat>.49) and absf(action_time-float(state.get("last_beat",-10)))>.3:state.dance_hits+=1;state.last_beat=action_time;announce("¡Ese paso sí salió!")
	return true

func start_outfit() -> void:
	state.outfit_phase="active";state.remaining=duration;state.pieces=[];update_outfit();announce("75 segundos: vestido, bandana, zapatillas. WASD y E. El espejo permite reintentar.");changed.emit()

func equip(piece: String) -> void:
	if state.outfit_phase!="active" or piece in state.pieces:return
	var expected: String=["dress","bandana","sneakers"][state.pieces.size()]
	if piece!=expected:announce("Primero %s; después los accesorios."%{"dress":"el vestido de denim","bandana":"la bandana roja","sneakers":"las zapatillas"}[expected]);return
	state.pieces.append(piece);update_outfit();pose("outfit",.65);announce("¡Listo! %d / 3 prendas."%state.pieces.size());changed.emit()
	if state.pieces.size()==3:
		state.outfit_phase="complete";update_outfit();pose("dance",1.5);announce("Vestido de denim, bandana roja y zapatillas blancas. ¡Ahora sí!");outfit_finished.emit()

func update_outfit() -> void:
	if world.scene_id=="invitation":
		world.sprites.anami=load("res://assets/art/sprites-v2/anami_halloween.png" if state.outfit_phase=="complete" else "res://assets/art/sprites-v2/anami_casual.png")
	elif world.location=="yacht":
		world.sprites.anami=load("res://assets/art/living/anami_swimwear.png" if state.swimwear else "res://assets/art/sprites-v2/anami_casual.png")
	world.actors.anami.texture=world.sprites.anami

func drink_fountain() -> void:
	busy=true;world.active=false;world.player_position=world.safe_position(Vector2(485,485));world.direction=1;pose("drink",2.2)
	props.fountain.get_child(0).texture=load("res://assets/art/living/fountain_flow.png")
	activity_tween=create_tween();activity_tween.tween_interval(2.2);activity_tween.tween_callback(func():
		if not is_instance_valid(world):return
		props.fountain.get_child(0).texture=load("res://assets/art/living/fountain.png");busy=false;world.active=true;announce("Debatir da sed, aunque una no tenga delegación.");changed.emit())

func encounter(done: Callable) -> void:
	if state.encounter:done.call();return
	busy=true;world.active=false
	var destination: Vector2=world.safe_position(world.player_position+Vector2(36,0))
	activity_tween=create_tween();activity_tween.tween_property(world,"companion_position",destination,.85);activity_tween.tween_callback(func():state.encounter=true;pose("surprise",1.5);world.effect="ouch";world.effect_time=1.2)
	activity_tween.tween_interval(.5);activity_tween.tween_callback(func():busy=false;done.call();changed.emit())

func pause_activities(value: bool) -> void:
	if is_instance_valid(activity_tween):
		if value:activity_tween.pause()
		else:activity_tween.play()

func phone(value: bool) -> void:
	if value and (state.swimming or pool_transition!="" or busy):return
	phone_open=value;phone_token+=1
	if value:state.unread=false
	if is_instance_valid(phone_tween):phone_tween.kill()
	if value:
		pose("phone",3600)
		if not is_instance_valid(world.phone_ui):world._build_phone()
		if not is_instance_valid(phone_dim):
			phone_dim=ColorRect.new();phone_dim.size=Vector2(1280,720);phone_dim.color=Color(0.04,.07,.1,.4);phone_dim.mouse_filter=Control.MOUSE_FILTER_IGNORE;phone_dim.z_index=19;world.add_child(phone_dim)
		phone_dim.show();world.phone_ui.show();world.phone_ui.modulate.a=0;world.phone_ui.position.y=162
		phone_tween=create_tween();phone_tween.tween_interval(.22);phone_tween.tween_property(world.phone_ui,"modulate:a",1.0,.2);phone_tween.parallel().tween_property(world.phone_ui,"position:y",145.0,.2)
	else:
		pose("phone",.4)
		if is_instance_valid(phone_dim):phone_dim.hide()
		if is_instance_valid(world.phone_ui):
			phone_tween=create_tween();phone_tween.tween_property(world.phone_ui,"modulate:a",0.0,.18);phone_tween.tween_callback(world.phone_ui.hide)

func populate() -> void:
	var count:=30 if world.location in ["party","pool"] else 10 if world.location in ["lobby","yacht","debate"] else 0
	for i in range(count):
		var actor: Node2D=Actor.new();actor.world=world;actor.npc=true;actor.texture=PEOPLE;actor.atlas_row=4+(i+int(i/8)*2)%4 if world.location in ["party","pool"] else i%2 if world.location in ["lobby","debate"] else 2+i%2
		var centers: Array=[Vector2(210,380),Vector2(595,355),Vector2(660,370),Vector2(1010,395),Vector2(320,520),Vector2(570,510),Vector2(800,535),Vector2(1050,530)]
		var base: Vector2=world.safe_position(centers[i%8]+Vector2(sin(i*2.4)*42,cos(i*1.75)*28))
		if world.location=="lobby" and base.distance_to(Vector2(465,485))<115:base=world.safe_position(base+Vector2(120,-80))
		if world.scene_id=="pool" and base.distance_to(world.companion_position)<140:base=world.safe_position(base+Vector2(100,100))
		if world.location in ["lobby","debate"]:actor.texture=preload("res://scripts/supporting_cast.gd").sprite(i%8);actor.atlas_row=-1
		actor.position=base;world.depth_root.add_child(actor)
		guests.append({"actor":actor,"origin":base,"destination":world.safe_position(base+Vector2(55 if i%2 else -55,35 if i%3 else -35)),"wait":float(i%7)*.7,"walking":false,"index":i,"speed":25.0+i%5*7})
	if world.location in ["party","pool"]:
		for i in range(24):
			var actor: Node2D=Actor.new();actor.world=world;actor.npc=true;actor.texture=PEOPLE;actor.atlas_row=4+i%4;actor.scale=Vector2(.65,.65);actor.position=Vector2(185+(i%8)*80+sin(i)*12,260+int(i/8)*27)
			world.depth_root.add_child(actor);guests.append({"actor":actor,"origin":actor.position,"destination":actor.position,"wait":2.0+i%5,"index":i+30,"speed":0.0})
	if world.location in ["yacht","party"]:
		var bartender: Node2D=Actor.new();bartender.world=world;bartender.npc=true;bartender.texture=PEOPLE;bartender.atlas_row=3;bartender.position=Vector2(1000,410) if world.location=="yacht" else Vector2(355,365);world.depth_root.add_child(bartender)
		guests.append({"actor":bartender,"origin":bartender.position,"destination":bartender.position,"wait":6.0,"index":100,"speed":0.0})

func tick(delta: float) -> void:
	photo_action.advance(delta)
	if world.get_parent().get("is_paused")==true:return
	splash_time=maxf(0,splash_time-delta)
	if pool_transition!="":tick_pool_transition(delta)
	if action!="":
		action_time+=delta;frame=mini(3,int(action_time*6)) if action in ["phone","surprise","outfit"] else int(action_time*6)%4
		if action_time>=action_duration:action=""
		if action=="affection":frame=int(state.get("affection_frame",1))
	if state.outfit_phase=="active" and world.active:
		state.remaining=maxf(0,float(state.remaining)-delta)
		if state.remaining<=0:state.outfit_phase="failed";announce("¡Se hizo tarde! Acércate al espejo y E para reintentar. El capítulo sigue guardado.");changed.emit()
	timer_label.text="VESTIRSE · %02d s · %d / 3 prendas"%[int(ceil(state.remaining)),state.pieces.size()] if state.outfit_phase=="active" else ""
	if state.sitting and world.moving:state.sitting=false
	if world.moving and action in ["drink","sit","dance"]:action=""
	if pool_transition!="":action=pool_transition
	elif state.swimming:action=Anim.swim_state(world.direction,world.moving)
	elif action in Anim.SWIM_ROWS:action=""
	elif phone_open:action="phone";frame=1 if int(world.clock*2)%2 else 2
	elif world.dancing:action="dance";frame=int(world.clock*6)%4
	elif state.sitting and action=="":action="sit";frame=0
	elif state.drink and not world.moving and action=="":action="drink";frame=0;action_duration=.05;action_time=0
	var actor: Node2D=world.actors.anami
	actor.position=world.player_position
	var next_key: String=action+str(world.direction)+str(world.moving)
	if next_key!=animation_key:animation_clock=0;animation_key=next_key
	else:animation_clock+=delta
	actor.column=Anim.walk_frame(animation_clock,world.moving or world.dancing)
	carried_drink.visible=state.drink and action not in ["drink","sit"] and not state.swimming
	held_phone.visible=state.swimwear and phone_open
	actor.action_texture=ACTIONS;actor.action_row=["phone","drink","sit","swim","dance","surprise","affection","outfit"].find(action);actor.action_frame=frame
	actor.action_cell=Vector2(32,48)
	actor.action_offset_y=-90.0
	actor.water_pose=false
	if action=="sit":actor.action_frame=0
	if action=="phone":actor.action_frame=1 if phone_open else 0
	# Phone/drink art is casual. Preserve other outfits with held object overlays.
	var casual: bool=world.sprites.anami.resource_path.ends_with("anami_casual.png")
	if not casual and action in ["phone","drink","surprise","sit"] and not (busy and world.location=="lobby" and action=="drink"):
		actor.action_row=-1;held_phone.visible=phone_open;carried_drink.visible=state.drink
		if action=="surprise":actor.position.y-=2 if int(action_time*12)%2==0 else 0
	if action=="outfit" and (world.scene_id!="invitation" or state.pieces.is_empty()):actor.action_row=-1
	if state.swimwear:actor.action_row=-1;carried_drink.visible=state.drink and not state.swimming
	if action in Anim.SWIM_ROWS:
		swim_animation=action;actor.action_texture=Anim.SWIM;actor.action_row=Anim.SWIM_ROWS[action]
		actor.action_cell=Vector2(48,48)
		actor.action_offset_y=-90.0 if action in ["enter_pool","exit_pool"] else -50.0
		actor.water_pose=action not in ["enter_pool","exit_pool"]
		actor.action_frame=Anim.swim_frame(action,transition_time if pool_transition!="" else animation_clock)
	if busy and world.location=="lobby" and action=="drink":
		# Columns are down/left/right/up views, NOT consecutive drinking frames.
		# Hold the authored left-facing lean; move vertically by one source pixel.
		actor.action_texture=load("res://assets/art/living/anami_fountain.png")
		actor.action_row=0;actor.action_frame=1
		actor.action_offset_y=-90.0+2.0*sin(PI*clampf(action_time/2.2,0,1))
	if world.scene_id=="invitation" and state.pieces.size()>0 and state.outfit_phase!="complete":
		# These legacy stage rows are directional views, not walking cycles.
		actor.action_texture=load("res://assets/art/living/anami_outfits.png");actor.action_row=state.pieces.size()-1;actor.action_frame=world.direction
		held_phone.visible=phone_open
	if world.scene_id=="pool":
		var partner: Node2D=world.actors.guillermo
		partner.action_texture=load("res://assets/art/living/guillermo_affection.png");partner.action_row=0;partner.action_frame=int(state.affection_frame) if state.romance else 0
		if state.romance and world.seated:actor.position=world.companion_position+Vector2(-20,-30) if state.affection_frame==3 else world.companion_position+Vector2(-45,-18)
	chatter_wait-=delta
	if photo_action.running:actor.action_row=-1;carried_drink.hide();held_phone.hide()
	for guest in guests:
		var npc: Node2D=guest.actor
		if not npc.visible:continue
		if world.scene_id=="pool" and action=="affection":npc.modulate.a=.4;npc.column=0;continue
		npc.modulate.a=1
		guest.wait-=delta
		npc.walking=guest.wait<=0 and guest.speed>0
		if guest.wait>0:
			# Dance poses 1/2 only on dancers; a brief gesture 3 on chatters.
			var local_time: float=world.clock*(.7+guest.index%5*.13)+guest.index*1.37
			npc.column=1+int(local_time*3)%2 if world.location in ["party","pool"] and guest.index%3==0 else 3 if fmod(local_time,7.0)>.0 and fmod(local_time,7.0)<.55 else 0
			continue
		var step: Vector2=npc.position.direction_to(guest.destination)*guest.speed*delta
		var candidate: Vector2=npc.position+step
		var clear: bool=world.can_stand(candidate)
		if world.location=="lobby" and candidate.distance_to(Vector2(465,485))<95:clear=false
		if world.scene_id=="pool" and candidate.distance_to(world.companion_position)<120:clear=false
		if clear:npc.position=candidate;npc.column=1+int(world.clock*(3.5+guest.index%5*.4)+guest.index)%2 if guest.speed>0 else 0
		else:guest.wait=2.0
		if npc.position.distance_to(guest.destination)<4 or guest.wait>0:
			var previous: Vector2=guest.origin;guest.origin=guest.destination;guest.destination=previous;guest.wait=2.0+guest.index%5
		if chatter_wait<0 and world.active and world.player_position.distance_to(npc.position)<85:
			announce(["¿Tu comité también se alargó?","Nos vemos en la clausura."][guest.index%2] if world.location in ["lobby","debate"] else ["¡Ese disfraz está buenísimo!","Una foto y volvemos a bailar."][guest.index%2] if world.location in ["party","pool"] else ["Hoy el mar está tranquilito.","Vamos por la sombra."][guest.index%2]);chatter_wait=22.0
	queue_redraw()

func _draw() -> void:
	if world.scene_id=="invitation":
		draw_texture_rect(BEDROOM,Rect2(0,0,1280,720),false)
	if state.zone=="pool":
		draw_texture_rect(CLUB_POOL,Rect2(0,0,1280,720),false)
		for i in range(16):draw_line(Vector2(380+i*32,375+sin(world.clock+i)*5),Vector2(400+i*32,375+sin(world.clock+i)*5),Color("85c6c9"),2)
		for id in ["changing_room","ladder","lounger","umbrella"]:
			var p: Vector2={"changing_room":Vector2(280,390),"ladder":Vector2(365,535),"lounger":Vector2(1020,435),"umbrella":Vector2(1100,335)}[id]
			draw_texture_rect(pool_art[id],Rect2(p-Vector2(64,110),Vector2(128,128)),false)
	if state.swimming:
		for i in range(3):draw_arc(world.player_position+Vector2(0,-12),16+i*8+fmod(world.clock*9,8),0,TAU,12,Color(.65,.9,.95,.35),2)
	if splash_time>0:
		for i in range(6):
			var offset:=Vector2(cos(i*TAU/6),sin(i*TAU/6))*(1-splash_time/.65)*28
			draw_rect(Rect2(Vector2(395,483)+offset,Vector2(4,4)),Color(.7,.95,1,splash_time/.65))
	if world.location=="yacht" and state.zone=="main":
		for i in range(12):draw_line(Vector2(i*110+sin(world.clock*.4+i)*8,300+i%3*12),Vector2(i*110+60+sin(world.clock*.4+i)*8,300+i%3*12),Color(1,.85,.7,.25),2)
		for i in range(3):
			var bird:=Vector2(fmod(world.clock*19+i*310,1280),220+sin(world.clock+i)*8)
			draw_line(bird-Vector2(7,2),bird,Color("f3e2c0"),2);draw_line(bird,bird+Vector2(7,-2),Color("f3e2c0"),2)
