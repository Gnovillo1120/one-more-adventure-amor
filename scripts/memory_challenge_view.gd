extends Control
signal changed
signal completed(kind: String)
signal reaction(kind: String, points: int)
signal action_performed(id: String, value: Variant)
const Session = preload("res://scripts/memory_challenge_session.gd")
var session: RefCounted
var game: Node
var category := 0
var menu_page := 0
var buttons: Array[Button] = []
var body: VBoxContainer
var panel: PanelContainer
var accent := Color("ebc48a")

func setup(owner_game: Node, kind: String, data: Dictionary, saved: Dictionary) -> void:
	game=owner_game;session=Session.new();session.setup(kind,data,saved)
	position=Vector2(120,115);size=Vector2(1040,535);texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	redraw()

func label(parent: Node, text: String, font_size: int=21, color: Color=Color("f5ead6")) -> Label:
	var node:=Label.new();node.text=text;node.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;node.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	node.add_theme_font_size_override("font_size",font_size);node.add_theme_color_override("font_color",color);parent.add_child(node);return node

func button(parent: Node, text: String, callback: Callable, min_height: float=54) -> Button:
	var node:=Button.new();node.custom_minimum_size.y=min_height;node.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var style:=StyleBoxFlat.new();style.bg_color=Color("2b4050");style.border_color=accent;style.set_border_width_all(1);style.set_content_margin_all(8)
	node.add_theme_stylebox_override("normal",style);node.add_theme_stylebox_override("focus",style);parent.add_child(node)
	var margin:=MarginContainer.new();margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);margin.add_theme_constant_override("margin_left",12);margin.add_theme_constant_override("margin_right",12);margin.mouse_filter=Control.MOUSE_FILTER_IGNORE;node.add_child(margin)
	var caption:=label(margin,text,19);caption.mouse_filter=Control.MOUSE_FILTER_IGNORE
	caption.resized.connect(func():
		var font: Font=caption.get_theme_font("font")
		node.custom_minimum_size.y=maxf(min_height,caption.get_line_count()*font.get_height(19)+12))
	node.pressed.connect(func():game._sfx("menu");callback.call())
	buttons.append(node);return node

func image(parent: Node, path: String, dims: Vector2=Vector2(100,100), tint: Color=Color.WHITE) -> void:
	if not ResourceLoader.exists(path):return
	var art:=TextureRect.new();art.texture=load(path);art.custom_minimum_size=dims;art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;art.modulate=tint;art.mouse_filter=Control.MOUSE_FILTER_IGNORE;parent.add_child(art)

func act(id: String, value: Variant = null) -> void:
	if game.is_paused:return
	if id=="continue" and session.state.phase=="result" and session.state.passed:completed.emit(session.kind);return
	var previous: int=int(session.state.score)
	if not session.act(id,value):return
	if id=="retry":category=0
	action_performed.emit(id,value)
	if id=="answer":reaction.emit(session.kind,int(session.state.score)-previous)
	changed.emit();redraw()

