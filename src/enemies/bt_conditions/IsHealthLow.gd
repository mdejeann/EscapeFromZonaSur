# IsHealthLow.gd
# Beehave ConditionLeaf — verifica si la salud del enemigo está baja.
# Usado por facciones como "Sobreviviente" para decidir huir.
# Agente responsable: @ai
class_name IsHealthLow
extends Node


## Porcentaje de salud por debajo del cual se considera "baja" (0.0-1.0).
@export_range(0.0, 1.0) var health_threshold: float = 0.3


## Llamado por el behavior tree cada tick.
func tick(actor: Node, _blackboard: Dictionary) -> int:
	var health_component: Node = actor.get_node("HealthComponent")
	if health_component == null:
		return 0  # FAILURE

	if health_component.get_health_ratio() <= health_threshold:
		return 1  # SUCCESS — salud baja

	return 0  # FAILURE — salud suficiente
