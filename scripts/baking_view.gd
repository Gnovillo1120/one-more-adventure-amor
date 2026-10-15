extends Control
## Spatial kitchen + resumable counter interactions; every visual reflects session state.
signal changed
signal completed(kind: String)
signal reaction(kind: String, points: int)
const Session = preload("res://scripts/baking_session.gd")
const COUNTER = preload("res://assets/art/baking/counter.png")
const Choreography = preload("res://scripts/baking_animation.gd")
var animation = Choreography.new()
var transition_pending := false
var pending_leave := false
var session: RefCounted
var game: Node
var panel: Control
var status: Label
var detail: Label
var progress: ProgressBar
var pouring := false
var whisk := false
var grabbed := false
var tray_selected := 0
var last_angle := 0.0
var save_clock := 0.0
var helper_clock := 0.0
var gather_source := ""
var gather_time := 0.0
var egg_fx := 0.0
var mix_done_button: Button
var gather_ids: Array = []
var gather_index := 0
var ingredient_buttons: Array[Button] = []
var textures: Dictionary = {}
var containers: Dictionary = {}
const STATIONS := {"pantry":[1160,320],"fridge":[280,310],"sink":[595,305],"counter":[640,555],"oven":[945,315],"rack":[975,555]}
const TITLES := {"intro":"Una cocina para dos","quiz":"Antes de empezar…","gather":"Reunir ingredientes","measure":"Medir con calma","dry":"Batir los secos","cream":"Mantequilla y ambos azúcares","eggs":"Huevos uno a uno · después vainilla","combine":"Secos, poco a poco","oats":"Ahora sí: la avena","chill":"Una hora de paciencia","preheat":"Precalentar el horno","tray":"Bolitas del tamaño de una nuez","flatten":"Agua, azúcar y tenedor","oven":"Que queden doraditas","cool":"Cinco minutos en la bandeja","taste":"La primera galleta es para compartir","result":"Nuestra tanda"}

func setup(owner: Node, _kind: String, recipe: Dictionary, saved: Dictionary = {}) -> void:
	game=owner;session=Session.new();session.setup("cookies",recipe,saved)
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for id in ["bowl","cup","whisk","egg","tray","fork","mitt","rack","jar"]:textures[id]=load("res://assets/art/baking/%s.png"%id)
	containers=JSON.parse_string(FileAccess.get_file_as_string("res://data/baking_containers.json"))
	for id in containers:textures["ingredient_"+id]=load(containers[id].art)
	game.memory.baking=self
	show_station("counter") if session.state.phase in ["intro","quiz","result"] else leave_counter()

func targets() -> Array:
	var result: Array=[]
	for id in STATIONS:
		result.append({"id":"baking:"+id,"label":{"pantry":"Despensa · ingredientes","fridge":"Frigorífico · mantequilla / huevos / reposo","sink":"Agua y utensilios","counter":"Preparar la masa","oven":"Horno · 190°C","rack":"Rejilla · enfriar y probar"}[id],"position":STATIONS[id],"kind":"baking"})
	return result

func in_kitchen() -> bool:
	return session.state.station==""

func missing_ingredients() -> Array:
	return session.data.ingredients.filter(func(item: Dictionary):return not session.state.pantry.has(item.id))

func kitchen_objective() -> void:
	if session.state.phase=="gather":
		game._set_objective("Reunir ingredientes · %d / %d · %s · encimera al terminar"%[session.data.ingredients.size()-missing_ingredients().size(),session.data.ingredients.size(),"utensilios listos" if session.state.tools else "agua / utensilios en el fregadero"])
	else:
		game._set_objective(TITLES[session.state.phase]+" · "+{"pantry":"despensa","fridge":"frigorífico","counter":"encimera","oven":"horno","rack":"rejilla"}[session.station_for_phase()]+" · E")

func explain(text: String) -> void:
	game.memory.living.note.position=Vector2(130,155)
	game.memory.living.note.size=Vector2(1020,100)
	game.memory.living.note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	game.memory.living.announce(text)
	game._sfx("interact")

