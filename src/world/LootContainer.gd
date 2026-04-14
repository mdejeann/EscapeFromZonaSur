# LootContainer.gd
# Contenedor de loot interactuable. Referencia una tabla de loot por ID.
# Al ser abierto, solicita al LootSystem los ítems y los spawnea en el mundo.
# Agente responsable: @world
class_name LootContainer
extends Node3D


@export var container_id: String = ""           # ID único para este contenedor
@export var loot_table_id: String = "generic"   # ID de tabla en loot_tables.json
@export var interact_distance: float = 2.5      # metros máximos para interactuar
@export var item_scene: PackedScene             # escena de ítem en el mundo

var _is_open: bool = false
var _player_ref: Node3D = null


func _ready() -> void:
	add_to_group("interactable")
	EventBus.container_opened.connect(_on_any_container_opened)


## Llamado desde el sistema de interacción del jugador (WeaponHandler o similar).
func interact(player: Node3D) -> void:
	if _is_open:
		EventBus.hud_message_requested.emit("Ya revisado", 1.5)
		return

	if player.global_position.distance_to(global_position) > interact_distance:
		EventBus.hud_message_requested.emit("Demasiado lejos", 1.5)
		return

	_open(player)


func _open(player: Node3D) -> void:
	_is_open = true
	_player_ref = player
	EventBus.container_opened.emit(container_id)
	# LootSystem.gd escucha container_opened y spawnea ítems


func _on_any_container_opened(opened_id: String) -> void:
	# Solo reaccionar al propio container_id si necesitamos efectos visuales
	if opened_id == container_id:
		_play_open_animation()


func _play_open_animation() -> void:
	# Implementar animación de apertura (rotar tapa, partículas de polvo, etc.)
	pass
