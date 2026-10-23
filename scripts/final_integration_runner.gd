extends "res://scripts/baking_input_runner.gd"
## Native source/export checks; real key/mouse events exercise the letter and volume UI.
var tracks: Array = []
var routes: Array = []
var no_music := false
var output_capture: AudioEffectCapture

func check_theme(expected: String) -> void:
	verify(game.audio_director.theme==expected,"scene selects "+expected)
	verify(game.audio_director.track_available!=no_music,"recording availability matches package")
	routes.append({"stage":game.stage,"scene":game._scene().id,"theme":expected,"loaded_path":game.audio_director.loaded_path})

func click_named(text: String, node: Node) -> bool:
	for child in node.get_children():
		if child is Button and child.text==text:
			var point: Vector2=child.get_global_rect().get_center()
			await mouse_button(point,true);await mouse_button(point,false);return true
		if await click_named(text,child):return true
	return false

func run() -> void:
	no_music=OS.get_cmdline_user_args().has("--expect-no-music")
	capture=DisplayServer.get_name()!="headless" and directory!=""
	DirAccess.make_dir_recursive_absolute(directory)
	game.volume=.65;game._apply_audio()
	if capture:
		output_capture=AudioEffectCapture.new();AudioServer.add_bus_effect(0,output_capture)
	for name in game.audio_director.manifest.tracks:
		game.audio_director.play(name,.05);await get_tree().create_timer(.12).timeout
		verify(game.audio_director.track_available!=no_music,"track availability: "+name)
		var row: Dictionary={"track":name,"path":game.audio_director.loaded_path,"available":game.audio_director.track_available}
		if not no_music:
			var player: AudioStreamPlayer=game.audio_director.players[game.audio_director.selected]
			verify(player.stream.get_length()>30 and player.playing,"full recording decoded and playing: "+name)
			row["duration"]=player.stream.get_length()
			player.seek(float(game.audio_director.loop_config.get("loop_start",0))+2)
			if capture:
				output_capture.clear_buffer();await get_tree().create_timer(.18).timeout
				var pcm:=output_capture.get_buffer(output_capture.get_frames_available());var peak:=0.0
				for sample in pcm:peak=maxf(peak,maxf(absf(sample.x),absf(sample.y)))
				verify(pcm.size()>0 and peak>.000001,"real mixer produces audible samples: "+name);row["mixer_peak"]=peak
		tracks.append(row)
	if not no_music:
		for name in ["ikura","uess"]:
			game.audio_director.play(name,.03);await get_tree().create_timer(.08).timeout
			var old: int=game.audio_director.selected
			game.audio_director.players[old].seek(float(game.audio_director.loop_config.loop_end)-.3)
			await get_tree().create_timer(.15).timeout
			verify(game.audio_director.selected!=old and game.audio_director.gains[old]>0,"OGG/WAV loop seam crossfades: "+name)
			await get_tree().create_timer(1).timeout
			verify(not game.audio_director.players[old].playing,"loop releases outgoing voice: "+name)
		game.audio_director.play("ending",.4);await get_tree().create_timer(.1).timeout
		verify(game.audio_director.gains[0]>0 and game.audio_director.gains[1]>0,"scene music overlaps only during crossfade")
		await get_tree().create_timer(.4).timeout
		verify(not game.audio_director.players[1-game.audio_director.selected].playing,"only one voice remains after fade")
		var voice: int=game.audio_director.selected;game.audio_director.play("ending")
		verify(voice==game.audio_director.selected,"same track does not restart or duplicate")
	game.show_menu();check_theme("play_game");await shot("01_main_menu")
	game.director.show_room();check_theme("memories_hub");await shot("02_memory_room")
	var expected: Array=[["uess","uess","uess","uess","uess","uess"],["yacht","intimate","ikura"],["intimate","halloween","intimate"],["cookies"],["minecraft","minecraft"],["ending","ending"]]
	for c in range(6):
		for s in range(expected[c].size()):
			game.chapter_index=c;game.scene_index=s;game.start_scene();await get_tree().process_frame;check_theme(expected[c][s])
	# Existing 3D quest state drives exploration/confrontation music; gameplay is unchanged.
	game.chapter_index=4;game.scene_index=0;game._start_voxel();await get_tree().process_frame;check_theme("minecraft")
	game.voxel.quest_index=8;await get_tree().process_frame;check_theme("boss")
	await tap(KEY_ESCAPE);verify(await click_named("Libro de recuerdos",game.ui),"boss pause opens scrapbook")
	await get_tree().process_frame;check_theme("memories_hub");await tap(KEY_ESCAPE);check_theme("boss");await tap(KEY_ESCAPE)
	# Music for scrapbook opened while pausing another chapter, then restored.
	game.chapter_index=0;game.scene_index=0;game.start_scene();await tap(KEY_ESCAPE)
	verify(await click_named("Libro de recuerdos",game.ui),"actual mouse opens scrapbook")
	check_theme("memories_hub");await shot("03_scrapbook");await tap(KEY_ESCAPE);check_theme("uess");await tap(KEY_ESCAPE)
	game.show_menu();game._settings(game.show_menu)
	var slider: HSlider
	for child in game.modal.get_children():
		if child is HSlider and child.max_value==1:slider=child
	verify(is_instance_valid(slider),"music slider exists");slider.grab_focus();await tap(KEY_HOME)
	verify(is_zero_approx(game.volume) and game.audio_director.players[game.audio_director.selected].volume_db<=-80,"Home on real volume control mutes music")
	await shot("04_music_muted");await tap(KEY_END)
	verify(is_equal_approx(game.volume,1) and game.audio_director.volume==1,"End restores volume through settings signal")
	game.volume=.65;game._apply_audio()
	game.chapter_index=5;game.scene_index=1;game.start_scene();await walk(Vector2(790,480))
	verify(game.memory.prompt()=="E · Leer carta","real beach letter prompt")
	await shot("05_letter_prompt");await tap(KEY_E)
	verify(game._dialogue_open() and is_instance_valid(game.letter_view),"E opens sunset letter card")
	var expected_hash: String=JSON.parse_string(FileAccess.get_file_as_string("res://data/final_letter_integrity.json")).sha256_utf8
	verify(game.letter_view.body.text.sha256_text()==expected_hash,"every UTF-8 character matches supplied letter")
	check_theme("ending");await shot("06_letter_top")
	await tap(KEY_END);await shot("07_letter_bottom")
	var bar: VScrollBar=game.letter_view.body.get_v_scroll_bar()
	verify(bar.value>0 and bar.value+bar.page>=bar.max_value-2,"keyboard reaches complete last line")
	await get_tree().create_timer(.5).timeout
	verify(game._dialogue_open(),"letter never advances on a timer")
	await tap(KEY_HOME);verify(bar.value==0,"Home returns to first word")
	var saved: Dictionary=game._save_payload();game.chapter_state=saved.chapter_state;game.start_scene(false,saved.position)
	verify(game.letter_view.body.text.sha256_text()==expected_hash,"saved open letter restores verbatim")
	game._restore_dialogue({"context":"scene","index":2,"lines":[{"speaker":"Guillermo","text":"legacy placeholder"}]})
	verify(game.letter_view.body.text.sha256_text()==expected_hash,"old placeholder checkpoint migrates to actual letter")
	await tap(KEY_E);verify(game.stage=="credits" and game.director.recovered(5),"reading completes beach memory and reaches credits")
	game._credits();check_theme("ending");await shot("08_credits")
	verify(await click_named("Leer la carta de nuevo",game.ui),"credits button reopens letter")
	verify(game.letter_view.body.text.sha256_text()==expected_hash,"letter remains replayable")
	await tap(KEY_E);game.show_menu();check_theme("play_game")
	if capture:AudioServer.remove_bus_effect(0,AudioServer.get_bus_effect_count(0)-1)
	var file:=FileAccess.open(directory.path_join("FINAL_INTEGRATION_TRACE.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"without_recordings":no_music,"letter_sha256":expected_hash,"tracks":tracks,"routes":routes,"events":events},"  "));file.close()
	print("FINAL_INTEGRATION_QA: %d checks; %d failures"%[checks,failures]);finished.emit(checks,failures)