func redraw() -> void:
	for child in get_children():remove_child(child);child.queue_free()
	buttons.clear()
	var s: Dictionary=session.state;var kind: String=session.kind
	accent=Color("81bcb7") if kind=="order" else Color("ef9dbb") if kind=="guillermo" else Color("ddae70") if kind=="cookies" else Color("e2c578")
	if kind=="guillermo" and int(s.index)>=7:accent=Color("c5a3f5")
	panel=PanelContainer.new();panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(panel)
	var style:=StyleBoxFlat.new();style.bg_color=Color("152331",.96);style.border_color=accent;style.set_border_width_all(3);style.set_content_margin_all(18);panel.add_theme_stylebox_override("panel",style)
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",10);panel.add_child(column)
	var titles: Dictionary={"debate":"UCRANIA  ↔  ADHOC · Caucus moderado","order":"IKURA · Nuestro pedido para dos","guillermo":"EL QUIZ DEFINITIVO DE GUILLERMO","cookies":"COCINA · Una receta entre los dos"}
	label(column,titles[kind],27,accent)
	var progress: String=""
	if kind in ["debate","guillermo"]:progress="%d / %d · Puntos: %d · Meta: %d" % [mini(int(s.index)+1,session.data.questions.size()),session.data.questions.size(),int(s.score),int(session.data.pass_score)]
	elif kind=="order":progress="Entrada compartida + plato de Guillermo + plato de Anami · confirma los tres juntos"
	else:progress="Despensa → medidas → mezcla → frío → horno → probar · no hay partidas perdidas"
	label(column,progress,17,accent)
	var scroll:=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;column.add_child(scroll)
	body=VBoxContainer.new();body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;body.add_theme_constant_override("separation",10);scroll.add_child(body)
	if s.phase=="intro":
		var intro: Dictionary={"debate":"Guillermo presenta su propuesta ante Chad. Anami, tienes la palabra.\nCinco intercambios: respuesta sólida +2, parcial +1, sin fundamento +0. Necesitas 7 de 10. Se premia la evidencia y la diplomacia; es una dramatización jugable.","order":"El mesero se acerca. ¿Recuerdas lo que pedimos? Selecciona los tres platos y envía el pedido completo. Cambia cualquier elección antes de confirmar.","guillermo":"Un momento, un momento… Anami del futuro, sí, TÚ.\nYa llevas tres años aguantando a Guillermo. ¿De verdad lo conoces?\n10 preguntas. Necesitas acertar al menos 8. Él probablemente se tomó demasiado en serio hacer esto.","cookies":"Reconstruyamos la receta de avena. Aproximadamente 24 galletas.\nElige ingredientes, mide y prepara la masa. Los tiempos largos se comprimen. Todas las tandas guardan el recuerdo, incluso las… experimentales."}
		label(body,intro[kind],24)
		button(body,"Comenzar · Enter",func():act("start"))
	elif s.phase=="hard_mode":
		label(body,"HARD MODE DESBLOQUEADO",38,accent);label(body,"Ahora sí, Anami. Se acabó lo fácil.",26)
		game._sfx("collect")
		button(body,"Preguntas 8–10 · Enter",func():act("hard_mode"))
	elif s.phase=="result":_result()
	elif kind in ["debate","guillermo"]:_question()
	elif kind=="order":_order()
	else:_cookies()
	if not buttons.is_empty():buttons[0].grab_focus()
	var tween:=create_tween();panel.modulate.a=.4;tween.tween_property(panel,"modulate:a",1.0,.18)
	if s.phase=="hard_mode" or (s.phase=="result" and s.passed):
		for i in range(16):
			var spark:=ColorRect.new();spark.mouse_filter=Control.MOUSE_FILTER_IGNORE;spark.color=accent;spark.size=Vector2(6,6);spark.position=Vector2(24+i*62,0);add_child(spark)
			var animation:=create_tween().set_parallel(true);animation.tween_property(spark,"position:y",480.0,.8+i*.04);animation.tween_property(spark,"modulate:a",0.0,1.2);animation.chain().tween_callback(spark.queue_free)

func _question() -> void:
	var s: Dictionary=session.state;var q: Dictionary=session.data.questions[int(s.index)]
	if session.kind=="debate":
		var row:=HBoxContainer.new();body.add_child(row);image(row,"res://assets/art/portraits/guillermo_neutral_formal.png",Vector2(110,110))
		var text:=VBoxContainer.new();text.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(text);label(text,q.argument,23);label(text,q.context,18,accent)
		if s.phase=="feedback":
			var portrait: TextureRect=row.get_child(0)
			var points: int=int(q.points[int(s.answers[-1])])
			portrait.texture=load("res://assets/art/portraits/guillermo_%s_formal.png" % ("surprised" if points==2 else "playful"))
			var gesture:=create_tween();gesture.tween_property(portrait,"modulate",accent,.15);gesture.tween_property(portrait,"modulate",Color.WHITE,.35)
			label(text,"Comité: intervención convincente · +2" if points==2 else "Comité: faltan fundamentos" if points==0 else "Comité: argumento parcial · +1",17,accent)
	else:label(body,q.question,24);image(body,q.get("image",""),Vector2(96,72))
	if s.phase=="feedback":
		label(body,s.feedback,23,accent);button(body,"Siguiente · Enter",func():act("next"));return
	for i in range(q.choices.size()):button(body,"%s · %s" % [char(65+i),q.choices[i]],func():act("answer",i),64 if session.kind=="debate" or int(s.index)==9 else 54)
	label(body,"1–%d o clic · Flechas / Tab y Enter · desplaza la lista si hace falta" % q.choices.size(),15,accent)

