extends SceneTree
## Render the preserved pre-overhaul PCK without checking out or changing source.
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var pack:=ProjectSettings.globalize_path("res://builds/interactive-memory-minigames/One More Adventure Amor.pck")
	if not ProjectSettings.load_resource_pack(pack,true):push_error("Preserved baseline pack missing");quit(1);return
	var game: Node=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	if game.has_method("_capture_living"):push_error("Baseline pack did not override current resources");quit(1);return
	game.capture_directory=ProjectSettings.globalize_path("res://docs/living/before")
	DirAccess.make_dir_recursive_absolute(game.capture_directory)
	for entry in [[1,0,"yacht"],[0,2,"uess"],[2,1,"party"]]:
		game.chapter_index=entry[0];game.scene_index=entry[1];game.start_scene();await create_timer(.6).timeout;await game._capture_frame(entry[2])
	print("LIVING_BEFORE_CAPTURE_OK");game.queue_free();await process_frame;quit()
