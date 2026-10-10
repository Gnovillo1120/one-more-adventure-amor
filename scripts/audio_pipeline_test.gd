extends SceneTree
var checks:=0
var failures:=0

func _initialize() -> void:call_deferred("run")

func verify(value: bool, label: String) -> void:
	checks+=1
	if not value:failures+=1;push_error(label)

func run() -> void:
	if not OS.get_cmdline_user_args().has("--self-test"):quit(2);return
	var director: Node=load("res://scripts/audio_director.gd").new();root.add_child(director)
	var folder: String="user://qa_audio_pipeline"
	DirAccess.make_dir_recursive_absolute(folder)
	# Test recordings are silence, explicitly QA fixtures rather than soundtrack assets.
	var source:=AudioStreamWAV.new();source.format=AudioStreamWAV.FORMAT_16_BITS;source.mix_rate=22050;source.stereo=true
	var data:=PackedByteArray();data.resize(8820);source.data=data
	verify(source.save_to_wav(folder+"/uees.wav")==OK,"write stereo WAV fixture")
	verify(source.save_to_wav(folder+"/ikura.wav")==OK,"write second WAV fixture")
	director.track_root=folder
	director.manifest.tracks.uees.loop_start=.02
	director.manifest.tracks.uees.loop_end=.08
	var wav: AudioStreamWAV=director._stream("uees")
	verify(wav!=null and wav.stereo,"replacement WAV decoded")
	verify(wav.loop_begin==441 and wav.loop_end==1764,"loop points measured in stereo frames")
	director.play("uees",.08);await create_timer(.12).timeout
	verify(director.track_available and is_equal_approx(director.gains[director.selected],1),"first track fades in")
	var previous: int=director.selected
	director.play("ikura",.2);await create_timer(.05).timeout
	verify(director.gains[previous]>0 and director.gains[director.selected]>0,"two tracks overlap during crossfade")
	director.volume=.2;director._process(0)
	verify(director.players[director.selected].volume_db<=linear_to_db(.2),"volume applies during crossfade")
	await create_timer(.25).timeout
	verify(not director.players[previous].playing and director.players[previous].stream==null,"faded player releases previous stream")
	director.play("missing",.08);await create_timer(.12).timeout
	verify(not director.track_available and director.gains==[0.0,0.0],"missing recording fades to silence")
	director.play("uees",.15);director.play("ikura",.15);director.play("uees",.02);await create_timer(.08).timeout
	verify(director.track_available and director.theme=="uees","rapid scene changes settle on latest track")
	for player in director.players:player.stop();player.stream=null
	await create_timer(.3).timeout
	director.queue_free();await process_frame;await process_frame
	for name in ["uees.wav","ikura.wav"]:DirAccess.remove_absolute(folder+"/"+name)
	DirAccess.remove_absolute(folder)
	print("AUDIO_PIPELINE_QA: ",checks," checks; ",failures," failures")
	quit(0 if failures==0 else 1)
