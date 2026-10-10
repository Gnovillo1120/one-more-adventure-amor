extends SceneTree
var checks:=0
var failures:=0
func _initialize() -> void:call_deferred("run")
func verify(value: bool, label: String) -> void:
	checks+=1
	if not value:failures+=1;push_error(label)
func run() -> void:
	if not OS.get_cmdline_user_args().has("--self-test"):quit(2);return
	var game: Node=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	for ci in range(6):
		for si in range(game.story.chapters[ci].scenes.size()):
			game.chapter_index=ci;game.scene_index=si;game.start_scene()
			var memory: Node2D=game.memory
			for i in range(memory.scene_config.steps.size()):
				memory.quest_step=i;memory._sync_target_visuals()
				var target: Dictionary=memory.mandatory_target()
				var prop: Node2D=memory.target_visuals[target.id]
				verify(memory.has_target_visual(target.id),"required object exists: "+str(game._scene().id)+"/"+target.id)
				verify(prop.visible and prop.enabled,"required object visible and highlighted")
				verify(prop.position==Vector2(target.position[0],target.position[1]),"object anchor equals interaction point")
				verify(prop.interaction_area.global_position==prop.global_position,"trigger and object aligned")
				verify(prop.interaction_area.get_child(0).shape.radius==memory.INTERACTION_RADIUS,"trigger distance matches prompt")
				verify(memory.can_stand(prop.position),"visible object can be approached")
			memory.completed=true;memory._sync_target_visuals()
			var exit: Node2D=memory.target_visuals.exit
			verify(exit.visible and exit.enabled and exit.has_representation(),"visible completed exit: "+str(game._scene().id))
			verify(exit.visual_kind in ["door","gate","arch"],"exit is a real doorway or gate")
			verify(exit.position==memory.exit_position,"exit trigger anchored to doorway")
			game.start_scene(true,[memory.player_position.x,memory.player_position.y])
			verify(game.memory.target_visuals.exit.visible,"loaded completed scene retains visible exit")
	game.chapter_index=4;game.scene_index=0;game._start_voxel()
	for key in game.voxel.targets:
		verify(game.voxel.target_objects.has(key),"3D target object registered: "+key)
		var object: Node3D=game.voxel.target_objects[key]
		verify(object.visible and object.get_child_count()>0,"3D target has real visible geometry: "+key)
		verify(object.position.distance_to(game.voxel.targets[key])<.01,"3D target object aligned: "+key)
	game.queue_free();await process_frame;await process_frame
	print("TARGET_VISIBILITY_QA: ",checks," checks; ",failures," failures")
	quit(0 if failures==0 else 1)