func show_station(id: String) -> void:
	if game.is_paused:return
	var phase: String=session.state.phase
	if phase=="gather" and id in ["pantry","fridge","sink"]:
		var gathered: Array=[]
		for item in session.data.ingredients:
			var source: String="fridge" if item.id in ["eggs","butter"] else "sink" if item.id=="water" else "pantry"
			if source==id and not session.state.pantry.has(item.id):
				session.state.pantry.append(item.id);gathered.append(item.name)
		if id=="sink":session.state.tools=true
		if not gathered.is_empty():gather_source=id;gather_time=1.5
		changed.emit();kitchen_objective()
		explain("Recogido: "+", ".join(gathered)+(" · bol, batidor, cucharas, bandeja y tenedor listos." if id=="sink" else ".") if not gathered.is_empty() else "Ya recogimos todo de aquí."+(" Utensilios listos." if id=="sink" else ""))
		return
	if phase=="gather" and id=="counter":
		var missing:=missing_ingredients()
		if not missing.is_empty() or not session.state.tools:
			var names: Array=missing.map(func(item: Dictionary):return item.name)
			if not session.state.tools:names.append("utensilios del fregadero")
			explain("Antes de mezclar, faltan: "+", ".join(names)+".");return
		session.act("gather");changed.emit();phase=session.state.phase
	if id=="sink":
		session.state.tools=true
		if session.state.phase=="gather" and not session.state.pantry.has("water"):session.state.pantry.append("water")
		changed.emit()
		game.memory.living.announce("Agua para el tenedor; bol, batidor, cucharas y bandeja listos.")
		game._sfx("interact");return
	if phase=="gather" and id=="fridge":session.state.station="fridge"
	elif id!=session.station_for_phase() and phase not in ["intro","quiz","result"]:
		explain("Siguiente: "+str(TITLES[phase])+" · "+{"pantry":"despensa","fridge":"frigorífico","counter":"encimera","oven":"horno","rack":"rejilla"}[session.station_for_phase()]);return
	else:session.state.station=id
	redraw()

func leave_counter() -> void:
	transition_pending=false;pending_leave=false
	pouring=false;whisk=false;grabbed=false;session.state.station=""
	if is_instance_valid(panel):remove_child(panel);panel.queue_free();panel=null
	game.modal=null;game.memory.active=true;mouse_filter=Control.MOUSE_FILTER_IGNORE
	kitchen_objective()
	changed.emit();queue_redraw()

func act(id: String, value: Variant = null) -> void:
	if transition_pending:return
	if id=="continue" and session.state.phase=="result":completed.emit("cookies");return
	var previous: String=session.state.phase
	var visual_before: Dictionary=session.state.duplicate(true)
	if not session.act(id,value):return
	animation.start(id,visual_before,session.state.portions[-1] if id=="portion" else value)
	if id in ["measure","tap","crack","add","flatten","portion","dip","insert","pull","rack","taste"]:
		transition_pending=true
	if id=="crack":egg_fx=.8;grabbed=false
	if id=="quiz":game.memory.living.announce("¡Eso! Medir, huevos uno a uno y reposar la masa." if int(value)==0 else "Lo hacemos con calma: medir, huevos uno a uno y una hora de reposo.")
	if id=="taste":game.memory.companion_position=Vector2(975,535);game.memory.living.pose("affection",1.4)
	changed.emit()
	if id not in ["mix","pour"]:game._sfx("interact")
	if session.state.phase!=previous:
		pouring=false;whisk=false;grabbed=false
		if session.state.phase in ["gather","chill","preheat","tray","oven","cool","taste"]:
			if transition_pending:
				pending_leave=true;session.state.station=visual_before.station;return
			leave_counter();return
	if transition_pending:return # Keep this action's instructions until its motion finishes.
	redraw() if id not in ["mix","pour","tap"] else update_live()

