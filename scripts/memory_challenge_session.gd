extends RefCounted
## Serializable semantic actions; no Controls, character nodes or timing dependencies.
var kind := ""
var data: Dictionary = {}
var state: Dictionary = {}

func setup(which: String, config: Dictionary, saved: Dictionary = {}) -> void:
	kind=which;data=config
	state={"phase":"intro","index":0,"answers":[],"score":0,"feedback":"","passed":false,"order":["","",""],"pantry":[],"measures":{},"preparation":[],"chill":0,"temperature":0,"minutes":0}
	if not saved.is_empty():state.merge(saved.duplicate(true),true)
	if kind=="guillermo":
		var revision: int=int(config.get("revision",1))
		if not saved.is_empty() and int(saved.get("quiz_revision",1))<revision:
			# Re-evaluate unfinished legacy quizzes against the corrected personal facts.
			state.score=0
			for i in range(mini(state.answers.size(),config.questions.size())):
				if int(state.answers[i])==int(config.questions[i].answer):state.score+=1
			if state.phase=="feedback" and int(state.index)<state.answers.size():
				var correct: bool=int(state.answers[int(state.index)])==int(config.questions[int(state.index)].answer)
				state.feedback=("¡Correcto! " if correct else "Esta no. ")+str(config.questions[int(state.index)].explanation)
			if state.phase=="result":state.passed=int(state.score)>=int(config.pass_score)
		state.quiz_revision=float(revision)

func act(id: String, value: Variant = null) -> bool:
	if id=="retry" and state.phase=="result" and not state.passed and kind!="cookies":setup(kind,data);state.phase="play";return true
	if id=="start" and state.phase=="intro":state.phase="pantry" if kind=="cookies" else "play";return true
	if id=="hard_mode" and state.phase=="hard_mode":state.phase="play";return true
	if kind in ["debate","guillermo"]:
		if id=="answer" and state.phase=="play":
			var q: Dictionary=data.questions[int(state.index)];var answer:=int(value)
			if answer<0 or answer>=q.choices.size():return false
			state.answers.append(answer)
			var points: int=int(q.points[answer]) if kind=="debate" else 1 if answer==int(q.answer) else 0
			state.score+=points;state.feedback=q.feedback[answer] if q.has("feedback") else q.explanation
			if kind=="guillermo":state.feedback=("¡Correcto! " if points==1 else "Esta no. ")+str(state.feedback)
			state.phase="feedback";return true
		if id=="next" and state.phase=="feedback":
			state.index+=1
			if state.index==data.questions.size():state.passed=state.score>=int(data.pass_score);state.phase="result"
			else:state.phase="hard_mode" if kind=="guillermo" and state.index==int(data.get("hard_mode_index",7)) else "play"
			return true
	elif kind=="order":
		if id=="dish" and state.phase=="play" and value is Array:
			if value.size()!=2:return false
			var category:=int(value[0]);var dish:=str(value[1])
			if category<0 or category>2 or not data.dishes.any(func(d: Dictionary):return d.id==dish):return false
			state.order[category]=dish;return true
		if id=="submit" and state.phase=="play" and not state.order.has(""):
			state.passed=state.order==data.correct_order;state.phase="result";return true
	elif kind=="cookies":
		if id=="ingredient" and state.phase=="pantry":
			if not data.pantry.any(func(d: Dictionary):return d.id==value):return false
			if state.pantry.has(value):state.pantry.erase(value)
			else:state.pantry.append(value)
			return true
		if id=="gather" and state.phase=="pantry":state.phase="measure";state.index=0;return true
		if id=="measure" and state.phase=="measure":
			var item: Dictionary=data.measurements[int(state.index)]
			state.measures[item.id]=float(value);state.index+=1
			if state.index==data.measurements.size():state.phase="prepare";state.index=0
			return true
		if id=="prepare" and state.phase=="prepare":
			var step: Dictionary=data.preparation[int(state.index)]
			if not step.options.any(func(o: Dictionary):return o.id==value):return false
			state.preparation.append(str(value));state.index+=1
			if state.index==data.preparation.size()-1:state.phase="chill"
			elif state.index==data.preparation.size():state.phase="timer"
			return true
		if id=="chill" and state.phase=="chill":state.chill=int(value);state.phase="oven";return true
		if id=="temperature" and state.phase=="oven":state.temperature=int(value);state.phase="prepare";return true
		if id=="minutes" and state.phase=="timer":
			state.minutes=int(value);state.score=evaluate_cookie();state.passed=true;state.phase="result";return true
	return false

func evaluate_cookie() -> int:
	# 25 pantry (penalty for distractors), 25 measurements, 20 order, 10 chill,
	# 10 temperature, 10 bake time. Rounding is deterministic; every result advances.
	var expected: Array=data.ingredients.map(func(i: Dictionary):return i.id)
	var correct:=0;var wrong:=0
	for id in state.pantry:
		if expected.has(id):correct+=1
		else:wrong+=1
	var score: float=float(data.weights.ingredients)*maxi(0,correct-wrong)/expected.size()
	var accurate:=0
	for item in data.measurements:
		if is_equal_approx(float(state.measures.get(item.id,-1)),float(item.quantity)):accurate+=1
	score+=float(data.weights.measurements)*accurate/data.measurements.size()
	var ordered:=0
	for i in range(mini(state.preparation.size(),data.preparation.size())):
		if state.preparation[i]==data.preparation[i].correct:ordered+=1
	score+=float(data.weights.preparation)*ordered/data.preparation.size()
	if state.chill>=int(data.chill_minutes):score+=float(data.weights.chill)
	if state.temperature==int(data.oven.celsius):score+=float(data.weights.temperature)
	if state.minutes>=int(data.bake_minutes.minimum) and state.minutes<=int(data.bake_minutes.maximum):score+=float(data.weights.time)
	return clampi(roundi(score),0,100)
