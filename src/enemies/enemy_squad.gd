# EnemySquad.gd
# Coordinación de escuadra entre enemigos de la misma facción.
# Los miembros se comunican vía señales de EventBus (no llamadas directas).
# Agente responsable: @ai
class_name EnemySquad
extends Node


## Facción de esta escuadra.
@export var faction: String = "generic"

## Distancia máxima entre miembros para considerarlos "en rango" de escuadra.
@export var squad_range: float = 30.0

## Máximo de miembros por escuadra.
@export var max_members: int = 4

## Miembros actuales de la escuadra.
var members: Array[Node3D] = []

## Posición del último avistamiento del jugador compartido con la escuadra.
var last_known_player_pos: Vector3 = Vector3.ZERO

## True si la escuadra está en estado de alerta o combate.
var is_alerted: bool = false


func _ready() -> void:
	EventBus.alert_raised.connect(_on_alert_raised)
	EventBus.enemy_died.connect(_on_enemy_died)
	EventBus.enemy_spotted_player.connect(_on_player_spotted)


## Registra un enemigo como miembro de esta escuadra.
func register_member(enemy: Node3D) -> bool:
	if members.size() >= max_members:
		return false
	if enemy in members:
		return false
	members.append(enemy)
	return true


## Elimina un miembro de la escuadra.
func unregister_member(enemy: Node3D) -> void:
	members.erase(enemy)


## Devuelve los miembros que están dentro del rango de escuadra de una posición dada.
func get_nearby_members(position: Vector3) -> Array[Node3D]:
	var nearby: Array[Node3D] = []
	for member in members:
		if is_instance_valid(member) and member.global_position.distance_to(position) <= squad_range:
			nearby.append(member)
	return nearby


## Devuelve el número de miembros vivos.
func get_alive_count() -> int:
	var count := 0
	for member in members:
		if is_instance_valid(member):
			count += 1
	return count


## Sugiere posiciones de flanqueo alrededor de un objetivo.
func get_flank_positions(target_pos: Vector3) -> Array[Vector3]:
	var positions: Array[Vector3] = []
	var alive := get_alive_count()
	if alive == 0:
		return positions

	# Distribuir miembros en arco alrededor del objetivo
	var angle_step := TAU / max(alive, 1)
	var base_dir := Vector3.FORWARD
	var flank_distance := 10.0

	for i in range(alive):
		var angle := angle_step * i
		var offset := base_dir.rotated(Vector3.UP, angle) * flank_distance
		positions.append(target_pos + offset)

	return positions


func _on_alert_raised(position: Vector3, alert_faction: String) -> void:
	if alert_faction != faction:
		return
	is_alerted = true
	last_known_player_pos = position

	# Notificar a todos los miembros cercanos
	for member in members:
		if is_instance_valid(member) and member.global_position.distance_to(position) <= squad_range:
			if member.has_method("on_squad_alert"):
				member.on_squad_alert(position)


func _on_player_spotted(enemy_position: Vector3, spotted_faction: String) -> void:
	if spotted_faction != faction:
		return
	last_known_player_pos = enemy_position
	is_alerted = true


func _on_enemy_died(position: Vector3, dead_faction: String, _loot_table_id: String) -> void:
	if dead_faction != faction:
		return

	# Limpiar miembros muertos
	members = members.filter(func(m: Node3D) -> bool: return is_instance_valid(m))

	# Si quedan pocos miembros, los sobrevivientes pueden huir
	if get_alive_count() <= 1:
		for member in members:
			if is_instance_valid(member) and member.has_method("on_squad_broken"):
				member.on_squad_broken()
