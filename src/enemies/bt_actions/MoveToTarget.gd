# MoveToTarget.gd
# Beehave ActionLeaf — mueve al enemigo hacia la posición objetivo almacenada en el blackboard.
# Requiere blackboard key "target_position" (Vector3).
# Agente responsable: @ai
class_name MoveToTarget
extends Node


## Distancia mínima para considerar que llegó al objetivo.
@export var arrival_distance: float = 2.0


## Llamado por el behavior tree cada tick.
func tick(actor: Node, blackboard: Dictionary) -> int:
	var target_pos: Vector3 = blackboard.get("target_position", Vector3.ZERO)
	if target_pos == Vector3.ZERO:
		return 0  # FAILURE — no hay objetivo

	var nav_agent: NavigationAgent3D = actor.get_node("NavigationAgent3D")
	nav_agent.target_position = target_pos

	var distance := actor.global_position.distance_to(target_pos)
	if distance <= arrival_distance:
		return 1  # SUCCESS — llegó al objetivo

	return 2  # RUNNING — en camino