func button(text: String, rect: Rect2, callback: Callable) -> Button:
	return game._button(panel,text,rect,callback)

func redraw() -> void:
	if session.state.phase=="flatten" and session.state.flat.has(tray_selected):
		for offset in range(1,7):
			var next: int=posmod(tray_selected+offset,6)
			if not session.state.flat.has(next):tray_selected=next;break
	mix_done_button=null
	ingredient_buttons.clear()
	if is_instance_valid(panel):remove_child(panel);panel.queue_free()
	panel=Control.new();panel.size=Vector2(1280,720);panel.mouse_filter=Control.MOUSE_FILTER_STOP;add_child(panel)
	panel.gui_input.connect(pointer)
	game.modal=self;game.memory.active=false;mouse_filter=Control.MOUSE_FILTER_STOP
	game._panel(panel,Rect2(36,22,1208,112),.96)
	game._label(panel,TITLES[session.state.phase],Rect2(58,32,755,40),30,game.GOLD)
	detail=game._label(panel,"",Rect2(58,77,1120,42),20)
	status=game._label(panel,"",Rect2(220,536,840,44),23,game.CREAM);status.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	button("← Cocina · Tab",Rect2(1015,32,210,36),leave_counter)
	button("Receta · F1",Rect2(825,32,175,36),recipe_card)
	progress=ProgressBar.new();progress.position=Vector2(365,580);progress.size=Vector2(550,20);progress.max_value=1;progress.show_percentage=false;panel.add_child(progress)
	var phase: String=session.state.phase
	match phase:
		"intro":
			detail.text="Una receta, dos ayudantes y ninguna nota para el amor."
			button("Prepararnos · Enter",Rect2(435,590,410,48),func():act("start"))
		"quiz":
			var questions: Array=["¿Cómo empezamos?","¿Cuándo incorporamos los huevos?","¿Qué hacemos antes de formar las bolitas?"]
			var options: Array=[["Medir y batir los secos","Echar todo a ojo"],["Uno a uno, luego vainilla","Todos de golpe"],["Reposar la masa 1 hora","Directo al horno"]]
			detail.text=questions[int(session.state.index)]+" · %d / 3"%(session.state.index+1)
			for i in range(2):button("%d · %s"%[i+1,options[int(session.state.index)][i]],Rect2(360,370+i*65,560,52),func():act("quiz",i))
		"gather":
			detail.text="Flechas + Espacio: elegir · huevos / mantequilla en el frigorífico · agua / utensilios en el fregadero."
			var ids: Array=["butter","eggs"] if session.state.station=="fridge" else session.data.pantry.filter(func(i: Dictionary):return i.id not in ["butter","eggs"]).map(func(i: Dictionary):return i.id)
			gather_ids=ids;gather_index=clampi(gather_index,0,ids.size()-1)
			for i in range(ids.size()):
				var id: String=ids[i];var item: Dictionary=session.data.pantry.filter(func(o: Dictionary):return o.id==id)[0]
				ingredient_buttons.append(button(("✓ " if session.state.pantry.has(id) else "○ ")+item.name,Rect2(160+(i%3)*330,168+(i/3)*64,320,52),func():act("ingredient",id)))
			ingredient_buttons[gather_index].grab_focus()
			button("Llevar a la encimera · Enter",Rect2(410,615,460,48),func():act("gather"))
		"measure":
			var item: Dictionary=session.ingredients_to_measure()[int(session.state.index)]
			detail.text="%s · objetivo %s %s · %d / %d"%[item.name,item.quantity,item.unit,session.state.index+1,session.ingredients_to_measure().size()]
			button("Vaciar · R",Rect2(220,620,220,48),func():act("empty"))
			button("Añadir al bol · Enter",Rect2(775,620,300,48),func():act("measure"))
			var pour_button:=button("Mantener para verter",Rect2(465,620,280,48),func():pass)
			pour_button.button_down.connect(func():pouring=true)
			pour_button.button_up.connect(func():pouring=false)
		"dry","cream","combine","oats":
			detail.text={"dry":"Harina, canela, bicarbonato y sal: bol de secos.","cream":"Mantequilla blanda + azúcar blanca + morena: cremar 2–3 minutos (tiempo abreviado).","combine":"Incorpora tres porciones de secos antes de mezclar.","oats":"Incorpora la avena en tres porciones; distribúyela bien."}[phase]
			if phase in ["combine","oats"] and session.state.additions<3:button("Añadir porción · A",Rect2(420,620,440,48),func():act("add"))
			elif session.state.mix>=1:button("Listo · Enter",Rect2(420,620,440,48),func():act("mixed"))
		"eggs":
			detail.text="Coge el huevo. Dos toques suaves en el borde; ábrelo sobre el bol. Uno a uno."
			button("Coger huevo · G",Rect2(150,620,280,48),func():grabbed=true)
			button("Tocar borde · T",Rect2(470,620,280,48),func():if grabbed:act("tap"))
			button("Abrir sobre bol · Enter",Rect2(790,620,330,48),func():if grabbed:act("crack"))
		"chill":
			detail.text="El reposo hace que la masa mantenga su forma. Saltamos una hora, juntos."
			button("Guardar · una hora después…",Rect2(400,620,480,48),func():act("chill"))
		"preheat":
			detail.text="La receta pide 375°F / 190°C. Ajusta antes de preparar la bandeja."
			for i in range(3):button("%d°C"%[160,190,220][i],Rect2(310+i*225,400,210,48),func():act("temperature",[160,190,220][i]))
			button("Precalentar · Enter",Rect2(425,620,430,48),func():act("preheat"))
		"tray":
			detail.text="Rocía la bandeja. Coloca seis porciones representativas, separadas 2 pulgadas."
			button("Spray · S",Rect2(145,620,240,48),func():act("spray"))
			button("Recolocar · R",Rect2(430,620,240,48),func():act("reset_tray"))
			if session.state.portions.size()==6:button("Al tenedor · Enter",Rect2(750,620,350,48),func():act("portioned"))
		"flatten":
			detail.text="Moja el tenedor en agua y azúcar antes de cada galleta. Clic en la bolita."
			button("Agua + azúcar · D",Rect2(420,620,440,48),func():act("dip"))
		"oven":
			detail.text="8–10 minutos: dorado claro. Cambia de rejilla a mitad. Tiempo de juego abreviado."
			button("Manoplas · M",Rect2(120,620,260,48),func():act("mitts"))
			button("Cambiar rejilla · S",Rect2(430,620,320,48),func():act("swap"))
			button("Sacar bandeja · Enter" if session.state.inserted else "Insertar bandeja · Enter",Rect2(800,620,350,48),func():act("pull" if session.state.inserted else "insert"))
		"cool":
			detail.text="La bandeja sigue caliente. Cinco minutos abreviados, después la rejilla."
			button("Pasar a rejilla · Enter",Rect2(420,620,440,48),func():act("rack"))
		"taste":
			detail.text="Ya frías. ¿Probamos? Una tanda imperfecta también es un recuerdo."
			button("Compartir una · Enter",Rect2(420,620,440,48),func():act("taste"))
		"result":
			detail.text="Sabor: %d%% · %s · primera y última tanda guardadas en el libro."%[session.state.score,session.quality()]
			status.text="Guillermo: ¡Ahora sí! · Anami: una para ti y una para mí." if session.state.score>=90 else "Guillermo: receta discutible. · Anami: compañía perfecta."
			button("Guardar el recuerdo · Enter",Rect2(420,620,440,48),func():act("continue"))
	update_live();queue_redraw()

