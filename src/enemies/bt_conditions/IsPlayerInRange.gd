# IsPlayerInRange.gd
# Beehave ConditionLeaf — verifica si el jugador está dentro de un rango configurable.
# Usado para decidir ataques cuerpo a cuerpo, territorios de facciones, etc.
# Agente responsable: @ai
class_name IsPlayerInRange
extends Node


## Distancia máxima para considerar al jugador "en rango".
@export var detection_range: float = 20.0


## Llamado por el behavior tree cada tick.
func tick(actor: Node, _blackboard: Dictionary) -> int:
	var player := actor.get_tree().get_first_node_in_group("player")
	if player == null:
		return 0  # FAILURE

	var distance := actor.global_position.distance_to(player.global_position)
	if distance <= detection_range:
		_blackboard["target_position"] = player.global_position
		_blackboard["target_distance"] = distance
		return 1  # SUCCESS — jugador en rango

	return 0  # FAILURE — fuera de rango
