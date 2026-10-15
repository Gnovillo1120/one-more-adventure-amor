extends RefCounted
## Countertop choreography. Durable recipe state remains in BakingSession.
## Effects interpolate original code-native pixel props; no runtime art generation.
var clock := 0.0
var elapsed := 0.0
var duration := 0.0
var event := ""
var before: Dictionary = {}
var value: Variant
var view: Control
var jar_blend := 0.0
var fork_rest := Vector2(1050,260)
var fork_origin := Vector2(1050,260)
const COLORS := {"flour":"efe3c7","white_sugar":"fff1d9","brown_sugar":"ad7545","oats":"d3ad6d","cinnamon":"9a542f","soda":"f9f5e9","salt":"d6e6e5","vanilla":"633a29","butter":"f1ce6f"}

func start(id: String, previous: Dictionary, argument: Variant) -> void:
	if id not in ["measure","tap","crack","add","portion","dip","flatten","insert","pull","rack","taste"]:return
	event=id;before=previous;value=argument;elapsed=0
	duration={"measure":1.6,"tap":.24,"crack":1.25,"add":.8,"portion":1.4,"dip":1.6,"flatten":1.0,"insert":1.3,"pull":1.3,"rack":1.8,"taste":2.2}[id]
	if id=="crack" and int(previous.eggs)==1:duration=2.0
	if id in ["dip","flatten"]:
		fork_origin=fork_rest
		if id=="flatten":
			var pos: Array=previous.portions[int(argument)]
			fork_rest=Vector2(355+float(pos[0])*570,220+float(pos[1])*270-60)

func tick(delta: float) -> void:
	clock+=delta;elapsed=minf(duration,elapsed+delta)
	if is_instance_valid(view):jar_blend=move_toward(jar_blend,1.0 if view.session.state.phase=="measure" and not view.transition_pending and (view.pouring or Input.is_physical_key_pressed(KEY_SPACE)) else 0.0,delta*4)

func active(id: String) -> bool:return event==id and elapsed<duration
func t() -> float:return clampf(elapsed/maxf(.001,duration),0,1)
func px(rect: Rect2, color: Color) -> void:view.draw_rect(Rect2(rect.position.snapped(Vector2(2,2)),rect.size.snapped(Vector2(2,2))),color)
func line(a: Vector2,b: Vector2,color: Color,width: float=4) -> void:view.draw_line(a.snapped(Vector2(2,2)),b.snapped(Vector2(2,2)),color,width)
func label(text: String, p: Vector2) -> void:view.draw_string(view.game.pixel_font,p,text,HORIZONTAL_ALIGNMENT_CENTER,220,18,Color("f8e4bd"))

func ingredient(id: String, p: Vector2, amount: float=1.0) -> void:
	var color:=Color(COLORS.get(id,"dfc18c"))
	if id=="butter":
		px(Rect2(p,Vector2(22,14)*amount),color.darkened(.25));px(Rect2(p+Vector2(2,-4),Vector2(18,12)*amount),color)
	elif id=="oats":
		px(Rect2(p,Vector2(10,4)*amount),color);px(Rect2(p+Vector2(2,-2),Vector2(6,2)*amount),color.lightened(.2))
	elif id=="vanilla":px(Rect2(p,Vector2(4,12)*amount),color)
	else:px(Rect2(p,Vector2(4 if id in ["flour","soda","salt"] else 6,4)*amount),color)

func stream(id: String, a: Vector2,b: Vector2, strength: float=1.0) -> void:
	for i in range(25):
		var f:=fposmod(clock*(.7 if id=="butter" else 1.6)+i*.079,1)
		var p:=a.lerp(b,f)+Vector2(sin(i*19.0)*10*f,0)
		ingredient(id,p,strength)

