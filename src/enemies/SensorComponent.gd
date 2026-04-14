# SensorComponent.gd
# Detección de jugador por visión (cono) y sonido (radio).
# Se adjunta como hijo de EnemyBase.
# Agente responsable: @ai
class_name SensorComponent
extends Node3D


@export_group("Visión")
@export var vision_range: float = 15.0     # metros
@export var vision_angle: float = 90.0     # grados, campo de visión total
@export var suspicion_rate: float = 20.0   # unidades/seg al ver al jugador
@export var suspicion_decay: float = 10.0  # unidades/seg sin ver al jugador
## Máscara de colisión para el raycast de line-of-sight (layer 1 = mundo estático por defecto).
@export_flags_3d_physics var los_collision_mask: int = 1

@export_group("Sonido")
@export var hearing_range: float = 25.0    # metros para escuchar noise_emitted

## Nivel de sospecha: 0.0 = tranquilo, 100.0 = en combate
var suspicion: float = 0.0

var _player: Node3D = null


func _ready() -> void:
	EventBus.noise_emitted.connect(_on_noise_emitted)


func _physics_process(delta: float) -> void:
	if _player == null:
		_player = get_tree().get_first_node_in_group("player")

	if _player == null:
		return

	_update_vision(delta)


func _update_vision(delta: float) -> void:
	var to_player := _player.global_position - global_position
	var distance := to_player.length()

	if distance > vision_range:
		_decay_suspicion(delta)
		return

	# Verificar ángulo de visión
	var forward := -global_transform.basis.z
	var angle := rad_to_deg(forward.angle_to(to_player.normalized()))
	if angle > vision_angle / 2.0:
		_decay_suspicion(delta)
		return

	# Line-of-sight raycast — layer 1 = mundo estático (ajustar según el proyecto)
	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(
		global_position + Vector3.UP * 1.5,
		_player.global_position + Vector3.UP * 1.0,
		los_collision_mask,
		[get_parent()]
	)
	var result := space.intersect_ray(query)

	if result and result.get("collider") == _player:
		var rate := lerpf(suspicion_rate, suspicion_rate * 0.3, distance / vision_range)
		_increase_suspicion(delta * rate)
	else:
		_decay_suspicion(delta)


func _increase_suspicion(amount: float) -> void:
	suspicion = min(100.0, suspicion + amount)
	if suspicion >= 100.0:
		EventBus.enemy_spotted_player.emit(get_parent().global_position, get_parent().faction)
		EventBus.alert_raised.emit(get_parent().global_position, get_parent().faction)


func _decay_suspicion(delta: float) -> void:
	suspicion = max(0.0, suspicion - suspicion_decay * delta)


func _on_noise_emitted(origin: Vector3, loudness: float) -> void:
	var effective_range := hearing_range * loudness
	if global_position.distance_to(origin) <= effective_range:
		EventBus.enemy_heard_noise.emit(origin, global_position)
		# Subir sospecha parcialmente por sonido
		_increase_suspicion(40.0)
