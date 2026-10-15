extends RefCounted
## Durable physical baking actions. Elapsed oven time advances only in gameplay.
var kind := "cookies"
var data: Dictionary = {}
var state: Dictionary = {}
const MIX_PHASES := ["dry", "cream", "combine", "oats"]

func setup(_kind: String, recipe: Dictionary, saved: Dictionary = {}) -> void:
	data=recipe
	state={"version":2,"phase":"intro","index":0,"quiz":[],"pantry":[],"measures":{},"fill":0.0,"mix":0.0,"eggs":0,"egg_taps":0,"shells":0,"additions":0,"portions":[],"flat":[],"dip":false,"sprayed":false,"chill":0,"temperature":190,"minutes":0.0,"swapped":false,"mitts":false,"cool":0.0,"preparation":[],"score":0,"passed":false,"feedback":"","station":""}
	if int(saved.get("version",0))==2:
		state.merge(saved.duplicate(true),true)
	elif not saved.is_empty():
		# Resume old semantic progress; never discard completed measurements/results.
		for key in ["pantry","measures","preparation","chill","temperature","minutes","score","passed"]:
			if saved.has(key):state[key]=saved[key]
		state.phase={"intro":"intro","pantry":"gather","measure":"measure","prepare":"dry","chill":"chill","oven":"preheat","timer":"oven","result":"result"}.get(saved.get("phase","intro"),"gather")
		if state.phase=="measure":
			state.index=0
			while state.index<ingredients_to_measure().size()-1 and state.measures.has(ingredients_to_measure()[int(state.index)].id):state.index+=1
		if state.phase=="dry":state.phase=["dry","cream","eggs","combine","oats","tray"][clampi(int(saved.get("index",0)),0,5)]
		if state.phase=="oven":state.portions=default_portions();state.sprayed=true;state.flat=[0,1,2,3,4,5];state.mitts=true
		if state.phase=="result":state.portions=default_portions();state.flat=[0,1,2,3,4,5]
	state.station="" # Close-ups reopen at their station after loading.
	if not state.has("inserted"):state.inserted=saved.get("phase","")=="timer"
	if not state.has("tools"):state.tools=false
	if not state.has("mix_quality"):state.mix_quality=[]

func ingredients_to_measure() -> Array:
	return data.ingredients.filter(func(i: Dictionary):return i.id not in ["eggs","spray","water","topping_sugar"])

func station_for_phase() -> String:
	match state.phase:
		"gather":return "pantry"
		"chill":return "fridge"
		"preheat","oven":return "oven"
		"cool","taste","result":return "rack"
		_:return "counter"

func default_portions() -> Array:
	return [[.2,.28],[.5,.28],[.8,.28],[.2,.72],[.5,.72],[.8,.72]]

