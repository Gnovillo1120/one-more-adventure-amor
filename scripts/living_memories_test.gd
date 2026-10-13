extends SceneTree
var game: Node
var checks:=0
var failures:=0
func _initialize() -> void:call_deferred("run")
func verify(value: bool, label: String) -> void:
	checks+=1
	if not value:failures+=1;push_error(label)
func scene(ci: int, si: int) -> void:
	game.chapter_index=ci;game.scene_index=si;game.start_scene()
func run() -> void:
	if not OS.get_cmdline_user_args().has("--self-test"):quit(2);return
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	scene(1,0)
	var world: Node2D=game.memory
	verify(world.target_visuals.photos.visual_kind=="player","phone belongs to player rather than floor")
	for i in range(12):world.show_phone(i%2==0);world.living.tick(.05)
	world.show_phone(true);world.apply_line("Anami","Las fotos del modelo.");world.apply_line("Anami","Las fotos del modelo.")
	verify(world.phone_messages.size()==1,"message replay does not duplicate history")
	game._store_memory_state();game.start_scene();world=game.memory
	verify(world.living.phone_open and world.phone_messages.size()==1,"phone and history restore")
	world.show_phone(false);world.living.perform("living:drink");world.living.perform("living:sit");world.living.tick(.2)
	verify(world.living.state.drink and world.seated,"sit and drink semantic states coexist")
	game._store_memory_state();game.start_scene();world=game.memory
	verify(world.living.state.drink and world.living.state.sitting,"optional club activity checkpoint restores")
	world.living.perform("living:wing")
	verify(world.living.state.zone=="pool","connected pool wing opens")
	verify(not world.can_stand(Vector2(600,430)),"walking cannot cross pool water")
	world.living.perform("living:swim");verify(not world.living.state.swimming,"swimwear required")
	world.living.perform("living:change");verify(world.living.state.swimwear,"visible swimwear equipped")
	world.living.perform("living:swim");world.living.tick(1.0)
	verify(world.actors.anami.action_texture.resource_path.ends_with("anami_swimming.png") and world.actors.anami.action_row==4,"actual idle swimming frames selected")
	world.move_by(Vector2(3000,3000));verify(world.living.POOL.grow(-14).has_point(world.player_position),"swimming cannot leave water")
	game._store_memory_state();var saved_position: Array=[world.player_position.x,world.player_position.y];game.start_scene(false,saved_position);world=game.memory
	verify(world.living.state.swimming and world.can_stand(world.player_position),"swimming reload restores legal water position")
	world.living.perform("living:back");verify(world.living.state.zone=="pool","cannot exit club in swimsuit")
	world.living.perform("living:swim");world.living.tick(1.0);verify(not world.living.state.swimming and world.can_stand(world.player_position),"ladder returns swimmer to land")
	world.living.perform("living:change");world.living.perform("living:back")
	verify(world.living.state.zone=="main" and not world.living.state.swimwear,"normal outfit restored on promenade")
	scene(0,2);world=game.memory;world.living.perform("living:water");world.living.tick(.4)
	verify(world.living.busy and world.actors.anami.action_texture.resource_path.ends_with("anami_fountain.png"),"fountain has lean-and-drink sprite animation")
	game._toggle_pause();await create_timer(.1).timeout;verify(not world.active and world.living.busy,"pause suspends fountain activity")
	game._toggle_pause();await create_timer(2.3).timeout;verify(world.active and not world.living.busy,"fountain returns to idle without trapping player")
	game._scene_interaction();await create_timer(1.4).timeout
	verify(world.living.state.encounter and game._dialogue_open(),"approach and flinch precede authored apology")
	scene(2,0);world=game.memory;world.living.duration=1;world.living.start_outfit();world.living.tick(1.2)
	verify(world.living.state.outfit_phase=="failed" and not game.scene_completed,"timer failure does not advance or reset chapter")
	world.living.perform("living:mirror");verify(world.living.state.outfit_phase=="active","mirror retries only costume activity")
	world.living.duration=75;world.living.start_outfit();world.living.perform("living:dress");world.living.tick(.1)
	verify(world.actors.anami.action_texture.resource_path.ends_with("anami_outfits.png") and world.actors.anami.action_row==0,"dress visibly changes sprite")
	game._store_memory_state();game.start_scene();world=game.memory
	verify(world.living.state.pieces==["dress"] and world.living.state.outfit_phase=="active","partial outfit and countdown checkpoint restore")
	verify(world.interaction_targets().all(func(t: Dictionary):return t.id.begins_with("living:")),"active preparation cannot replay invitation")
	world.living.perform("living:bandana");world.living.tick(.1);verify(world.actors.anami.action_row==1,"red bandana visibly changes outfit stage")
	world.living.perform("living:sneakers");verify(world.living.state.outfit_phase=="complete","all three spatial outfit items succeed")
	verify(world.sprites.anami.resource_path.ends_with("anami_halloween.png"),"final outfit uses established dress bandana white sneakers")
	scene(2,1);verify(game.memory.sprites.anami.resource_path.ends_with("anami_halloween.png"),"party preserves final outfit")
	verify(game.memory.living.guests.size()>=30,"party populated with independent animated guests")
	for guest in game.memory.living.guests:verify(guest.actor.atlas_row in [3,4,5,6,7],"distinct costume or staff archetype")
	var before: Vector2=game.memory.living.guests[0].actor.position
	for i in range(120):game.memory.living.tick(.016)
	verify(game.memory.living.guests[0].actor.position!=before,"NPC route moves without synchronized sine loop")
	game.memory.living.perform("living:party_photo");game._store_memory_state();game._toggle_pause();game._album()
	verify(game.modal.get_children()[1].text.contains("Halloween"),"optional photograph unlocks album entry")
	scene(2,2);game.memory.apply_line("Narrador","Anami lo besó.");game._store_memory_state();game.start_scene(true)
	verify(game.memory.living.state.affection_frame==3 and game.memory.living.action=="affection","completed romantic pose restores")
	game.memory.living.tick(.01)
	verify(game.memory.actors.anami.position.distance_to(game.memory.companion_position)<40,"kiss has adjacent visual character composition")
	verify(game.memory.can_stand(game.memory.player_position),"romantic pose keeps a legal movement ground anchor")
	game.queue_free();await process_frame;await process_frame
	print("LIVING_MEMORIES_QA: ",checks," checks; ",failures," failures")
	quit(0 if failures==0 else 1)
