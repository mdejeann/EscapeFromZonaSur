# state_combat.gd
# Estado de combate: el enemigo persigue y ataca al objetivo.
# La agresividad y precisión dependen de la facción.
# Agente responsable: @ai
class_name StateCombat
extends Node


## Distancia máxima de disparo antes de perseguir.
@export var engage_range: float = 20.0

## Cadencia de disparo (segundos entre disparos).
@export var fire_rate: float = 0.8

## Daño por disparo.
@export var damage_per_shot: int = 10

## Probabilidad de acertar (0.0–1.0). Se reduce con distancia.
@export var base_accuracy: float = 0.6

## Umbral de salud para considerar huir (ratio 0.0–1.0).
@export var flee_health_ratio: float = 0.2

var _fire_timer: float = 0.0
var _target: Node3D = null
var _reposition_timer: float = 0.0


## Llamado al entrar al estado.
func enter(enemy: CharacterBody3D, combat_target: Node3D = null) -> void:
	_fire_timer = 0.0
	_reposition_timer = 0.0
	_target = combat_target
	# Emitir alerta para la escuadra
	EventBus.alert_raised.emit(enemy.global_position, enemy.faction)


## Llamado cada frame de física mientras el estado esté activo.
## Retorna la transición sugerida: "" = quedarse, "flee" = huir, "patrol" = volver.
func process(enemy: CharacterBody3D, delta: float) -> String:
	# Verificar si el objetivo sigue vivo
	if not is_instance_valid(_target):
		_target = _find_player(enemy)
		if _target == null:
			return "patrol"

	# Verificar si salud baja → huir
	if enemy.health.get_health_ratio() <= flee_health_ratio:
		return "flee"

	var distance := enemy.global_position.distance_to(_target.global_position)

	# Perseguir si está fuera de rango
	if distance > engage_range:
		enemy.nav_agent.target_position = _target.global_position
	else:
		_fire_timer += delta
		_reposition_timer += delta

		# Mirar al objetivo
		_face_target(enemy)

		# Disparar con cadencia
		if _fire_timer >= fire_rate:
			_fire_timer = 0.0
			_try_shoot(enemy, distance)

		# Reposicionar periódicamente (comportamiento más humano)
		if _reposition_timer >= 3.0:
			_reposition_timer = 0.0
			_reposition(enemy)

	return ""


## Llamado al salir del estado.
func exit(_enemy: CharacterBody3D) -> void:
	_target = null
	_fire_timer = 0.0


func _try_shoot(enemy: CharacterBody3D, distance: float) -> void:
	# Precisión disminuye con la distancia (falibilidad humana)
	var accuracy := base_accuracy * (1.0 - (distance / (engage_range * 1.5)))
	accuracy = clamp(accuracy, 0.1, base_accuracy)

	if randf() <= accuracy:
		# Impacto: verificar line of sight primero
		if _has_line_of_sight(enemy):
			if _target.has_method("take_damage"):
				_target.take_damage(damage_per_shot)

	# Generar ruido del disparo
	EventBus.noise_emitted.emit(enemy.global_position, 0.8)


func _has_line_of_sight(enemy: CharacterBody3D) -> bool:
	var space := enemy.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(
		enemy.global_position + Vector3.UP * 1.5,
		_target.global_position + Vector3.UP * 1.0,
		enemy.sensor.los_collision_mask,
		[enemy]
	)
	var result := space.intersect_ray(query)
	return result and result.get("collider") == _target


func _face_target(enemy: CharacterBody3D) -> void:
	var dir := (_target.global_position - enemy.global_position).normalized()
	if dir.length_squared() > 0.001:
		enemy.look_at(enemy.global_position + Vector3(dir.x, 0.0, dir.z), Vector3.UP)


func _reposition(enemy: CharacterBody3D) -> void:
	# Moverse lateralmente para no quedarse estático (más creíble)
	var lateral := enemy.global_transform.basis.x * randf_range(-3.0, 3.0)
	enemy.nav_agent.target_position = enemy.global_position + lateral


func _find_player(enemy: CharacterBody3D) -> Node3D:
	return enemy.get_tree().get_first_node_in_group("player")
