# ExtractionZone.gd
# Zona de extracción — el jugador debe permanecer dentro para escapar del raid.
# Agente responsable: @world
class_name ExtractionZone
extends Area3D


@export var zone_name: String = "Extracción Norte"
@export var extraction_time: float = 5.0  # segundos para completar la extracción
@export var is_active: bool = true         # puede desactivarse por eventos del mundo

var _player_inside: bool = false
var _progress: float = 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _process(delta: float) -> void:
	if not is_active:
		return

	if _player_inside:
		_progress = min(1.0, _progress + delta / extraction_time)
		EventBus.extraction_progress_changed.emit(_progress)
		if _progress >= 1.0:
			_complete_extraction()
	else:
		# Retrocede lentamente si el jugador sale antes de completar
		_progress = max(0.0, _progress - delta * 0.5)
		if _progress < 1.0:
			EventBus.extraction_progress_changed.emit(_progress)


func _complete_extraction() -> void:
	set_process(false)
	EventBus.extraction_completed.emit(zone_name)


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		_player_inside = true
		EventBus.extraction_zone_entered.emit(zone_name)


func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		_player_inside = false
		if _progress < 1.0:
			EventBus.extraction_zone_exited.emit(zone_name)
