# MainMenu.gd
# Pantalla de título con opciones de juego y persistencia de settings.
# Agente responsable: @ui
class_name MainMenu
extends Control


const SETTINGS_PATH := "user://settings.cfg"

@onready var new_game_button: Button = $VBoxContainer/NewGameButton
@onready var continue_button: Button = $VBoxContainer/ContinueButton
@onready var options_button: Button = $VBoxContainer/OptionsButton
@onready var quit_button: Button = $VBoxContainer/QuitButton
@onready var options_panel: PanelContainer = $OptionsPanel
@onready var sfx_slider: HSlider = $OptionsPanel/VBoxContainer/SFXSlider
@onready var music_slider: HSlider = $OptionsPanel/VBoxContainer/MusicSlider
@onready var ambient_slider: HSlider = $OptionsPanel/VBoxContainer/AmbientSlider
@onready var fullscreen_check: CheckBox = $OptionsPanel/VBoxContainer/FullscreenCheck
@onready var back_button: Button = $OptionsPanel/VBoxContainer/BackButton


func _ready() -> void:
	options_panel.visible = false
	_connect_buttons()
	_load_settings()

	# Verificar si hay partida guardada
	continue_button.disabled = not FileAccess.file_exists("user://stash.json")

	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _connect_buttons() -> void:
	new_game_button.pressed.connect(_on_new_game)
	continue_button.pressed.connect(_on_continue)
	options_button.pressed.connect(_on_options)
	quit_button.pressed.connect(_on_quit)
	back_button.pressed.connect(_on_back)

	sfx_slider.value_changed.connect(_on_sfx_changed)
	music_slider.value_changed.connect(_on_music_changed)
	ambient_slider.value_changed.connect(_on_ambient_changed)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)


func _on_new_game() -> void:
	GameState.start_raid("adrogue")
	get_tree().change_scene_to_file("res://scenes/world/adrogue/adrogue.tscn")


func _on_continue() -> void:
	GameState.start_raid("adrogue")
	get_tree().change_scene_to_file("res://scenes/world/adrogue/adrogue.tscn")


func _on_options() -> void:
	options_panel.visible = true


func _on_quit() -> void:
	get_tree().quit()


func _on_back() -> void:
	options_panel.visible = false
	_save_settings()


func _on_sfx_changed(value: float) -> void:
	AudioManager.set_bus_volume("SFX", value)


func _on_music_changed(value: float) -> void:
	AudioManager.set_bus_volume("Music", value)


func _on_ambient_changed(value: float) -> void:
	AudioManager.set_bus_volume("Ambience", value)


func _on_fullscreen_toggled(toggled: bool) -> void:
	if toggled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "sfx_volume", sfx_slider.value)
	config.set_value("audio", "music_volume", music_slider.value)
	config.set_value("audio", "ambient_volume", ambient_slider.value)
	config.set_value("display", "fullscreen", fullscreen_check.button_pressed)
	config.save(SETTINGS_PATH)


func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		# Valores por defecto
		sfx_slider.value = 0.8
		music_slider.value = 0.6
		ambient_slider.value = 0.7
		return

	sfx_slider.value = config.get_value("audio", "sfx_volume", 0.8)
	music_slider.value = config.get_value("audio", "music_volume", 0.6)
	ambient_slider.value = config.get_value("audio", "ambient_volume", 0.7)
	fullscreen_check.button_pressed = config.get_value("display", "fullscreen", false)

	# Aplicar los valores cargados
	AudioManager.set_bus_volume("SFX", sfx_slider.value)
	AudioManager.set_bus_volume("Music", music_slider.value)
	AudioManager.set_bus_volume("Ambience", ambient_slider.value)
