# CanSeePlayer.gd
# Beehave ConditionLeaf — verifica si el enemigo puede ver al jugador.
# Lee el nivel de sospecha del SensorComponent.
# Agente responsable: @ai
class_name CanSeePlayer
extends Node


## Umbral de sospecha para considerar que "ve" al jugador (0-100).
@export var suspicion_threshold: float = 80.0


## Llamado por el behavior tree cada tick. Retorna SUCCESS o FAILURE.
func tick(actor: Node, _blackboard: Dictionary) -> int:
	var sensor: Node = actor.get_node("SensorComponent")
	if sensor == null:
		return 0  # FAILURE

	if sensor.suspicion >= suspicion_threshold:
		# Almacenar posición del jugador en el blackboard para las acciones
		var player := actor.get_tree().get_first_node_in_group("player")
		if player:
			_blackboard["target_position"] = player.global_position
		return 1  # SUCCESS — ve al jugador

	return 0  # FAILURE — no lo ve
