# state_flee.gd
# Estado de huida: el enemigo escapa del peligro.
# Busca un punto seguro lejos del jugador/amenaza.
# Agente responsable: @ai
class_name StateFlee
extends Node


## Distancia mínima para sentirse "seguro" y detenerse.
@export var safe_distance: float = 30.0

## Velocidad multiplicada durante la huida.
@export var flee_speed_multiplier: float = 1.5

## Tiempo máximo huyendo antes de reconsiderar (segundos).
@export var flee_timeout: float = 8.0

var _timer: float = 0.0
var _threat_position: Vector3 = Vector3.ZERO
var _original_speed: float = 0.0


## Llamado al entrar al estado.
func enter(enemy: CharacterBody3D, threat_pos: Vector3 = Vector3.ZERO) -> void:
	_timer = 0.0
	_threat_position = threat_pos
	_original_speed = enemy.move_speed
	enemy.move_speed *= flee_speed_multiplier

	if _threat_position == Vector3.ZERO:
		var player := enemy.get_tree().get_first_node_in_group("player")
		if player:
			_threat_position = player.global_position

	_pick_flee_point(enemy)


## Llamado cada frame de física mientras el estado esté activo.
## Retorna la transición sugerida: "" = quedarse, "patrol" = volver.
func process(enemy: CharacterBody3D, delta: float) -> String:
	_timer += delta

	if _timer >= flee_timeout:
		return "patrol"

	# Si ya estamos lejos del peligro, volver a patrullar
	var distance := enemy.global_position.distance_to(_threat_position)
	if distance >= safe_distance:
		return "patrol"

	# Si llegamos al punto de huida pero aún no estamos seguros, buscar otro punto
	if enemy.nav_agent.is_navigation_finished() and distance < safe_distance:
		_pick_flee_point(enemy)

	return ""


## Llamado al salir del estado.
func exit(enemy: CharacterBody3D) -> void:
	enemy.move_speed = _original_speed
	_timer = 0.0


func _pick_flee_point(enemy: CharacterBody3D) -> void:
	# Calcular dirección opuesta a la amenaza
	var away_dir := (enemy.global_position - _threat_position).normalized()
	# Agregar algo de aleatoriedad para no ser predecible
	var jitter := Vector3(randf_range(-0.3, 0.3), 0.0, randf_range(-0.3, 0.3))
	var flee_target := enemy.global_position + (away_dir + jitter).normalized() * safe_distance
	enemy.nav_agent.target_position = flee_target
