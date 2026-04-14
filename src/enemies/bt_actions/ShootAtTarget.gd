# ShootAtTarget.gd
# Beehave ActionLeaf — el enemigo dispara al jugador si tiene línea de visión.
# Requiere que SensorComponent haya detectado al jugador (suspicion >= 100).
# Agente responsable: @ai
class_name ShootAtTarget
extends Node


## Daño base por disparo.
@export var damage: int = 10

## Cadencia de disparo (segundos entre disparos).
@export var fire_rate: float = 0.5

## Precisión del enemigo (0.0 = perfecto, 1.0 = muy impreciso).
@export_range(0.0, 1.0) var inaccuracy: float = 0.3

var _fire_timer: float = 0.0


## Llamado por el behavior tree cada tick.
func tick(actor: Node, blackboard: Dictionary) -> int:
	var sensor: Node = actor.get_node("SensorComponent")
	if sensor == null or sensor.suspicion < 100.0:
		return 0  # FAILURE — no ve al jugador

	var player := actor.get_tree().get_first_node_in_group("player")
	if player == null:
		return 0  # FAILURE

	# Apuntar al jugador
	var direction := (player.global_position - actor.global_position).normalized()
	actor.look_at(actor.global_position + Vector3(direction.x, 0.0, direction.z), Vector3.UP)

	# Controlar cadencia
	_fire_timer += actor.get_process_delta_time()
	if _fire_timer < fire_rate:
		return 2  # RUNNING — esperando para disparar

	_fire_timer = 0.0

	# Verificar distancia y aplicar daño (simplificado — raycast en futuro sprint)
	var distance := actor.global_position.distance_to(player.global_position)
	var hit_chance := 1.0 - (inaccuracy * (distance / 20.0))
	if randf() < hit_chance:
		# Buscar HealthComponent en el jugador
		for child in player.get_children():
			if child.has_method("take_damage"):
				child.take_damage(damage)
				break

	# Emitir disparo para audio y detección
	EventBus.weapon_fired.emit("enemy_weapon", actor.global_position)
	EventBus.noise_emitted.emit(actor.global_position, 1.0)

	return 2  # RUNNING — seguir disparando
