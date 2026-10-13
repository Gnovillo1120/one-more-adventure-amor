extends SceneTree
const Anim = preload("res://scripts/character_animation.gd")
var game: Node
var checks := 0
var failures := 0
func _initialize() -> void:call_deferred("run")
func verify(value: bool, label: String) -> void:
	checks+=1
	if not value:failures+=1;push_error(label)
func run() -> void:
	if not OS.get_cmdline_user_args().has("--self-test"):quit(2);return
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.chapter_index=1;game.scene_index=0;game.start_scene()
	var world: Node2D=game.memory;world.set_process(false)
	var living: Node2D=world.living
	living.perform("wing");living.perform("change");living.tick(1.0)
	verify(world.sprites.anami==Anim.WALK,"swimwear walking uses corrected atlas")
	verify(Anim.WALK.get_size()==Vector2(128,192),"walking is four 32x48 directional rows")
	verify(Anim.SWIM.get_size()==Vector2(192,288),"swimming has six 48x48 rows")
	for outfit in ["anami_casual","anami_formal","anami_halloween","guillermo_casual","guillermo_formal","guillermo_halloween"]:
		var texture: Texture2D=load("res://assets/art/sprites-v2/%s.png"%outfit)
		verify(texture.get_size()==Vector2(128,192),"established outfit has canonical bounds: "+outfit)
	var walk_images: Array=[];var swim_images: Array=[]
	for direction in range(4):
		world.direction=direction;world.moving=true;world._update_actors();living.tick(.125)
		verify(world.actors.anami.row==direction and world.actors.anami.action_row==-1,"land direction chooses one stable walking row")
		for sample in range(16):
			living.tick(.125);verify(world.actors.anami.column in [0,1,2,3],"walk frame bounds")
		world.moving=false;world._update_actors()
		for sample in range(4):living.tick(.25);verify(world.actors.anami.column==0,"stationary swimwear does not cycle")
		walk_images.append(Anim.WALK.get_image().get_region(Rect2i(0,direction*48,32,48)).get_data())
	for direction in range(1,4):verify(walk_images[0]!=walk_images[direction],"direction art differs from front view")
	living.perform("swim");living.tick(.2)
	verify(living.busy and living.pool_transition=="enter_pool" and not living.can_move(),"entry has locked ladder state")
	verify(world.actors.anami.action_row==5,"ladder uses climbing artwork")
	living.phone(true);verify(not living.phone_open,"phone cannot override ladder")
	living.pause_activities(true);game.is_paused=true;var time: float=living.transition_time;living.tick(.3)
	verify(living.transition_time==time,"pause freezes ladder")
	game.is_paused=false;living.pause_activities(false);living.tick(.7)
	verify(not living.busy and living.state.swimming and world.can_stand(world.player_position),"entry activates legal swimming destination")
	verify(living.splash_time>0,"entry emits splash")
	verify(world.active,"entry remains controllable after pause")
	for direction in range(4):
		world.direction=direction;world.moving=true
		for sample in range(12):
			living.tick(.125)
			verify(living.swim_animation=="swim_"+Anim.DIRECTIONS[direction] and world.actors.anami.action_row==direction,"swim direction uses its own stroke row")
			verify(world.actors.anami.action_frame in [0,1,2,3],"stroke bounds")
		swim_images.append(Anim.SWIM.get_image().get_region(Rect2i(0,direction*48,48,48)).get_data())
		world.moving=false;living.tick(.2)
		verify(living.swim_animation=="swim_idle" and world.actors.anami.action_row==4,"stopping selects distinct treading water")
	for direction in range(1,4):verify(swim_images[0]!=swim_images[direction],"four strokes have distinct artwork")
	living.perform("drink");living.phone(true);living.tick(.1)
	verify(living.swim_animation=="swim_idle" and not living.phone_open,"swimming priority prevents incompatible drink and phone")
	world.move_by(Vector2(9999,9999));verify(world.can_stand(world.player_position),"water boundaries preserved")
	living.perform("swim");living.tick(.2)
	verify(living.pool_transition=="exit_pool" and living.busy,"exit plays reverse ladder before movement")
	game._store_memory_state();game.start_scene(false,[world.player_position.x,world.player_position.y]);world=game.memory;world.set_process(false);living=world.living
	verify(not living.state.swimming and living.state.swimwear and not living.busy and world.can_stand(world.player_position),"save during exit resolves safely to walking swimsuit")
	living.perform("swim");living.tick(.1);game._store_memory_state();game.start_scene(false,[world.player_position.x,world.player_position.y]);world=game.memory;world.set_process(false);living=world.living
	verify(living.state.swimming and living.state.swimwear and not living.busy and world.can_stand(world.player_position),"save during entry resolves safely to swimmer")
	living.perform("swim");living.tick(1.0);living.tick(.1)
	verify(living.can_move() and world.actors.anami.action_row==-1,"exit restores ordinary walking")
	living.phone(true);living.tick(.1)
	verify(not living.can_move() and world.actors.anami.action_row==-1 and living.held_phone.visible,"swimwear phone preserves swimsuit and blocks walking")
	living.phone(false);living.tick(.5);living.perform("change");living.tick(1);living.perform("back")
	verify(not living.state.swimwear and world.sprites.anami.resource_path.ends_with("anami_casual.png"),"changing restores original casual outfit")
	living.perform("drink");world.moving=true;living.tick(.1)
	verify(world.actors.anami.action_row==-1 and living.carried_drink.visible,"walking cancels sip but retains carried drink")
	world.moving=false;living.perform("sit");living.tick(.5)
	verify(world.actors.anami.action_row==2 and world.actors.anami.action_frame==0,"sitting holds one coherent seated view")
	game.chapter_index=0;game.scene_index=2;game.start_scene();world=game.memory;world.set_process(false)
	for direction in range(4):
		world.direction=direction;world.moving=false;world.clock+=8;world._update_actors();world.living.tick(.2)
		verify(world.actors.anami.column==0 and world.actors.guillermo.column==0,"regular outfits hold stationary idle")
	game.queue_free();await process_frame;await process_frame
	print("ANIMATION_POLISH_QA: ",checks," checks; ",failures," failures");quit(0 if failures==0 else 1)
