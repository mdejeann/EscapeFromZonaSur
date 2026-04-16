# HUD.gd
# HUD de combate — muestra salud, munición, brújula y timer de extracción.
# Solo escucha señales del EventBus — nunca llama métodos del jugador.
# Agente responsable: @ui
class_name HUD
extends CanvasLayer


@onready var health_bar: ProgressBar = $MarginContainer/VBoxContainer/HealthBar
@onready var health_label: Label = $MarginContainer/VBoxContainer/HealthBar/HealthLabel
@onready var ammo_label: Label = $MarginContainer/VBoxContainer/AmmoContainer/AmmoLabel
@onready var weight_bar: ProgressBar = $MarginContainer/VBoxContainer/WeightBar
@onready var message_label: Label = $CenterContainer/MessageLabel
@onready var extraction_panel: PanelContainer = $ExtractionPanel
@onready var extraction_bar: ProgressBar = $ExtractionPanel/VBoxContainer/ExtractionBar
@onready var extraction_label: Label = $ExtractionPanel/VBoxContainer/ExtractionLabel
@onready var crosshair: TextureRect = $Crosshair

var _message_tween: Tween = null


func _ready() -> void:
	# Conectar señales del EventBus
	EventBus.health_changed.connect(_on_health_changed)
	EventBus.ammo_changed.connect(_on_ammo_changed)
	EventBus.weight_changed.connect(_on_weight_changed)
	EventBus.extraction_zone_entered.connect(_on_extraction_zone_entered)
	EventBus.extraction_zone_exited.connect(_on_extraction_zone_exited)
	EventBus.extraction_progress_changed.connect(_on_extraction_progress_changed)
	EventBus.extraction_completed.connect(_on_extraction_completed)
	EventBus.hud_message_requested.connect(_on_hud_message_requested)
	EventBus.player_died.connect(_on_player_died)

	# Estado inicial
	extraction_panel.visible = false
	message_label.visible = false


func _on_health_changed(current: int, maximum: int) -> void:
	health_bar.max_value = maximum
	# Animar la barra de salud con tween
	var tween := create_tween()
	tween.tween_property(health_bar, "value", float(current), 0.3).set_ease(Tween.EASE_OUT)
	health_label.text = "%d / %d" % [current, maximum]

	# Feedback visual: barra roja si salud baja
	if float(current) / float(maximum) < 0.25:
		health_bar.modulate = Color(1.0, 0.3, 0.3)
	else:
		health_bar.modulate = Color.WHITE


func _on_ammo_changed(current: int, reserve: int) -> void:
	ammo_label.text = "%d / %d" % [current, reserve]


func _on_weight_changed(current: float, maximum: float) -> void:
	weight_bar.max_value = maximum
	weight_bar.value = current
	# Rojo si está por encima del 90%
	if current / maximum > 0.9:
		weight_bar.modulate = Color(1.0, 0.3, 0.3)
	else:
		weight_bar.modulate = Color.WHITE


func _on_extraction_zone_entered(zone_name: String) -> void:
	extraction_panel.visible = true
	extraction_label.text = zone_name
	extraction_bar.value = 0.0


func _on_extraction_zone_exited(_zone_name: String) -> void:
	extraction_panel.visible = false


func _on_extraction_progress_changed(progress: float) -> void:
	extraction_bar.value = progress * 100.0


func _on_extraction_completed(_zone_name: String) -> void:
	extraction_panel.visible = false
	_show_message("¡EXTRACCIÓN COMPLETADA!", 3.0)


func _on_hud_message_requested(text: String, duration: float) -> void:
	_show_message(text, duration)


func _on_player_died() -> void:
	_show_message("HAS MUERTO", 5.0)


func _show_message(text: String, duration: float) -> void:
	message_label.text = text
	message_label.visible = true
	message_label.modulate.a = 1.0

	if _message_tween and _message_tween.is_running():
		_message_tween.kill()

	_message_tween = create_tween()
	_message_tween.tween_interval(duration)
	_message_tween.tween_property(message_label, "modulate:a", 0.0, 0.5)
	_message_tween.tween_callback(func() -> void: message_label.visible = false)
