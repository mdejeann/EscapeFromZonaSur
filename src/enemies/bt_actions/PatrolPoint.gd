# PatrolPoint.gd
# Beehave ActionLeaf — mueve al enemigo al siguiente punto de patrulla.
# Requiere blackboard key "patrol_points" (Array[Vector3]) y "patrol_index" (int).
# Agente responsable: @ai
class_name PatrolPoint
extends Node


## Distancia mínima para considerar que llegó al punto de patrulla.
@export var arrival_distance: float = 1.5

## Tiempo de espera en cada punto de patrulla (segundos).
@export var wait_time: float = 2.0

var _wait_timer: float = 0.0
var _waiting: bool = false


## Llamado por el behavior tree cada tick. Retorna SUCCESS, RUNNING o FAILURE.
func tick(actor: Node, blackboard: Dictionary) -> int:
	var nav_agent: NavigationAgent3D = actor.get_node("NavigationAgent3D")
	var patrol_points: Array = blackboard.get("patrol_points", [])

	if patrol_points.is_empty():
		return 0  # FAILURE

	var patrol_index: int = blackboard.get("patrol_index", 0)
	var target: Vector3 = patrol_points[patrol_index]

	# Si estamos esperando en el punto
	if _waiting:
		_wait_timer += get_process_delta_time()
		if _wait_timer >= wait_time:
			_waiting = false
			_wait_timer = 0.0
			# Avanzar al siguiente punto
			blackboard["patrol_index"] = (patrol_index + 1) % patrol_points.size()
			return 1  # SUCCESS
		return 2  # RUNNING

	# Mover al punto de patrulla
	nav_agent.target_position = target
	var distance := actor.global_position.distance_to(target)

	if distance <= arrival_distance:
		_waiting = true
		return 2  # RUNNING

	return 2  # RUNNING — todavía en camino
