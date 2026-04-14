# EnemySpawner.gd
# Spawner dinámico de enemigos por zona. Respeta límites por facción y radio.
# Agente responsable: @ai
class_name EnemySpawner
extends Node3D


## Escena del enemigo a instanciar.
@export var enemy_scene: PackedScene

## Facción de los enemigos spawneados por este spawner.
@export var faction: String = "generic"

## Cantidad máxima de enemigos activos de este spawner.
@export var max_enemies: int = 4

## Radio de spawn alrededor de este nodo.
@export var spawn_radius: float = 15.0

## Tiempo entre spawns (segundos).
@export var spawn_interval: float = 30.0

## Si es true, solo spawnea si no hay jugador cerca.
@export var avoid_player_spawn: bool = true

## Distancia mínima al jugador para poder spawnear.
@export var min_player_distance: float = 30.0

var _spawn_timer: float = 0.0
var _spawned_enemies: Array[Node] = []


func _ready() -> void:
	_initial_spawn()


func _process(delta: float) -> void:
	# Limpiar referencias a enemigos que ya no existen
	_spawned_enemies = _spawned_enemies.filter(func(e: Node) -> bool: return is_instance_valid(e))

	if _spawned_enemies.size() >= max_enemies:
		return

	_spawn_timer += delta
	if _spawn_timer >= spawn_interval:
		_spawn_timer = 0.0
		_try_spawn()


func _initial_spawn() -> void:
	if enemy_scene == null:
		return
	# Spawnear la mitad al inicio
	var initial_count := max(1, max_enemies / 2)
	for _i in range(initial_count):
		_spawn_enemy()


func _try_spawn() -> void:
	if avoid_player_spawn:
		var player := get_tree().get_first_node_in_group("player")
		if player and global_position.distance_to(player.global_position) < min_player_distance:
			return
	_spawn_enemy()


func _spawn_enemy() -> void:
	if enemy_scene == null:
		return
	if _spawned_enemies.size() >= max_enemies:
		return

	var enemy: Node3D = enemy_scene.instantiate()
	var offset := Vector3(
		randf_range(-spawn_radius, spawn_radius),
		0.0,
		randf_range(-spawn_radius, spawn_radius)
	)
	enemy.global_position = global_position + offset

	# Configurar facción si el enemigo tiene el campo
	if enemy.has_method("set") and "faction" in enemy:
		enemy.faction = faction

	get_tree().current_scene.add_child(enemy)
	_spawned_enemies.append(enemy)
