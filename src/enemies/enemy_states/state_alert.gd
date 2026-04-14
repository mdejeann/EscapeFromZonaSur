# state_alert.gd
# Estado de alerta: el enemigo investiga una posición sospechosa.
# Si confirma al jugador, cambia a COMBAT. Si no encuentra nada, vuelve a PATROL.
# Agente responsable: @ai
class_name StateAlert
extends Node


## Tiempo máximo investigando antes de volver a PATROL (segundos).
@export var investigation_timeout: float = 10.0

## Distancia de "llegada" al punto de investigación.
@export var arrival_threshold: float = 2.0

var _timer: float = 0.0
var _investigate_position: Vector3 = Vector3.ZERO
var _arrived: bool = false
var _look_timer: float = 0.0


## Llamado al entrar al estado. investigate_position es el punto a investigar.
func enter(enemy: CharacterBody3D, investigate_position: Vector3 = Vector3.ZERO) -> void:
	_timer = 0.0
	_arrived = false
	_look_timer = 0.0
	_investigate_position = investigate_position
	if _investigate_position != Vector3.ZERO:
		enemy.nav_agent.target_position = _investigate_position


## Llamado cada frame de física mientras el estado esté activo.
## Retorna la transición sugerida: "" = quedarse, "patrol" = volver, "combat" = pelear.
func process(enemy: CharacterBody3D, delta: float) -> String:
	_timer += delta

	# Timeout: no encontramos nada, volver a patrullar
	if _timer >= investigation_timeout:
		return "patrol"

	# Si el sensor detectó al jugador durante la investigación
	if enemy.sensor.suspicion >= 100.0:
		return "combat"

	# Navegar al punto de investigación
	if not _arrived and enemy.nav_agent.is_navigation_finished():
		_arrived = true
		_look_timer = 0.0

	# Una vez en el punto, "mirar alrededor" por unos segundos
	if _arrived:
		_look_timer += delta
		_look_around(enemy, delta)
		if _look_timer >= 4.0:
			return "patrol"

	return ""


## Llamado al salir del estado.
func exit(_enemy: CharacterBody3D) -> void:
	_timer = 0.0
	_arrived = false


func _look_around(enemy: CharacterBody3D, delta: float) -> void:
	# Rotar lentamente para simular búsqueda visual
	enemy.rotate_y(deg_to_rad(45.0) * delta * sign(sin(_look_timer * 2.0)))