func update_live() -> void:
	if not is_instance_valid(status):return
	var s: Dictionary=session.state
	progress.visible=s.phase in ["measure","dry","cream","combine","oats","cool"]
	progress.value=float(s.fill)/2 if s.phase=="measure" else float(s.minutes)/15 if s.phase=="oven" else float(s.cool)/5 if s.phase=="cool" else float(s.mix)
	if s.phase=="measure":status.text="%0.2f / %s · mantener Espacio o clic para verter"%[float(s.fill)*float(session.ingredients_to_measure()[int(s.index)].quantity),session.ingredients_to_measure()[int(s.index)].quantity]
	elif s.phase in Session.MIX_PHASES:status.text="%d%% · coge el batidor y haz círculos · o mantén Espacio"%roundi(float(s.mix)*100)
	elif s.phase=="eggs":status.text="%d / 2 huevos · %d toques · %d fragmentos de cáscara"%[s.eggs,s.egg_taps,s.shells]
	elif s.phase=="tray":status.text="%d / 6 · clic para colocar · Enter coloca el siguiente hueco"%s.portions.size()
	elif s.phase=="flatten":status.text="%d / 6 · %s · flechas seleccionan, Enter presiona"%[s.flat.size(),"tenedor mojado" if s.dip else "moja el tenedor"]
	elif s.phase=="oven":status.text="%0.1f min · %s · %s"%[s.minutes,"manoplas listas" if s.mitts else "coge las manoplas","rejilla cambiada" if s.swapped else "cambiar a los 4 min"]
	elif s.phase=="cool":status.text="%d / 5 · el calor también necesita una pausa"%int(s.cool)
	if s.phase=="preheat":status.text="Ajustado: %d°C · 1 / 2 / 3 eligen temperatura"%s.temperature
	if s.phase in Session.MIX_PHASES and s.mix>=.25:
		if not is_instance_valid(mix_done_button):mix_done_button=button("",Rect2(420,620,440,48),func():act("mixed"))
		mix_done_button.text="Listo · Enter" if s.mix>=1 else "Terminar con esta textura · Enter"
	queue_redraw()

