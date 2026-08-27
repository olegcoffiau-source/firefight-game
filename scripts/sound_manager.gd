extends Node

var audio_players: Array[AudioStreamPlayer] = []
var sound_cache: Dictionary = {}

func _ready() -> void:
	for i in range(16):
		var player := AudioStreamPlayer.new()
		player.bus = "Master"
		add_child(player)
		audio_players.append(player)
	_load_sounds()

func _load_sounds() -> void:
	var list = [
		"shot_rifle", "shot_smg", "shot_mg",
		"hit", "explosion", "click", "order", "victory", "defeat"
	]
	for s in list:
		var path = "res://assets/audio/" + s + ".wav"
		if ResourceLoader.exists(path):
			sound_cache[s] = load(path)

func play_sound(sfx_name: String, pitch_range: float = 0.1, volume_db: float = 0.0) -> void:
	if not sound_cache.has(sfx_name):
		return
	var stream: AudioStream = sound_cache[sfx_name]
	for player in audio_players:
		if not player.playing:
			player.stream = stream
			player.volume_db = volume_db
			player.pitch_scale = randf_range(1.0 - pitch_range, 1.0 + pitch_range)
			player.play()
			return
	if audio_players.size() > 0:
		audio_players[0].stream = stream
		audio_players[0].volume_db = volume_db
		audio_players[0].pitch_scale = randf_range(1.0 - pitch_range, 1.0 + pitch_range)
		audio_players[0].play()
