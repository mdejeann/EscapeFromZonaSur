# AudioManager.gd
# Autoload — gestión centralizada de audio: SFX espacial, música y ambiente.
# Agente responsable: @audio
extends Node


# ── Bus names (deben coincidir con el Audio Bus Layout del proyecto) ──────────
const BUS_MASTER := "Master"
const BUS_SFX    := "SFX"
const BUS_MUSIC  := "Music"
const BUS_AMBIENT := "Ambience"

# Pool de AudioStreamPlayer3D para SFX espacial
const SFX_POOL_SIZE := 16
var _sfx_pool: Array[AudioStreamPlayer3D] = []
var _sfx_pool_index: int = 0

# Música actual
var _music_player: AudioStreamPlayer = null
var _ambient_player: AudioStreamPlayer = null


func _ready() -> void:
	_build_sfx_pool()
	_music_player = _make_stream_player(BUS_MUSIC)
	_ambient_player = _make_stream_player(BUS_AMBIENT)

	# Conectar señales del EventBus
	EventBus.weapon_fired.connect(_on_weapon_fired)
	EventBus.player_footstep.connect(_on_player_footstep)
	_load_footstep_sounds()


# ── API pública ──────────────────────────────────────────────────────────────

## Reproduce un SFX en una posición 3D. Usa un pool para evitar GC pressure.
func play_sfx(stream: AudioStream, position: Vector3, volume_db: float = 0.0) -> void:
	var player := _get_sfx_player()
	player.stream = stream
	player.volume_db = volume_db
	player.global_position = position
	player.play()


## Cambia la música actual con crossfade.
func play_music(stream: AudioStream, fade_time: float = 1.0) -> void:
	if _music_player.playing:
		var tween := create_tween()
		tween.tween_property(_music_player, "volume_db", -80.0, fade_time)
		await tween.finished
	_music_player.stream = stream
	_music_player.volume_db = -80.0
	_music_player.play()
	var tween2 := create_tween()
	tween2.tween_property(_music_player, "volume_db", 0.0, fade_time)


## Cambia el audio de ambiente con crossfade.
func play_ambient(stream: AudioStream, fade_time: float = 2.0) -> void:
	if _ambient_player.playing:
		var tween := create_tween()
		tween.tween_property(_ambient_player, "volume_db", -80.0, fade_time)
		await tween.finished
	_ambient_player.stream = stream
	_ambient_player.volume_db = -80.0
	_ambient_player.play()
	var tween2 := create_tween()
	tween2.tween_property(_ambient_player, "volume_db", 0.0, fade_time)


## Ajusta el volumen de un bus (0.0 = silencio, 1.0 = máximo).
func set_bus_volume(bus_name: String, linear_volume: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(clamp(linear_volume, 0.0, 1.0)))


# ── Handlers de señales ──────────────────────────────────────────────────────

func _on_weapon_fired(_weapon_id: String, position: Vector3) -> void:
	# TODO Sprint 2: cargar stream según weapon_id desde diccionario de SFX
	EventBus.noise_emitted.emit(position, 1.0)  # disparo = ruido máximo


func _on_player_footstep(surface_type: String) -> void:
	var streams: Array = _footstep_streams.get(surface_type, _footstep_streams.get("concrete", []))
	if streams.size() > 0:
		var stream: AudioStream = streams[randi() % streams.size()]
		var player := _get_sfx_player()
		player.stream = stream
		player.volume_db = -6.0
		var p := get_tree().get_first_node_in_group("player")
		if p:
			player.global_position = p.global_position
		player.play()


# ── Footstep loading ────────────────────────────────────────────────────────

var _footstep_streams: Dictionary = {}

func _load_footstep_sounds() -> void:
	var base_path := "res://assets/audio/sfx/footsteps/"
	var surfaces := ["Asphalt", "Dirt", "Generic", "Grass"]
	for surface in surfaces:
		var streams: Array[AudioStream] = []
		for i in range(1, 9):
			var path := base_path + "Footstep_%s_%02d.wav" % [surface, i]
			if ResourceLoader.exists(path):
				streams.append(load(path))
		_footstep_streams[surface.to_lower()] = streams
	# Alias surfaces that don't have dedicated files
	_footstep_streams["concrete"] = _footstep_streams.get("asphalt", [])
	_footstep_streams["rock"] = _footstep_streams.get("dirt", [])
	_footstep_streams["metal"] = _footstep_streams.get("generic", [])
	_footstep_streams["cobblestone"] = _footstep_streams.get("asphalt", [])
	_footstep_streams["gravel"] = _footstep_streams.get("dirt", [])
	_footstep_streams["wood"] = _footstep_streams.get("generic", [])


# ── Privado ──────────────────────────────────────────────────────────────────

func _build_sfx_pool() -> void:
	for _i in range(SFX_POOL_SIZE):
		var p := AudioStreamPlayer3D.new()
		p.bus = BUS_SFX
		add_child(p)
		_sfx_pool.append(p)


func _get_sfx_player() -> AudioStreamPlayer3D:
	# Round-robin sobre el pool
	_sfx_pool_index = (_sfx_pool_index + 1) % SFX_POOL_SIZE
	return _sfx_pool[_sfx_pool_index]


func _make_stream_player(bus: String) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = bus
	add_child(p)
	return p