func key(code: int) -> void:
	if code==KEY_F1:recipe_card();return
	if code==KEY_TAB:leave_counter();return
	if transition_pending:return
	if session.state.station=="":return
	var s: Dictionary=session.state
	if s.phase=="gather":
		if code in [KEY_LEFT,KEY_RIGHT,KEY_UP,KEY_DOWN]:
			gather_index=posmod(gather_index+{KEY_LEFT:-1,KEY_RIGHT:1,KEY_UP:-3,KEY_DOWN:3}[code],gather_ids.size());ingredient_buttons[gather_index].grab_focus();return
		if code==KEY_SPACE:act("ingredient",gather_ids[gather_index]);return
	if s.phase=="preheat" and code in [KEY_1,KEY_2,KEY_3]:act("temperature",[160,190,220][code-KEY_1])
	if s.phase=="quiz" and code in [KEY_1,KEY_2]:act("quiz",code-KEY_1)
	if code==KEY_R:act("empty" if s.phase=="measure" else "reset_tray")
	if code==KEY_A:act("add")
	if code==KEY_G:grabbed=true
	if code==KEY_T and grabbed:act("tap")
	if code==KEY_D:act("dip")
	if code==KEY_M:act("mitts")
	if code==KEY_S:act("spray" if s.phase=="tray" else "swap")
	if code in [KEY_LEFT,KEY_RIGHT]:tray_selected=posmod(tray_selected+(1 if code==KEY_RIGHT else -1),6);queue_redraw()
	if code!=KEY_ENTER:return
	match s.phase:
		"intro":act("start")
		"gather":act("gather")
		"measure":act("measure")
		"dry","cream","combine","oats":act("mixed")
		"eggs":if grabbed:act("crack")
		"chill":act("chill")
		"preheat":act("preheat")
		"tray":
			if s.portions.size()<6:act("portion",session.default_portions()[s.portions.size()])
			else:act("portioned")
		"flatten":act("flatten",tray_selected);tray_selected=posmod(tray_selected+1,6)
		"oven":act("pull" if s.inserted else "insert")
		"cool":act("rack")
		"taste":act("taste")
		"result":act("continue")