func _order() -> void:
	var tabs:=HBoxContainer.new();body.add_child(tabs)
	for i in range(3):
		var selected: String=session.state.order[i];var name:=str(session.data.categories[i])
		for dish in session.data.dishes:
			if dish.id==selected:name+="\n"+dish.name
		button(tabs,("● " if category==i else "")+name,func():category=i;redraw(),55)
	var pages:=HBoxContainer.new();body.add_child(pages)
	button(pages,"← Página",func():menu_page=posmod(menu_page-1,2);redraw(),32)
	label(pages,"Carta inspirada · %d / 2"%(menu_page+1),18,accent)
	button(pages,"Página →",func():menu_page=posmod(menu_page+1,2);redraw(),32)
	buttons.clear() # Number keys choose visible dishes; Q/W/R choose diner.
	var grid:=GridContainer.new();grid.columns=3;grid.add_theme_constant_override("h_separation",10);grid.add_theme_constant_override("v_separation",8);body.add_child(grid)
	for dish in session.data.dishes.slice(menu_page*6,menu_page*6+6):
		var tile:=VBoxContainer.new();tile.size_flags_horizontal=Control.SIZE_EXPAND_FILL;tile.custom_minimum_size.x=305;grid.add_child(tile)
		image(tile,dish.art,Vector2(90,55))
		label(tile,dish.get("section","")+" · "+dish.description,14,accent)
		button(tile,("✓ " if session.state.order[category]==dish.id else "")+dish.name,func():act("dish",[category,dish.id]);category=mini(category+1,2);redraw(),48)
	var submit:=button(body,"Enviar pedido completo · Enter",func():act("submit"));submit.disabled=session.state.order.has("")
	label(body,"Q/W/R: categoría · 1–6: plato · ←/→ página · Enter: enviar · todos se revisan juntos",15,accent)

func _cookies() -> void:
	var s: Dictionary=session.state
	match s.phase:
		"pantry":
			label(body,"Despensa · elige ingredientes (puedes quitar o añadir)",23)
			var grid:=GridContainer.new();grid.columns=4;body.add_child(grid)
			for item in session.data.pantry:
				var b:=button(grid,("✓ " if s.pantry.has(item.id) else "□ ")+item.name,func():act("ingredient",item.id),62);b.custom_minimum_size.x=240
			button(body,"Llevar a la mesa · Enter",func():act("gather"))
		"measure":
			var item: Dictionary=session.data.measurements[int(s.index)]
			var units: Dictionary={"cup":"tazas","teaspoon":"cucharaditas","tablespoon":"cucharadas","item":"unidades"}
			var unit: String=units.get(item.unit,item.unit)
			label(body,"Medir · "+item.name,28,accent);label(body,"Cantidad en "+unit+" · %d / %d" % [int(s.index)+1,session.data.measurements.size()])
			var row:=HBoxContainer.new();body.add_child(row)
			for amount in item.options:button(row,str(amount)+" "+unit,func():act("measure",amount),90)
		"prepare":
			var step: Dictionary=session.data.preparation[int(s.index)];label(body,"Mezcla · próximo paso",27,accent);label(body,step.detail,23)
			for option in step.options:button(body,option.label,func():act("prepare",option.id),80)
		"chill":
			label(body,"Al refrigerador · ¿cuánto reposo?",27,accent);label(body,"El juego salta el tiempo: no tendrás que esperar una hora.")
			for minutes in [0,15,60]:button(body,str(minutes)+" minutos",func():act("chill",minutes))
		"oven":
			label(body,"Precalentar el horno",28,accent)
			for temp in [160,190,220]:button(body,str(temp)+" °C"+(" / 375 °F" if temp==190 else ""),func():act("temperature",temp),70)
		"timer":
			label(body,"Al horno · temporizador",28,accent);label(body,"Cambiamos las bandejas de rejilla a mitad. Después: 5 minutos en bandeja y enfriar completamente en rejilla.",21)
			for minutes in [5,9,15]:button(body,str(minutes)+" minutos",func():act("minutes",minutes))

