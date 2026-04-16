# state_patrol.gd
# Estado de patrulla: el enemigo recorre puntos de patrulla o vaga aleatoriamente.
# Agente responsable: @ai
class_name StatePatrol
extends Node


## Tiempo de espera en cada punto de patrulla (segundos).
@export var wait_time: float = 2.0

## Radio de vagabundeo si no hay puntos de patrulla asignados.
@export var wander_radius: float = 12.0

var _wait_timer: float = 0.0
var _waiting: bool = false
var _origin: Vector3 = Vector3.ZERO


## Llamado al entrar al estado.
func enter(enemy: CharacterBody3D) -> void:
	_waiting = false
	_wait_timer = 0.0
	_origin = enemy.global_position
	if enemy.patrol_points.is_empty():
		_pick_random_point(enemy)
	else:
		_go_to_patrol_point(enemy)


## Llamado cada frame de física mientras el estado esté activo.
func process(enemy: CharacterBody3D, delta: float) -> void:
	if _waiting:
		_wait_timer += delta
		if _wait_timer >= wait_time:
			_waiting = false
			_wait_timer = 0.0
			_advance_patrol(enemy)
		return

	if enemy.nav_agent.is_navigation_finished():
		_waiting = true
		_wait_timer = 0.0


## Llamado al salir del estado.
func exit(_enemy: CharacterBody3D) -> void:
	_waiting = false
	_wait_timer = 0.0


func _go_to_patrol_point(enemy: CharacterBody3D) -> void:
	if enemy.patrol_points.is_empty():
		return
	enemy.nav_agent.target_position = enemy.patrol_points[enemy.current_patrol_index]


func _advance_patrol(enemy: CharacterBody3D) -> void:
	if enemy.patrol_points.is_empty():
		_pick_random_point(enemy)
		return
	enemy.current_patrol_index = (enemy.current_patrol_index + 1) % enemy.patrol_points.size()
	_go_to_patrol_point(enemy)


func _pick_random_point(enemy: CharacterBody3D) -> void:
	var random_offset := Vector3(
		randf_range(-wander_radius, wander_radius),
		0.0,
		randf_range(-wander_radius, wander_radius)
	)
	enemy.nav_agent.target_position = _origin + random_offset