func pointer(event: InputEvent) -> void:
	if transition_pending:return
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		if not event.pressed:pouring=false;whisk=false;return
		var p: Vector2=event.position;var phase: String=session.state.phase
		if phase=="measure" and Rect2(260,210,220,270).has_point(p):pouring=true
		if phase in Session.MIX_PHASES and Rect2(430,190,400,330).has_point(p):whisk=true;last_angle=(p-Vector2(640,355)).angle()
		if phase=="eggs":
			if Rect2(200,260,200,200).has_point(p):grabbed=true
			elif grabbed and Rect2(430,260,380,65).has_point(p):act("tap")
			elif grabbed and Rect2(450,330,350,170).has_point(p):act("crack")
		if phase=="tray" and Rect2(355,220,570,270).has_point(p):act("portion",[(p.x-355)/570,(p.y-220)/270])
		if phase=="flatten":
			for i in range(6):
				var pos: Array=session.state.portions[i]
				if p.distance_to(Vector2(355+float(pos[0])*570,220+float(pos[1])*270))<40:tray_selected=i;act("flatten",i);break
	if event is InputEventMouseMotion and whisk:
		var angle: float=(event.position-Vector2(640,355)).angle()
		var motion: float=absf(wrapf(angle-last_angle,-PI,PI));last_angle=angle
		if event.position.distance_to(Vector2(640,355))>40:act("mix",minf(.08,motion*.055))

func _process(delta: float) -> void:
	if not is_instance_valid(game) or not is_instance_valid(game.memory) or game.is_paused:return
	var s: Dictionary=session.state
	animation.tick(delta)
	if transition_pending:queue_redraw()
	gather_time=maxf(0,gather_time-delta)
	if transition_pending and animation.elapsed>=animation.duration:
		transition_pending=false
		if pending_leave:leave_counter();return
		redraw()
	egg_fx=maxf(0,egg_fx-delta)
	session.tick(delta)
	if s.station!="":
		if not transition_pending and s.phase=="measure" and (pouring or Input.is_physical_key_pressed(KEY_SPACE)):session.act("pour",delta*.28)
		if s.phase in Session.MIX_PHASES and Input.is_physical_key_pressed(KEY_SPACE):session.act("mix",delta*.2)
		if not transition_pending:update_live()
	if s.phase=="quiz":
		helper_clock+=delta
		if gather_time==0:gather_source="fridge" if int(helper_clock/4)%2==0 else "sink";gather_time=1.5
		game.memory.companion_position=Vector2(300+absf(sin(helper_clock*.45))*350,300)
		game.memory.actors.guillermo.row=2 if sin(helper_clock*.45)*cos(helper_clock*.45)>0 else 1
		game.memory.actors.guillermo.column=int(helper_clock*7)%4
	save_clock+=delta
	if save_clock>1:save_clock=0;changed.emit()

func sprite(id: String, rect: Rect2, color: Color = Color.WHITE) -> void:
	draw_texture_rect(textures[id],rect,false,color)

func _draw() -> void:
	if not is_instance_valid(session) or session.state.station=="":return
	var s: Dictionary=session.state
	if s.phase in ["intro","quiz","gather"]:return
	draw_texture_rect(COUNTER,Rect2(0,0,1280,720),false)
	draw_rect(Rect2(210,530,860,78),Color("47382ed9"))
	animation.render(self)

func recipe_card() -> void:
	if not is_instance_valid(panel):show_station(session.station_for_phase());return
	var card: Control=game._panel(panel,Rect2(245,140,790,455),.98)
	game._label(card,"Nuestra receta · ~24 galletas",Rect2(25,16,735,35),26,game.GOLD)
	var text: String=""
	for item in session.data.ingredients:text+="%s: %s %s\n"%[item.name,item.quantity,item.unit]
	text+="\nReposo 1 h · horno 190°C · 8–10 min · rejilla a mitad"
	game._label(card,text,Rect2(25,58,735,330),18)
	game._button(card,"Volver a cocinar",Rect2(245,395,300,42),card.queue_free)
