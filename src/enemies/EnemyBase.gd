# EnemyBase.gd
# Clase base para todos los enemigos del juego.
# Implementa una FSM con estados: PATROL, ALERT, COMBAT, FLEE, DEAD.
# Cada facción configura parámetros exportados y comportamiento de los estados.
# Agente responsable: @ai
class_name EnemyBase
extends CharacterBody3D


## Estados posibles del enemigo.
enum State { PATROL, ALERT, COMBAT, FLEE, DEAD }

@export_group("Facción y stats")
@export var faction: String = "generic"
@export var loot_table_id: String = "generic"
@export var move_speed: float = 3.0

@export_group("Navegación")
@export var patrol_radius: float = 10.0

## Puntos de patrulla asignados (se pueden configurar desde el editor o el spawner).
@export var patrol_points: Array[Vector3] = []

@onready var health: HealthComponent = $HealthComponent
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var sensor: SensorComponent = $SensorComponent

## Estado actual del FSM.
var current_state: State = State.PATROL

## Índice del punto de patrulla actual.
var current_patrol_index: int = 0

## Objetivo actual (generalmente el jugador).
var _target: Node3D = null

## Instancias de los estados del FSM.
var _state_patrol: StatePatrol = null
var _state_alert: StateAlert = null
var _state_combat: StateCombat = null
var _state_flee: StateFlee = null


func _ready() -> void:
	add_to_group("enemies")
	add_to_group("faction_" + faction)
	health.is_player = false

	# Inicializar estados del FSM
	_state_patrol = StatePatrol.new()
	_state_alert = StateAlert.new()
	_state_combat = StateCombat.new()
	_state_flee = StateFlee.new()
	_state_patrol.wander_radius = patrol_radius
	add_child(_state_patrol)
	add_child(_state_alert)
	add_child(_state_combat)
	add_child(_state_flee)

	_connect_signals()
	_state_patrol.enter(self)


func _physics_process(delta: float) -> void:
	if current_state == State.DEAD:
		return

	_apply_gravity(delta)

	match current_state:
		State.PATROL:
			_process_patrol(delta)
		State.ALERT:
			_process_alert(delta)
		State.COMBAT:
			_process_combat(delta)
		State.FLEE:
			_process_flee(delta)

	_move_along_nav()
	move_and_slide()


## Recibe daño desde proyectiles u otras fuentes.
func take_damage(amount: int) -> void:
	if current_state == State.DEAD:
		return
	var died := health.take_damage(amount)
	if died:
		_on_died()
	elif current_state == State.PATROL:
		# Si nos dañan en patrulla, pasar a alerta hacia el origen del daño
		var player := get_tree().get_first_node_in_group("player")
		if player:
			_change_state(State.ALERT, player.global_position)


## Devuelve la facción de este enemigo.
func get_faction() -> String:
	return faction


## Llamado por EnemySquad cuando la escuadra da la alerta.
func on_squad_alert(alert_position: Vector3) -> void:
	if current_state == State.PATROL:
		_change_state(State.ALERT, alert_position)


## Llamado por EnemySquad cuando la escuadra se rompe (pocos miembros).
func on_squad_broken() -> void:
	if current_state == State.COMBAT:
		_change_state(State.FLEE)


func _on_died() -> void:
	_change_state(State.DEAD)
	EventBus.enemy_died.emit(global_position, faction, loot_table_id)
	set_physics_process(false)
	# Desactivar colisión
	if has_node("CollisionShape3D"):
		$CollisionShape3D.set_deferred("disabled", true)
	# Diferir queue_free para dar tiempo a animación de muerte
	await get_tree().create_timer(3.0).timeout
	queue_free()


func _change_state(new_state: State, context: Variant = null) -> void:
	# Salir del estado actual
	match current_state:
		State.PATROL:
			_state_patrol.exit(self)
		State.ALERT:
			_state_alert.exit(self)
		State.COMBAT:
			_state_combat.exit(self)
		State.FLEE:
			_state_flee.exit(self)

	current_state = new_state

	# Entrar al nuevo estado
	match new_state:
		State.PATROL:
			_state_patrol.enter(self)
		State.ALERT:
			var pos: Vector3 = context if context is Vector3 else Vector3.ZERO
			_state_alert.enter(self, pos)
		State.COMBAT:
			var target_node: Node3D = context if context is Node3D else null
			_state_combat.enter(self, target_node)
			EventBus.enemy_spotted_player.emit(global_position, faction)
		State.FLEE:
			var threat_pos: Vector3 = context if context is Vector3 else Vector3.ZERO
			_state_flee.enter(self, threat_pos)


func _process_patrol(delta: float) -> void:
	_state_patrol.process(self, delta)

	# Verificar si el sensor ha alcanzado suspición máxima
	if sensor.suspicion >= 100.0:
		var player := get_tree().get_first_node_in_group("player")
		if player:
			_target = player
			_change_state(State.COMBAT, _target)


func _process_alert(delta: float) -> void:
	var transition := _state_alert.process(self, delta)
	match transition:
		"patrol":
			_change_state(State.PATROL)
		"combat":
			var player := get_tree().get_first_node_in_group("player")
			if player:
				_target = player
				_change_state(State.COMBAT, _target)


func _process_combat(delta: float) -> void:
	var transition := _state_combat.process(self, delta)
	match transition:
		"patrol":
			_change_state(State.PATROL)
		"flee":
			var threat_pos := _target.global_position if is_instance_valid(_target) else Vector3.ZERO
			_change_state(State.FLEE, threat_pos)


func _process_flee(delta: float) -> void:
	var transition := _state_flee.process(self, delta)
	match transition:
		"patrol":
			_change_state(State.PATROL)


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
	# Evitar look_at si dirección es cero
	if direction.length_squared() > 0.001:
		var look_target := global_position + Vector3(direction.x, 0.0, direction.z)
		if look_target.distance_squared_to(global_position) > 0.001:
			look_at(look_target, Vector3.UP)


func _connect_signals() -> void:
	EventBus.alert_raised.connect(_on_alert_raised)
	EventBus.enemy_heard_noise.connect(_on_enemy_heard_noise)


func _on_alert_raised(position: Vector3, alert_faction: String) -> void:
	if alert_faction != faction:
		return
	if current_state == State.PATROL:
		_change_state(State.ALERT, position)


func _on_enemy_heard_noise(origin: Vector3, _enemy_position: Vector3) -> void:
	# Si escuchamos un ruido y estamos patrullando, investigar
	if current_state == State.PATROL:
		if global_position.distance_to(origin) <= sensor.hearing_range:
			_change_state(State.ALERT, origin)
