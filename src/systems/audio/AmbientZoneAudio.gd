# AmbientZoneAudio.gd
# Zona de audio ambiental. Al entrar, hace crossfade al stream asignado.
# Colocar como Area3D en las distintas zonas del mapa.
# Agente responsable: @audio
class_name AmbientZoneAudio
extends Area3D


## Stream de audio ambiental que se reproduce al entrar a esta zona.
@export var ambient_stream: AudioStream

## Tiempo de crossfade en segundos al entrar/salir de la zona.
@export var crossfade_time: float = 2.0

## Nombre descriptivo de la zona (para debug).
@export var zone_name: String = "default"

## Nivel de reverb para esta zona (0.0 = seco/exterior, 1.0 = máximo/interior).
@export_range(0.0, 1.0) var reverb_amount: float = 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		if ambient_stream:
			AudioManager.play_ambient(ambient_stream, crossfade_time)
		_apply_reverb(reverb_amount)


func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		# Revertir reverb a exterior por defecto al salir
		_apply_reverb(0.0)


func _apply_reverb(amount: float) -> void:
	var bus_idx := AudioServer.get_bus_index("SFX")
	if bus_idx < 0:
		return

	# Buscar o crear efecto de reverb en el bus SFX
	for i in range(AudioServer.get_bus_effect_count(bus_idx)):
		var effect := AudioServer.get_bus_effect(bus_idx, i)
		if effect is AudioEffectReverb:
			effect.room_size = lerpf(0.0, 0.8, amount)
			effect.wet = lerpf(0.0, 0.4, amount)
			effect.dry = lerpf(1.0, 0.6, amount)
			return
