# AmbientAudioSystem.gd
# Sistema de audio ambiental dinámico — pájaros, viento, clima.
# Se adjunta al nivel/mundo para generar sonidos ambiente alrededor del jugador.
# Agente responsable: @audio
extends Node


@export_group("Weather Ambient")
@export var weather_ambient_path: String = "res://assets/audio/ambient/weather/"
@export var weather_crossfade_time: float = 3.0

@export_group("Dynamic Ambient")
@export var dynamic_ambient_path: String = "res://assets/audio/ambient/dynamic/"
@export var dynamic_spawn_interval: float = 8.0
@export var dynamic_spawn_radius: float = 30.0
@export var max_concurrent_dynamic: int = 3

enum TimeOfDay { DAWN, DAY, DUSK, NIGHT }
var _current_tod: TimeOfDay = TimeOfDay.DAY
var _weather_player: AudioStreamPlayer
var _dynamic_timer: float = 0.0
var _active_dynamic_players: Array[AudioStreamPlayer3D] = []

# Loaded streams
var _weather_streams: Dictionary = {}
var _dynamic_streams: Array[AudioStream] = []


func _ready() -> void:
	_weather_player = AudioStreamPlayer.new()
	_weather_player.bus = "Ambience"
	_weather_player.volume_db = -10.0
	add_child(_weather_player)

	_load_weather_streams()
	_load_dynamic_streams()
	_play_weather_for_tod(_current_tod)


func _process(delta: float) -> void:
	_dynamic_timer += delta
	if _dynamic_timer >= dynamic_spawn_interval:
		_dynamic_timer = 0.0
		_try_spawn_dynamic_sound()

	# Clean up finished dynamic players
	for i in range(_active_dynamic_players.size() - 1, -1, -1):
		if not _active_dynamic_players[i].playing:
			_active_dynamic_players[i].queue_free()
			_active_dynamic_players.remove_at(i)


func set_time_of_day(tod: TimeOfDay) -> void:
	if tod != _current_tod:
		_current_tod = tod
		_play_weather_for_tod(tod)


func _load_weather_streams() -> void:
	var files := {
		TimeOfDay.DAWN: "Ambient_Dawn.wav",
		TimeOfDay.DAY: "Ambient_Day.wav",
		TimeOfDay.DUSK: "Ambient_Dusk.wav",
		TimeOfDay.NIGHT: "Ambient_Night.wav",
	}
	for tod in files:
		var path := weather_ambient_path + files[tod]
		if ResourceLoader.exists(path):
			_weather_streams[tod] = load(path)


func _load_dynamic_streams() -> void:
	var dynamic_files := [
		"Blackbird_01.wav", "Blackbird_02.wav",
		"Crow_01.wav", "Crow_02.wav", "Crow_03.wav", "Crow_04.wav",
		"Crow_Group_01.wav", "Crow_Group_02.wav",
		"Dog_01.wav", "Dog_02.wav",
		"Bird_Alarm_01.wav", "Bird_Alarm_02.wav", "Bird_Alarm_03.wav",
		"Tree_Creak_01.wav", "Tree_Creak_02.wav",
		"Wind_Gust_01.wav", "Wind_Gust_02.wav",
	]
	for filename in dynamic_files:
		var path := dynamic_ambient_path + filename
		if ResourceLoader.exists(path):
			_dynamic_streams.append(load(path))


func _play_weather_for_tod(tod: TimeOfDay) -> void:
	if not _weather_streams.has(tod):
		return
	var stream: AudioStream = _weather_streams[tod]
	if _weather_player.playing:
		var tween := create_tween()
		tween.tween_property(_weather_player, "volume_db", -80.0, weather_crossfade_time)
		await tween.finished
	_weather_player.stream = stream
	_weather_player.volume_db = -80.0
	_weather_player.play()
	var tween2 := create_tween()
	tween2.tween_property(_weather_player, "volume_db", -10.0, weather_crossfade_time)


func _try_spawn_dynamic_sound() -> void:
	if _dynamic_streams.size() == 0:
		return
	if _active_dynamic_players.size() >= max_concurrent_dynamic:
		return

	var player := get_tree().get_first_node_in_group("player")
	if not player:
		return

	var stream: AudioStream = _dynamic_streams[randi() % _dynamic_streams.size()]
	var audio := AudioStreamPlayer3D.new()
	audio.stream = stream
	audio.bus = "Ambience"
	audio.volume_db = randf_range(-15.0, -5.0)
	audio.max_distance = 50.0
	audio.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE

	# Random position around player
	var angle := randf() * TAU
	var dist := randf_range(10.0, dynamic_spawn_radius)
	var offset := Vector3(cos(angle) * dist, randf_range(2.0, 8.0), sin(angle) * dist)
	audio.global_position = player.global_position + offset

	add_child(audio)
	audio.play()
	_active_dynamic_players.append(audio)
