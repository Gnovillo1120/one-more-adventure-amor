extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
	if not OS.get_cmdline_user_args().has("--self-test"):quit(2);return
	var game: Node=load("res://scenes/main.tscn").instantiate()
	if OS.get_cmdline_user_args().has("--prove-original-routing"):
		# Recreate just the reported router defect in a test-only in-memory script.
		var old_router:=GDScript.new()
		old_router.source_code=FileAccess.get_file_as_string("res://scripts/game.gd").replace("if is_instance_valid(challenge) and not (challenge is BakingView and challenge.in_kitchen()):","if is_instance_valid(challenge):")
		if old_router.reload()!=OK:quit(2);return
		game.set_script(old_router)
	root.add_child(game);await process_frame
	var runner: Node=load("res://scripts/baking_input_runner.gd").new();runner.game=game;game.add_child(runner)
	runner.finished.connect(func(_checks: int, failures: int):quit(0 if failures==0 else 1))
	runner.call_deferred("run")