func bowl(center: Vector2, radius: float, phase: String, mix: float, volume: float, grain: float=1.0) -> void:
	var scale:=radius/150
	view.sprite("bowl",Rect2(center-Vector2(200,60)*scale,Vector2(400,245)*scale))
	if volume<=0:return
	volume=clampf(volume,0,1)
	var fill_scale:=sqrt(volume)
	var color:=Color("8cb5b0") if phase=="water" else Color("f3ead4") if phase=="sugar" else Color("e8d7b7") if phase=="dry" else Color("e9c375") if phase=="cream" else Color("e6c076") if phase=="eggs" else Color("e2bd77") if phase=="combine" else Color("c69b60")
	if phase=="cream":color=color.lerp(Color("efd7a6"),mix)
	elif phase not in ["water","sugar"]:color=color.lerp(Color("b98a4e"),mix*(.65 if phase=="combine" else .18))
	var surface:=center+Vector2(0,(40-volume*12)*scale)
	for y in range(-36,40,2):
		var width:=sqrt(maxf(0,1-pow(float(y)/43,2)))*radius*fill_scale
		px(Rect2(surface+Vector2(-width,y*scale*fill_scale),Vector2(width*2,maxf(2,2*scale))),color)
	var count:=0 if phase=="water" else int(48*volume*grain)
	for i in range(count):
		var angle:=i*2.4+mix*TAU+sin(clock*2)*.04
		var r:=sqrt(float(i)/maxi(1,count))*radius*.85*fill_scale
		var p:=surface+Vector2(cos(angle)*r,sin(angle)*r*.22)
		px(Rect2(p,Vector2(8 if phase=="oats" else 4,3)*scale),color.lightened(.18) if i%3 else color.darkened(.2))
	if phase=="cream" and mix<.6:
		for i in range(mini(5,maxi(1,int(volume*15)))):ingredient("butter",surface+Vector2(-50+i*22,sin(i*3.0)*12)*fill_scale*scale,(1-mix)*fill_scale*scale)
	if phase=="water":line(surface+Vector2(-radius*.4,-2),surface+Vector2(radius*.25,-2),Color("c2d9c7"),2)

func amount(ids: Array, measured: Dictionary) -> float:
	var expected:=0.0;var actual:=0.0
	for item in view.session.ingredients_to_measure():
		if not ids.has(item.id):continue
		var factor: float=1.0/48 if item.unit=="teaspoon" else 1.0/16 if item.unit=="tablespoon" else 1.0
		expected+=float(item.quantity)*factor;actual+=float(measured.get(item.id,0))*factor
	return clampf(actual/maxf(.001,expected),0,1.2)

func cup_at(point: Vector2, fill: float,id: String,tilt: float=0.0,scale: float=1.0,mirror: bool=true) -> void:
	view.draw_set_transform(point,tilt,Vector2(-scale if mirror else scale,scale))
	view.sprite("cup",Rect2(-80,-40,200,160))
	var height:=clampf(fill,0,2)*42
	px(Rect2(-25,99-height,68,height),Color(COLORS.get(id,"dfc18c")))
	if height>4 and id!="vanilla":
		for i in range(6 if id=="butter" else 15):ingredient(id,Vector2(-21+posmod(i*17,45),96-fposmod(i*13,maxf(1,height*.9))),.7)
	for i in range(4):line(Vector2(20,94-i*20),Vector2(38,94-i*20),Color("975f4a"),2)
	line(Vector2(-22,57),Vector2(42,57),Color("608163"),2)
	view.draw_set_transform(Vector2.ZERO)

func fork_at(point: Vector2,coated: bool) -> void:
	# Actual PNG tines are centered at (39,9), with the handle extending down-left.
	view.draw_set_transform(point.snapped(Vector2(2,2)))
	view.sprite("fork",Rect2(-117,-27,192,144))
	if coated:
		for i in range(4):px(Rect2(-7+i*5,-6,2,4),Color("fff0d1"))
	view.draw_set_transform(Vector2.ZERO)

func mitt_at(point: Vector2, mirror: bool) -> void:
	view.draw_set_transform(point,0,Vector2(-1 if mirror else 1,1))
	view.sprite("mitt",Rect2(-96,-16,128,96))
	view.draw_set_transform(Vector2.ZERO)

