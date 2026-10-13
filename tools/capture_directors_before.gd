extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var directory:=ProjectSettings.globalize_path("res://docs/directors/before")
	if not ProjectSettings.load_resource_pack("res://builds/2d-animation-polish/One More Adventure Amor.pck",true):quit(1);return
	var game: Node=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	if game.get("director")!=null:push_error("Baseline pack override failed");quit(1);return
	game.capture_directory=directory;DirAccess.make_dir_recursive_absolute(directory)
	await game._capture_frame("menu");game.chapter_index=0;game.scene_index=0;game.start_scene();await game._capture_frame("uess")
	if not FileAccess.file_exists(directory+"/menu.png") or not FileAccess.file_exists(directory+"/uess.png"):push_error("Missing baseline captures");quit(1);return
	print("DIRECTORS_BASELINE_CAPTURE_OK");quit()