func act(id: String, value: Variant = null) -> bool:
	var phase: String=state.phase
	if id=="start" and phase=="intro":state.phase="quiz";return true
	if id=="quiz" and phase=="quiz":
		if int(value)<0 or int(value)>1:return false
		state.quiz.append(int(value));state.index+=1
		if state.index==3:state.phase="gather";state.index=0
		return true
	if id=="ingredient" and phase=="gather":
		if not data.pantry.any(func(i: Dictionary):return i.id==str(value)):return false
		if state.pantry.has(str(value)):state.pantry.erase(str(value))
		else:state.pantry.append(str(value))
		return true
	if id=="gather" and phase=="gather":state.phase="measure";state.index=0;return true
	if id=="pour" and phase=="measure":
		state.fill=clampf(float(state.fill)+clampf(float(value),0,.4),0,2.0);return true
	if id=="empty" and phase=="measure":state.fill=0.0;return true
	if id=="measure" and phase=="measure":
		var item: Dictionary=ingredients_to_measure()[int(state.index)]
		state.measures[item.id]=float(state.fill)*float(item.quantity)
		state.index+=1;state.fill=0.0
		while state.index<ingredients_to_measure().size() and state.measures.has(ingredients_to_measure()[int(state.index)].id):state.index+=1
		if state.index==ingredients_to_measure().size():state.phase="dry";state.index=0
		return true
	if id=="add" and phase in ["combine","oats"]:
		if state.additions>=3:return false
		state.additions+=1;return true
	if id=="mix" and phase in MIX_PHASES:
		if phase in ["combine","oats"] and state.additions<3:return false
		state.mix=clampf(float(state.mix)+clampf(float(value),0,.15),0,1);return true
	if id=="mixed" and phase in MIX_PHASES and state.mix>=.25:
		state.mix_quality.append(float(state.mix))
		state.preparation.append({"dry":"whisk_dry","cream":"cream","combine":"gradual_dry","oats":"mix_oats"}[phase])
		state.phase={"dry":"cream","cream":"eggs","combine":"oats","oats":"chill"}[phase];state.mix=0.0;state.additions=0;return true
	if id=="tap" and phase=="eggs":state.egg_taps+=1;return true
	if id=="crack" and phase=="eggs" and state.egg_taps>0:
		if state.egg_taps!=2:state.shells+=1
		state.eggs+=1;state.egg_taps=0
		if state.eggs==2:state.phase="combine";state.measures.eggs=2;state.preparation.append("eggs_vanilla")
		return true
	if id=="chill" and phase=="chill":state.chill=60;state.phase="preheat";return true
	if id=="temperature" and phase=="preheat":state.temperature=clampi(int(value),160,220);return true
	if id=="preheat" and phase=="preheat":state.phase="tray";return true
	if id=="spray" and phase=="tray":state.sprayed=true;return true
	if id=="portion" and phase=="tray" and value is Array and value.size()==2 and state.portions.size()<6:
		state.portions.append([clampf(float(value[0]),.08,.92),clampf(float(value[1]),.12,.88)]);return true
	if id=="reset_tray" and phase=="tray":state.portions=[];return true
	if id=="portioned" and phase=="tray" and state.portions.size()==6:state.phase="flatten";return true
	if id=="dip" and phase=="flatten":state.dip=true;return true
	if id=="flatten" and phase=="flatten" and state.dip:
		var i:=int(value)
		if i<0 or i>=6 or state.flat.has(i):return false
		state.flat.append(i);state.dip=false
		if state.flat.size()==6:state.preparation.append("shape_fork");state.phase="oven";state.station=""
		return true
	if id=="mitts" and phase=="oven":state.mitts=true;return true
	if id=="insert" and phase=="oven":state.inserted=true;return true
	if id=="swap" and phase=="oven" and state.mitts and state.minutes>=4:state.swapped=true;return true
	if id=="pull" and phase=="oven" and state.mitts and state.inserted:state.phase="cool";state.station="";return true
	if id=="rack" and phase=="cool" and state.cool>=5:state.phase="taste";return true
	if id=="taste" and phase=="taste":state.score=evaluate_cookie();state.phase="result";state.passed=true;return true
	return false

func tick(delta: float) -> void:
	if state.phase=="oven" and state.inserted:state.minutes=minf(15,float(state.minutes)+maxf(0,delta)*.25)
	if state.phase=="cool":state.cool=minf(5,float(state.cool)+maxf(0,delta))

func evaluate_cookie() -> int:
	var expected: Array=data.ingredients.map(func(i: Dictionary):return i.id)
	var pantry_points:=0
	for id in state.pantry:pantry_points+=1 if expected.has(id) else -1
	var score: float=25.0*maxi(0,pantry_points)/expected.size()
	var accuracy:=0.0
	var items:=ingredients_to_measure()
	for item in items:
		accuracy+=maxf(0,1-absf(float(state.measures.get(item.id,0))-float(item.quantity))/float(item.quantity))
	score+=25.0*accuracy/items.size()
	var ordered:=0
	for i in range(mini(state.preparation.size(),data.preparation.size())):
		if state.preparation[i]==data.preparation[i].correct:ordered+=1
	var spacing:=1.0
	for i in range(state.portions.size()):
		for j in range(i):
			var a: Array=state.portions[i];var b: Array=state.portions[j]
			if Vector2(a[0],a[1]).distance_to(Vector2(b[0],b[1]))<.21:spacing-=.12
	var mixing:=1.0
	if not state.mix_quality.is_empty():
		mixing=0
		for value in state.mix_quality:mixing+=clampf(float(value),0,1)
		mixing/=state.mix_quality.size()
	score+=20.0*ordered/data.preparation.size()*clampf(spacing,0,1)*mixing
	if state.chill>=60:score+=10
	if state.temperature==190:score+=10
	if state.minutes>=8 and state.minutes<=10:score+=10
	score-=state.shells*3+(0 if state.sprayed else 4)+(0 if state.swapped else 3)
	return clampi(roundi(score),0,100)

func quality() -> String:
	if state.minutes>10:return "Muy tostadas"
	if state.minutes<8:return "Blanditas"
	if state.score>=90:return "Dorado perfecto"
	if state.score>=75:return "Caseras y ricas"
	return "Desiguales, hechas juntos" if state.score>=50 else "Nuestra tanda experimental"
