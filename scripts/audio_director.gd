extends Node
## Two-player equal-power crossfades. Missing licensed replacements fade to silence.
var players: Array[AudioStreamPlayer] = []
var gains := [0.0,0.0]
var selected := -1
var volume := .65
var theme := ""
var manifest: Dictionary = {}
var fade: Tween
var track_available := false
var track_root := "res://assets/audio/instrumental"
var external_root := ""
var user_root := "user://music"
var loaded_path := ""

func _ready() -> void:
	manifest=JSON.parse_string(FileAccess.get_file_as_string("res://data/audio_tracks.json"))
	if not OS.has_feature("editor"):external_root=OS.get_executable_path().get_base_dir().path_join("music")
	for i in range(2):
		var player:=AudioStreamPlayer.new();add_child(player);players.append(player)

func _process(_delta: float) -> void:
	for i in range(2):players[i].volume_db=linear_to_db(maxf(volume*gains[i],.00001))

func _stream(name: String) -> AudioStream:
	loaded_path=""
	for folder in [external_root,user_root,track_root]:
		if folder=="":continue
		var config: Dictionary=manifest.get("tracks",{}).get(name,{}).duplicate()
		var loop_file: String=folder+"/tracks.json"
		if FileAccess.file_exists(loop_file):
			var parser:=JSON.new()
			if parser.parse(FileAccess.get_file_as_string(loop_file))==OK and parser.data is Dictionary:
				var override=parser.data.get(name,{})
				if override is Dictionary:config.merge(override,true)
		for extension in ["ogg","wav"]:
			var path: String="%s/%s.%s" % [folder,name,extension]
			var audio: AudioStream
			if ResourceLoader.exists(path):audio=load(path)
			elif FileAccess.file_exists(path):audio=AudioStreamOggVorbis.load_from_file(path) if extension=="ogg" else AudioStreamWAV.load_from_file(path)
			else:continue
			if audio==null:continue
			if audio is AudioStreamOggVorbis:audio.loop=true;audio.loop_offset=maxf(0,float(config.get("loop_start",0)))
			if audio is AudioStreamWAV:
				audio.loop_mode=AudioStreamWAV.LOOP_FORWARD
				var divisor:= (2 if audio.format==AudioStreamWAV.FORMAT_16_BITS else 1)*(2 if audio.stereo else 1)
				var frames: int=audio.data.size()/divisor
				audio.loop_begin=clampi(int(float(config.get("loop_start",0))*audio.mix_rate),0,maxi(0,frames-1))
				audio.loop_end=clampi(int(float(config.loop_end)*audio.mix_rate),audio.loop_begin+1,frames) if config.get("loop_end",0)>0 else frames
			loaded_path=path
			return audio
	return null

func reload_tracks() -> void:
	var previous:=theme;theme="";play(previous)

func status_text() -> String:
	return "Música instrumental: "+theme if track_available else "Música pendiente · añade archivos a music junto al juego."

func play(name: String, seconds: float = 1.25) -> void:
	if theme==name:return
	theme=name
	if fade and fade.is_valid():fade.kill()
	var audio:=_stream(name)
	track_available=audio!=null
	var previous:=selected
	selected=1 if selected==0 else 0
	players[selected].stop();players[selected].stream=audio;gains[selected]=0
	if audio:players[selected].play()
	var target:=selected
	var starts:=gains.duplicate()
	fade=create_tween()
	fade.tween_method(func(t: float):
		gains[target]=sin(t*PI*.5) if audio else 0.0
		if previous>=0:gains[previous]=float(starts[previous])*cos(t*PI*.5),0.0,1.0,maxf(seconds,.01))
	fade.tween_callback(func():
		gains[target]=1.0 if audio else 0.0
		if previous>=0:gains[previous]=0.0;players[previous].stop();players[previous].stream=null)

func _exit_tree() -> void:
	if fade and fade.is_valid():fade.kill()
	for player in players:player.stop();player.stream=null
