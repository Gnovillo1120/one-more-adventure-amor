extends SceneTree
const Session=preload("res://scripts/memory_challenge_session.gd")
var checks:=0
var failures:=0
var game: Node
func _initialize() -> void:call_deferred("run")
func verify(value: bool, message: String) -> void:
	checks+=1
	if not value:failures+=1;push_error(message)
func config(kind: String) -> Dictionary:
	var paths={"debate":"mun_debate","order":"ikura_order","guillermo":"guillermo_quiz","cookies":"oatmeal_cookie_recipe"}
	return JSON.parse_string(FileAccess.get_file_as_string("res://data/%s.json" % paths[kind]))
func make(kind: String) -> RefCounted:
	var session:=Session.new();session.setup(kind,config(kind));session.act("start");return session
func answer_all(session: RefCounted, score: int) -> void:
	for i in range(session.data.questions.size()):
		if session.state.phase=="hard_mode":session.act("hard_mode")
		var q: Dictionary=session.data.questions[i]
		var answer: int=q.points.find(2.0) if session.kind=="debate" else int(q.answer)
		if i>=score:answer=q.points.find(0.0) if session.kind=="debate" else (answer+1)%q.choices.size()
		session.act("answer",answer);session.act("next")
func bake(session: RefCounted, perfect: bool=true) -> void:
	for item in session.data.ingredients:session.act("ingredient",item.id)
	if not perfect:session.act("ingredient","pepper")
	session.act("gather")
	for item in session.data.measurements:session.act("measure",item.quantity if perfect else item.quantity/2)
	for i in range(5):session.act("prepare",session.data.preparation[i].correct if perfect else session.data.preparation[i].options[1].id)
	session.act("chill",60 if perfect else 0);session.act("temperature",190 if perfect else 220)
	session.act("prepare",session.data.preparation[5].correct if perfect else "big_sheet")
	session.act("minutes",9 if perfect else 15)
func drain() -> void:
	var guard:=0
	while game._dialogue_open() and guard<200:
		guard+=1;game.revealed=100000
		if game.lines[game.line_index].has("choices"):game._choose(0)
		else:game._advance_dialogue()
func run() -> void:
	if not OS.get_cmdline_user_args().has("--self-test"):quit(2);return
	var debate: Dictionary=config("debate")
	for i in range(5):
		for choice in range(3):
			var s:=make("debate");s.state.index=i;s.act("answer",choice)
			verify(s.state.score==debate.questions[i].points[choice],"debate choice scoring")
	for correct in range(6):
		var s:=make("debate");answer_all(s,correct)
		verify(s.state.passed==(correct*2>=7),"debate threshold")
		if not s.state.passed:s.act("retry");verify(s.state.index==0 and s.state.score==0 and s.state.answers.is_empty(),"debate retry")
	var order: Dictionary=config("order")
	for a in order.dishes:
		for b in order.dishes:
			for c in order.dishes:
				var s:=make("order");s.act("dish",[0,a.id]);s.act("dish",[1,b.id]);s.act("dish",[2,c.id]);s.act("submit")
				verify(s.state.passed==([a.id,b.id,c.id]==order.correct_order),"exact order combination")
	var missing:=make("order");verify(not missing.act("submit"),"incomplete order cannot submit")
	var quiz: Dictionary=config("guillermo")
	verify(quiz.questions.size()==10,"ten questions")
	var keys=[0,3,3,1,1,2,1,1,2,4]
	for i in range(10):verify(quiz.questions[i].answer==keys[i] and quiz.questions[i].choices.size()==(5 if i==9 else 4),"quiz facts and variable choices")
	for score in range(11):
		var s:=make("guillermo");answer_all(s,score)
		verify(s.state.score==score and s.state.passed==(score>=8),"quiz threshold %d" % score)
		if score<8:s.act("retry");verify(s.state.index==0 and s.state.score==0 and s.state.answers.is_empty(),"quiz retry reset")
	var hard:=make("guillermo")
	for i in range(7):hard.act("answer",keys[i]);hard.act("next")
	verify(hard.state.phase=="hard_mode" and hard.state.index==7,"hard mode before eighth question")
	verify(not hard.act("answer",1),"hard mode cannot be skipped")
	var perfect:=make("cookies");bake(perfect)
	verify(perfect.state.score==100 and perfect.state.passed,"perfect recipe 100")
	var poor:=make("cookies");bake(poor,false)
	verify(poor.state.score<40 and poor.state.passed and poor.state.phase=="result","poor cookies always advance")
	for field in ["measures","preparation","chill","temperature","minutes"]:
		var s:=make("cookies");s.state=perfect.state.duplicate(true)
		match field:
			"measures":s.state.measures.flour=99
			"preparation":s.state.preparation.reverse()
			"chill":s.state.chill=0
			"temperature":s.state.temperature=0
			"minutes":s.state.minutes=0
		verify(s.evaluate_cookie()<100 and s.evaluate_cookie()>=0,"cookie penalty: "+field)
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.test_mode=true
	for kind in ["debate","order","guillermo","cookies"]:
		game.chapter_state={};game.chapter_index=0 if kind=="debate" else 3 if kind=="cookies" else 1
		game.scene_index=1 if kind=="debate" else 0 if kind=="cookies" else 2;game.start_scene()
		game.memory.quest_step=1;game.memory.optional_seen=["preserved"]
		game._open_challenge(kind);game.challenge.act("start")
		if kind=="cookies":game.challenge.act("ingredient","flour");game.challenge.act("gather");game.challenge.act("measure",2)
		elif kind=="order":game.challenge.act("dish",[0,"gyozas"])
		else:game.challenge.act("answer",0)
		var before: Dictionary=JSON.parse_string(JSON.stringify(game.challenge.session.state))
		game._toggle_pause();verify(not game.challenge.visible,"pause hides challenge");game._toggle_pause()
		var saved: Dictionary=JSON.parse_string(JSON.stringify(game._save_payload()))
		game.chapter_state=saved.chapter_state;game.start_scene(saved.completed,saved.position)
		verify(game.challenge.session.state==before,"active phase restored: "+kind)
		verify(game.memory.optional_seen==["preserved"] and game.memory.quest_step==1,"earlier progress retained")
		var s: RefCounted=game.challenge.session
		if kind=="order":
			s.act("dish",[1,"ramen"]);s.act("dish",[2,"sushi"]);s.act("submit");game.challenge.act("continue")
			verify(game.challenge.session.kind=="guillermo" and not game.scene_completed,"order unlocks mandatory quiz")
		elif kind=="cookies":
			s.setup(kind,config(kind));s.act("start");bake(s,false);game.challenge.act("continue");drain()
			verify(game.scene_completed,"poor cookies complete memory")
		else:
			s.setup(kind,config(kind));s.act("start");answer_all(s,0);game.challenge.redraw();game.challenge.act("continue")
			verify(not game.scene_completed and is_instance_valid(game.challenge),"failed challenge blocks continuation")
			game.challenge.act("retry");answer_all(s,10);game.challenge.act("continue");drain()
			verify(game.scene_completed,"passed challenge resumes story")
	game.queue_free();await process_frame
	print("MINIGAMES_QA: %d checks; %d failures" % [checks,failures]);quit(0 if failures==0 else 1)
