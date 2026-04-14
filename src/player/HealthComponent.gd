# HealthComponent.gd
# Componente reutilizable de salud — usado por el jugador Y los enemigos.
# Emite señales a través de EventBus para que UI y sistemas reaccionen.
# Agente responsable: @core
class_name HealthComponent
extends Node


@export var max_health: int = 100
@export var is_player: bool = false  # si true, usa EventBus.health_changed / player_died

var _current_health: int


func _ready() -> void:
	_current_health = max_health


## Aplica daño al personaje. Retorna true si el personaje muere.
func take_damage(amount: int) -> bool:
	_current_health = max(0, _current_health - amount)
	_emit_health_changed()
	if _current_health <= 0:
		_on_died()
		return true
	return false


## Cura al personaje. No supera max_health.
func heal(amount: int) -> void:
	_current_health = min(max_health, _current_health + amount)
	_emit_health_changed()


## Devuelve la salud actual.
func get_health() -> int:
	return _current_health


## Devuelve la salud como porcentaje de 0.0 a 1.0.
func get_health_ratio() -> float:
	return float(_current_health) / float(max_health)


## Devuelve true si el personaje está vivo.
func is_alive() -> bool:
	return _current_health > 0


func _emit_health_changed() -> void:
	if is_player:
		EventBus.health_changed.emit(_current_health, max_health)


func _on_died() -> void:
	if is_player:
		EventBus.player_died.emit()
	# Los enemigos emiten enemy_died desde EnemyBase.gd con datos adicionales