func cookie(p: Vector2, flat: float, bake: float, outcome: int=100) -> void:
	var width:=lerpf(19,29,flat)+bake*3
	var height:=lerpf(23,15,flat)
	var color:=Color("ccb17d").lerp(Color("dc9b48"),minf(1,bake))
	if bake>1:color=color.lerp(Color("543326"),minf(1,(bake-1)*2))
	if outcome<70:color=color.lightened(.15)
	if outcome<50:color=color.lerp(Color("78442e"),.45)
	elif outcome<90:color=color.darkened(.08)
	px(Rect2(p-Vector2(width-6,height),Vector2(width*2-12,height*2)),color.darkened(.24))
	px(Rect2(p-Vector2(width,height-6),Vector2(width*2,height*2-12)),color.darkened(.24))
	px(Rect2(p-Vector2(width-4,height-4),Vector2(width*2-8,height*2-8)),color)
	for i in range(11):ingredient("oats",p+Vector2(-width+6+fposmod(i*11,width*2-14),-height+6+fposmod(i*7,maxf(2,height*2-12))),.65)
	if flat>.8:
		for x in [-10,0,10]:line(p+Vector2(x,-height+4),p+Vector2(x,height-4),color.darkened(.3),3)
	if outcome<75:line(p+Vector2(-12,2),p+Vector2(5,-7),color.darkened(.25),3)

