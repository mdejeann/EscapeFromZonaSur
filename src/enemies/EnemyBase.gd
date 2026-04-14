# EnemyBase.gd
# Clase base para todos los enemigos del juego.
# Cada facción extiende esta clase o usa un behavior tree diferente (Beehave).
# Agente responsable: @ai
class_name EnemyBase
extends CharacterBody3D


@export_group("Facción y stats")
@export var faction: String = "generic"
@export var loot_table_id: String = "generic"
@export var move_speed: float = 3.0

@export_group("Navegación")
@export var patrol_radius: float = 10.0

@onready var health: HealthComponent = $HealthComponent
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var sensor: Node = $SensorComponent  # SensorComponent.gd


func _ready() -> void:
	add_to_group("enemies")
	add_to_group("faction_" + faction)
	health.is_player = false  # HealthComponent no emite señales de jugador
	_connect_signals()


func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	_move_along_nav()
	move_and_slide()


## Recibe daño desde proyectiles u otras fuentes.
func take_damage(amount: int) -> void:
	var died := health.take_damage(amount)
	if died:
		_on_died()


func _on_died() -> void:
	EventBus.enemy_died.emit(global_position, faction, loot_table_id)
	# Beehave BTRoot se detiene automáticamente al desactivar el nodo
	set_physics_process(false)
	# Animación de muerte y queue_free diferido
	await get_tree().create_timer(3.0).timeout
	queue_free()


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 9.8 * delta


func _move_along_nav() -> void:
	if nav_agent.is_navigation_finished():
		velocity.x = move_toward(velocity.x, 0.0, move_speed)
		velocity.z = move_toward(velocity.z, 0.0, move_speed)
		return
	var next_pos := nav_agent.get_next_path_position()
	var direction := (next_pos - global_position).normalized()
	velocity.x = direction.x * move_speed
	velocity.z = direction.z * move_speed
	look_at(global_position + Vector3(direction.x, 0.0, direction.z), Vector3.UP)


func _connect_signals() -> void:
	# Escuchar alertas de la misma facción
	EventBus.alert_raised.connect(_on_alert_raised)


func _on_alert_raised(position: Vector3, alert_faction: String) -> void:
	if alert_faction == faction:
		# Ir a investigar la posición de alerta
		nav_agent.target_position = position