func _result() -> void:
	var s: Dictionary=session.state;var kind: String=session.kind
	var heading: String;var message: String
	if kind=="cookies":
		heading="¡Tanda terminada! · %d%% de sabor" % int(s.score)
		message="Ok, amor. Estas están demasiado buenas." if s.score>=90 else "No están nada mal. La próxima hacemos el doble." if s.score>=70 else "Mmm… interesante interpretación de la receta." if s.score>=40 else "Amor… ¿estamos seguros de que esto es una galleta?"
		var tray:=HBoxContainer.new();body.add_child(tray)
		image(tray,"res://assets/art/portraits/anami_happy.png",Vector2(80,80))
		for i in range(4):image(tray,"res://assets/art/sprites/cookie.png",Vector2(80,80),Color.WHITE if s.score>=70 else Color("b78563") if s.score>=40 else Color("705549"))
		image(tray,"res://assets/art/portraits/guillermo_happy.png",Vector2(80,80))
		label(body,"Anami: Ya están frías. A ver… probamos juntos.",19,accent)
	elif kind=="order":
		heading="Pedido confirmado" if s.passed else "Pedido incorrecto — Inténtalo otra vez"
		message="Mesero: Gyozas al centro, miso ramen y sushi. Enseguida les traigo." if s.passed else "Guillermo: Mmm… yo no pedí eso.\nAnami: ¿Cómo que no? ¿Seguro?\nGuillermo: Amor, es nuestra primera cita. Acuérdate bien."
	elif kind=="debate":
		heading="ADHOC convence al comité" if s.passed else "Presidencia: otra ronda"
		message="Guillermo: Bueno, tampoco hacía falta destruirme diplomáticamente.\nAnami: ¿No que tú eras el mejor delegado?\nGuillermo: Todavía no anuncian los premios, tranquila." if s.passed else "Guillermo: Esa intervención necesita otro borrador.\nPresidencia: ADHOC, retomemos. Distingue causas, acceso y responsabilidad; propone medidas concretas."
	else:
		heading="EXPERTA EN GUILLERMO · %d / 10" % int(s.score) if s.passed else "¿TRES AÑOS JUNTOS Y SACASTE ESO? · %d / 10" % int(s.score)
		message="Oficialmente certificada. Tu premio: seguir aguantándolo. Volvemos a Ikura: la comida ya llega." if s.passed else "Bueno, vamos otra vez. Revisa las respuestas que acabas de ver; necesitas 8 de 10. El pedido sigue guardado."
	label(body,heading,30,accent);label(body,message,23)
	button(body,"Volver al recuerdo · Enter" if s.passed else "Reintentar solo este reto · Enter",func():act("continue" if s.passed else "retry"))

func key(code: int) -> void:
	if session.kind=="cookies" and session.state.phase=="pantry" and code==KEY_ENTER:act("gather");return
	if session.kind=="order" and session.state.phase=="play":
		if code in [KEY_Q,KEY_W,KEY_R]:category=[KEY_Q,KEY_W,KEY_R].find(code);redraw();return
		if code in [KEY_LEFT,KEY_RIGHT]:menu_page=posmod(menu_page+(1 if code==KEY_RIGHT else -1),2);redraw();return
		if code==KEY_ENTER:act("submit");return
	if code>=KEY_1 and code<=KEY_9:
		var index:=int(code-KEY_1)
		if index<buttons.size() and not buttons[index].disabled:buttons[index].pressed.emit()
	elif code in [KEY_ENTER,KEY_SPACE]:
		for b in buttons:
			if b.has_focus() and not b.disabled:b.pressed.emit();return