func render(owner_view: Control) -> void:
	view=owner_view
	var s: Dictionary=view.session.state
	var phase: String=s.phase
	if active("measure"):phase="measure"
	if active("crack"):phase="eggs"
	if active("flatten"):phase="flatten"
	if active("pull"):phase="oven"
	if active("rack"):phase="cool"
	if phase=="measure":
		var item: Dictionary=view.session.ingredients_to_measure()[int(before.index if active("measure") else s.index)]
		var id: String=item.id
		var fill: float=float(before.fill if active("measure") else s.fill)
		var cup:=Vector2(600,335)
		var tilt:=0.0
		var group: Array=["flour","cinnamon","soda","salt"] if id in ["flour","cinnamon","soda","salt"] else ["oats"] if id=="oats" else ["vanilla"] if id=="vanilla" else ["butter","white_sugar","brown_sugar"]
		var volume: float=amount(group,s.measures)
		if active("measure"):
			var transfer: float=smoothstep(.3,.75,t())
			volume=lerpf(amount(group,before.measures),volume,transfer)
			var travel: float=smoothstep(0,.25,t())*(1-smoothstep(.8,1,t()))
			cup=cup.lerp(Vector2(870,255),travel);fill*=1-transfer
			tilt=.8*smoothstep(.2,.4,t())*(1-smoothstep(.75,.9,t()))
		if id=="vanilla":cup_at(Vector2(950,360),volume*.1,id,0,.65,false)
		else:bowl(Vector2(950,360),100,"dry" if group.has("flour") else "oats" if id=="oats" else "cream",0,volume)
		label("Bol de secos" if group.has("flour") else "Avena reservada" if id=="oats" else "Vainilla reservada" if id=="vanilla" else "Bol de mezcla",Vector2(840,520))
		# Each ingredient has an open container and an authored mouth pivot.
		var jar:=Vector2(350,330).lerp(Vector2(520,170) if id=="butter" else Vector2(460,270),jar_blend)
		view.draw_set_transform(jar,.8*jar_blend)
		view.sprite("ingredient_"+id,Rect2(-96,-120,192,240))
		view.draw_set_transform(Vector2.ZERO)
		cup_at(cup,fill,id,tilt)
		if not active("measure") and (view.pouring or Input.is_physical_key_pressed(KEY_SPACE)) and jar_blend>.35:
			stream(id,jar+(Vector2(view.containers[id].mouth[0],view.containers[id].mouth[1])-Vector2(32,40)).rotated(.8*jar_blend)*3,cup+Vector2(0,99-clampf(fill,0,2)*42))
		if active("measure") and t()>.3 and t()<.77:
			stream(id,cup+Vector2(64,-7).rotated(tilt),Vector2(950,424 if id=="vanilla" else 380),.8)
	elif phase in ["dry","cream","eggs","combine","oats"]:
		var additions: float=float(s.additions)
		if active("add"):additions=float(before.additions)+smoothstep(.2,.8,t())
		var eggs: float=float(s.eggs)
		var egg_f: float=clampf(t()/(.65 if active("crack") and int(before.eggs)==1 else 1.0),0,1)
		if active("crack"):eggs=float(before.eggs)+smoothstep(.4,.9,egg_f)
		var dry: float=amount(["flour","cinnamon","soda","salt"],s.measures)
		var wet: float=amount(["butter","white_sugar","brown_sugar"],s.measures)
		var volume: float=.6*dry if phase=="dry" else .45*wet+eggs*.12
		if phase=="combine":volume+=.25*dry*additions/3
		if phase=="oats":volume+=.25*dry+.06*additions/3
		bowl(Vector2(640,355),150,phase,s.mix,volume,additions/3 if phase=="oats" else 1.0)
		if phase in ["combine","oats"]:
			var reserve:=Vector2(295,290);var angle:=0.0
			if active("add"):
				reserve=reserve.lerp(Vector2(470,240),smoothstep(0,.25,t())*(1-smoothstep(.8,1,t())))
				angle=.45*smoothstep(.2,.4,t())*(1-smoothstep(.75,.9,t()))
			view.draw_set_transform(reserve,angle)
			bowl(Vector2.ZERO,72,"dry" if phase=="combine" else "oats",1,1-additions/3)
			view.draw_set_transform(Vector2.ZERO)
			label("Secos reservados" if phase=="combine" else "Avena",Vector2(180,470))
			if active("add") and t()>.2 and t()<.8:stream("flour" if phase=="combine" else "oats",reserve+Vector2(72,15).rotated(angle),Vector2(620,385))
		if phase=="eggs":
			var ep:=Vector2(300,365)
			if view.grabbed:ep=Vector2(730,245 if s.egg_taps==0 else 290)
			if active("tap"):ep=Vector2(730,255+sin(t()*PI)*40)
			if not active("crack"):
				view.sprite("egg",Rect2(ep-Vector2(32,44),Vector2(65,88)))
				var visible_taps: int=int(before.egg_taps) if active("tap") and t()<.5 else int(s.egg_taps)
				if visible_taps>0:
					line(ep+Vector2(-6,-4),ep+Vector2(1,2),Color("735743"),3);line(ep+Vector2(1,2),ep+Vector2(6,-1),Color("735743"),3)
			else:
				var center: float=620+int(before.eggs)*40
				if egg_f<.15:
					var approach:=Vector2(730,290).lerp(Vector2(center,245),smoothstep(0,.15,egg_f))
					view.sprite("egg",Rect2(approach-Vector2(32,44),Vector2(65,88)))
				elif egg_f<1:
					var f: float=(egg_f-.15)/.85
					var separation: float=minf(1,f*3)*65
					for side in [-1,1]:
						var p:=Vector2(center+side*separation,245-f*32)
						view.draw_set_transform(p,side*(.15+f*.4))
						view.draw_texture_rect_region(view.textures.egg,Rect2(-24,-30,48,70),Rect2(0 if side<0 else 32,0,32,48))
						view.draw_set_transform(Vector2.ZERO)
					if f>.15 and f<.85:
						var y: float=lerpf(260,388,clampf((f-.15)/.65,0,1))
						px(Rect2(center-4,255,8,y-255),Color("f7e7b8"));px(Rect2(center-10,y-4,20,26),Color("e7b22e"));px(Rect2(center-14,y+2,28,14),Color("e7b22e"));px(Rect2(center-7,y,8,6),Color("ffda57"))
					if before.egg_taps!=2 and f>.4:px(Rect2(center+10,300+f*85,10,6),Color("e4c49e"))
				if int(before.eggs)==1 and t()>.7:
					var v: float=smoothstep(.7,1,t())
					cup_at(Vector2(780,275),.1*(1-v),"vanilla",-.6,.65,false)
					stream("vanilla",Vector2(742,295),Vector2(660,388),.5)
			var settled: int=int(before.eggs) if active("crack") and egg_f<.9 else int(s.eggs)
			for i in range(settled):
				px(Rect2(610+i*40,379,20,22),Color("e7b22e"));px(Rect2(606+i*40,384,28,12),Color("e7b22e"))
			var shells: int=int(before.shells) if active("crack") and egg_f<.8 else int(s.shells)
			for i in range(shells):px(Rect2(590+i*35,388,10,6),Color("f2dcc0"))
		else:
			var angle: float=view.last_angle if view.whisk else clock*2 if Input.is_physical_key_pressed(KEY_SPACE) else -.5
			var p:=Vector2(640,345)+Vector2(cos(angle)*70,sin(angle)*22)
			view.draw_set_transform(p,sin(angle)*.28)
			view.sprite("whisk",Rect2(-20,-110,65,155));view.draw_set_transform(Vector2.ZERO)
	elif phase in ["tray","flatten","oven","cool","taste","result"]:
		var tray:=Rect2(310,180,660,350)
		var oven_travel: float=1 if s.inserted else 0
		if active("insert"):oven_travel=t()
		if active("pull"):oven_travel=1-t()
		if phase=="oven":
			px(Rect2(280,165,720,355),Color("35413e"));px(Rect2(310,220,660,280),Color("6b4632"))
			px(Rect2(324,235,632,245),Color("c17a37"))
			for y in [270,330,390,450]:line(Vector2(325,y),Vector2(955,y),Color("dcb473"),4)
			label("%d°C · %.1f min"%[s.temperature,s.minutes],Vector2(530,205))
			tray=Rect2(350,235+115*(1-oven_travel),580,250)
			if oven_travel<1:px(Rect2(305,480,670,35+(1-oven_travel)*60),Color("68706a"))
		if not active("rack"):view.sprite("rack" if phase in ["taste","result"] else "tray",tray)
		if active("rack"):
			view.sprite("tray",Rect2(190,230,500,260));view.sprite("rack",Rect2(700,230,420,240))
		var portions: Array=before.portions if active("flatten") else s.portions
		for i in range(portions.size()):
			var point:=Vector2(355+float(portions[i][0])*570,220+float(portions[i][1])*270)
			if phase=="oven":point=Vector2(390+float(portions[i][0])*500,265+float(portions[i][1])*190+115*(1-oven_travel))
			if active("rack"):
				var f:=smoothstep(0,1,clampf(t()*6-i,0,1))
				point=Vector2(230+float(portions[i][0])*390,260+float(portions[i][1])*160).lerp(Vector2(740+float(portions[i][0])*320,260+float(portions[i][1])*160),f)
			if active("portion") and i==portions.size()-1 and t()<.75:continue
			var flat:=1.0 if s.flat.has(i) else 0.0
			if active("flatten") and i==int(value):flat=smoothstep(.35,.65,t())
			cookie(point,flat,float(s.minutes)/9,s.score if phase=="result" else 100)
			if phase=="flatten" and (int(value) if active("flatten") else view.tray_selected)==i:view.draw_rect(Rect2(point-Vector2(35,31),Vector2(70,62)),Color("e7d5a1"),false,2)
		if phase=="tray" or active("portion"):
			var used: float=float(s.portions.size())
			if active("portion"):used=float(before.portions.size())+smoothstep(.15,.25,t())
			var dough: float=.45*amount(["butter","white_sugar","brown_sugar"],s.measures)+.24+.25*amount(["flour","cinnamon","soda","salt"],s.measures)+.06*amount(["oats"],s.measures)
			bowl(Vector2(155,350),75,"oats",1,dough*(1-used/24))
			var p:=Vector2(160,315)
			if active("portion"):
				var destination:=Vector2(355+float(value[0])*570,220+float(value[1])*270)
				if t()<.15:p=p.lerp(Vector2(155,370),smoothstep(0,.15,t()))
				elif t()<.25:p=Vector2(155,370).lerp(Vector2(160,315),smoothstep(.15,.25,t()))
				elif t()<.6:
					p=p.lerp(destination-Vector2(0,15),smoothstep(.25,.6,t()));p.y-=sin((t()-.25)/.35*PI)*40
				elif t()<.75:p=(destination-Vector2(0,15)).lerp(destination,smoothstep(.6,.75,t()))
				else:p=destination.lerp(Vector2(160,315),smoothstep(.75,1,t()))
			line(p+Vector2(-70,-45),p,Color("9bafb0"),10);px(Rect2(p-Vector2(14,8),Vector2(28,16)),Color("cad5c4"))
			if active("portion") and t()>.15 and t()<.75:cookie(p,0,0)
			if s.portions.size()>1:
				for i in range(s.portions.size()):
					for j in range(i):
						if Vector2(s.portions[i][0],s.portions[i][1]).distance_to(Vector2(s.portions[j][0],s.portions[j][1]))<.21:label("Demasiado cerca",Vector2(510,516))
		if phase=="flatten":
			bowl(Vector2(150,350),48,"water",0,.5);bowl(Vector2(1110,350),48,"sugar",0,.5)
			label("Agua",Vector2(45,480));label("Azúcar",Vector2(1000,480))
			var p: Vector2=fork_rest
			if active("dip"):
				if t()<.25:p=fork_origin.lerp(Vector2(150,360),smoothstep(0,.25,t()));p.y-=sin(t()/.25*PI)*35
				elif t()<.4:p=Vector2(150,360+sin((t()-.25)/.15*PI)*16)
				elif t()<.72:p=Vector2(150,360).lerp(Vector2(1110,360),smoothstep(.4,.72,t()));p.y-=sin((t()-.4)/.32*PI)*45
				elif t()<.85:p=Vector2(1110,360+sin((t()-.72)/.13*PI)*16)
				else:p=Vector2(1110,360).lerp(fork_origin,smoothstep(.85,1,t()))
			if active("flatten"):
				var pos: Array=before.portions[int(value)]
				var destination:=Vector2(355+float(pos[0])*570,220+float(pos[1])*270)
				if t()<.3:p=fork_origin.lerp(destination-Vector2(0,30),smoothstep(0,.3,t()))
				elif t()<.5:p=(destination-Vector2(0,30)).lerp(destination,smoothstep(.3,.5,t()))
				elif t()<.7:p=destination
				else:p=destination.lerp(fork_rest,smoothstep(.7,1,t()))
			var coated: bool=t()>.75 if active("dip") else bool(before.dip) and t()<.65 if active("flatten") else bool(s.dip)
			fork_at(p,coated)
		if phase=="oven":
			if oven_travel>=1:
				px(Rect2(310,235,660,250),Color(.08,.12,.12,.14));line(Vector2(540,482),Vector2(750,482),Color("d2d1b5"),8)
			px(Rect2(365,580,550,12),Color("a07442"));px(Rect2(365+550*8/15.0,580,550*2/15.0,12),Color("81a671"))
			line(Vector2(365+float(s.minutes)/15*550,574),Vector2(365+float(s.minutes)/15*550,600),Color("f5e5ba"),4)
			if s.mitts:
				if active("insert") or active("pull"):
					mitt_at(tray.position+Vector2(8,110),false);mitt_at(tray.position+Vector2(tray.size.x-8,110),true)
				else:view.sprite("mitt",Rect2(1000,330,100,125))
		if phase in ["taste","result"]:
			for i in range(2):
				var p:=Vector2(150+i*970,330)
				var person: String="anami" if i==0 else "guillermo"
				view.draw_texture_rect_region(view.game.memory.sprites[person],Rect2(p-Vector2(48,100),Vector2(96,144)),Rect2(0,0,32,48))
				var bite:=sin(minf(1,t())*PI) if active("taste") else 0.0
				# A bite-sized cookie reaches the mouth; it never obscures the face.
				view.draw_set_transform(p+Vector2(12,-12-bite*44),0,Vector2(.42,.42))
				cookie(Vector2.ZERO,1,float(s.minutes)/9,s.score if phase=="result" else view.session.evaluate_cookie());view.draw_set_transform(Vector2.ZERO)
				if phase=="result":
					var reactions: Array=["¡Mmm!","¡Una más!"] if s.score>=90 else ["¡Qué ricas!","Nos salieron."] if s.score>=75 else ["Un poquito chuecas…","Igual compartimos."] if s.score>=50 else ["¿Está crujiente?","¡La próxima también!"]
					label(reactions[i],p+Vector2(-100,90))
