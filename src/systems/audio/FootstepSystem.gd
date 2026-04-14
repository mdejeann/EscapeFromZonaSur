# FootstepSystem.gd
# Reproduce SFX de pasos según la superficie bajo el jugador.
# Escucha EventBus.player_footstep para desacoplar de @core.
# Agente responsable: @audio
class_name FootstepSystem
extends Node


## Diccionario de streams de pasos por tipo de superficie.
## Configurar desde el editor asignando AudioStream a cada superficie.
@export var footstep_streams: Dictionary = {}

## Variación aleatoria de pitch para mayor naturalidad.
@export var pitch_variation: float = 0.15

## Volumen base de los pasos en dB.
@export var volume_db: float = -6.0


func _ready() -> void:
	EventBus.player_footstep.connect(_on_player_footstep)


func _on_player_footstep(surface_type: String) -> void:
	var stream: AudioStream = _get_stream_for_surface(surface_type)
	if stream == null:
		return

	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return

	# Usar AudioManager para reproducir el SFX espacial
	var pitch := 1.0 + randf_range(-pitch_variation, pitch_variation)
	AudioManager.play_sfx(stream, player.global_position, volume_db)

	# Emitir ruido para que los enemigos puedan escuchar los pasos
	var loudness := 0.3  # pasos normales — bajo
	if Input.is_action_pressed("sprint"):
		loudness = 0.6  # corriendo — más audible
	EventBus.noise_emitted.emit(player.global_position, loudness)


func _get_stream_for_surface(surface_type: String) -> AudioStream:
	if footstep_streams.has(surface_type):
		return footstep_streams[surface_type]
	# Fallback a superficie por defecto
	if footstep_streams.has("concrete"):
		return footstep_streams["concrete"]
	return null
