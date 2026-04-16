# EnemySpawner.gd
# Spawner dinámico de enemigos según zona y dificultad.
# Se coloca en el mapa como un Marker3D con parámetros configurables.
# Agente responsable: @ai
class_name EnemySpawner
extends Marker3D


## Escena del enemigo a instanciar.
@export var enemy_scene: PackedScene

## Facción de los enemigos spawneados.
@export var faction: String = "generic"

## Número máximo de enemigos activos de este spawner.
@export var max_enemies: int = 3

## Radio del área de spawn alrededor del spawner.
@export var spawn_radius: float = 8.0

## Tiempo entre intentos de spawn (segundos).
@export var spawn_interval: float = 30.0

## Distancia mínima al jugador para spawnear (no spawnear enfrente del jugador).
@export var min_player_distance: float = 40.0

## Puntos de patrulla que se asignarán a los enemigos spawneados.
@export var patrol_points: Array[Vector3] = []

## Referencia opcional a una escuadra para registrar enemigos spawneados.
@export var squad: EnemySquad = null

var _active_enemies: Array[Node3D] = []
var _spawn_timer: float = 0.0
var _initial_spawn_done: bool = false


func _ready() -> void:
	# Spawn inicial tras un breve delay para que la navegación esté lista
	await get_tree().create_timer(1.0).timeout
	_initial_spawn()


func _physics_process(delta: float) -> void:
	_cleanup_dead()

	if _active_enemies.size() >= max_enemies:
		return

	_spawn_timer += delta
	if _spawn_timer >= spawn_interval:
		_spawn_timer = 0.0
		_try_spawn()


## Spawn inicial de enemigos al inicio del raid.
func _initial_spawn() -> void:
	_initial_spawn_done = true
	for _i in range(max_enemies):
		_try_spawn()


## Intenta spawnear un enemigo si las condiciones lo permiten.
func _try_spawn() -> void:
	if enemy_scene == null:
		return

	if _active_enemies.size() >= max_enemies:
		return

	# Verificar distancia al jugador
	var player := get_tree().get_first_node_in_group("player")
	if player and global_position.distance_to(player.global_position) < min_player_distance:
		return

	var spawn_pos := _get_spawn_position()
	var enemy := enemy_scene.instantiate() as CharacterBody3D

	if enemy == null:
		return

	enemy.global_position = spawn_pos

	# Configurar facción y puntos de patrulla si el enemigo los soporta
	if "faction" in enemy:
		enemy.faction = faction
	if "patrol_points" in enemy:
		enemy.patrol_points = patrol_points.duplicate()

	# Agregar al árbol de escena
	get_tree().current_scene.add_child(enemy)
	_active_enemies.append(enemy)

	# Registrar en escuadra si hay una disponible
	if squad and squad.has_method("register_member"):
		squad.register_member(enemy)


## Genera una posición de spawn dentro del radio configurado.
func _get_spawn_position() -> Vector3:
	var angle := randf() * TAU
	var dist := randf() * spawn_radius
	return global_position + Vector3(cos(angle) * dist, 0.0, sin(angle) * dist)


## Limpia referencias a enemigos que ya no existen.
func _cleanup_dead() -> void:
	_active_enemies = _active_enemies.filter(
		func(e: Node3D) -> bool: return is_instance_valid(e) and e.is_inside_tree()
	)
