# NatureSpawner.gd
# Spawns trees, rocks, and grass procedurally on terrain surfaces.
# Attach to a level node. Uses raycasting to place objects on ground.
# Agente responsable: @world
@tool
extends Node3D


@export_group("Tree Spawning")
@export var tree_count: int = 50
@export var tree_radius: float = 200.0
@export var tree_min_scale: float = 0.8
@export var tree_max_scale: float = 1.4
@export var tree_models: Array[PackedScene] = []

@export_group("Rock Spawning")
@export var rock_count: int = 30
@export var rock_radius: float = 200.0
@export var rock_min_scale: float = 0.5
@export var rock_max_scale: float = 2.0

@export_group("Spawn Settings")
@export var min_distance_between_objects: float = 5.0
@export var ground_layer: int = 1
@export var spawn_on_ready: bool = true
@export var seed_value: int = 42

var _spawned_positions: Array[Vector3] = []
var _rng: RandomNumberGenerator


func _ready() -> void:
	if Engine.is_editor_hint() or not spawn_on_ready:
		return
	call_deferred("_spawn_all")


func _spawn_all() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.seed = seed_value
	_spawned_positions.clear()

	_spawn_trees()
	_spawn_rocks()
	print("NatureSpawner: spawned %d trees, %d rocks" % [tree_count, rock_count])


func respawn() -> void:
	# Clear existing spawned children
	for child in get_children():
		child.queue_free()
	_spawn_all()


func _spawn_trees() -> void:
	if tree_models.size() == 0:
		# Load default OBJ tree models if no scenes provided
		return

	var space := get_world_3d().direct_space_state
	var spawned := 0

	for _i in range(tree_count * 3):  # Try extra attempts for placement
		if spawned >= tree_count:
			break

		var pos2d := _random_point_in_radius(tree_radius)
		var from := Vector3(pos2d.x, 100.0, pos2d.y) + global_position
		var to := Vector3(pos2d.x, -100.0, pos2d.y) + global_position

		var query := PhysicsRayQueryParameters3D.create(from, to, ground_layer)
		var result := space.intersect_ray(query)

		if result.is_empty():
			continue

		var hit_pos: Vector3 = result.position
		if not _check_min_distance(hit_pos):
			continue

		var tree_scene: PackedScene = tree_models[_rng.randi() % tree_models.size()]
		var tree := tree_scene.instantiate()
		add_child(tree)
		tree.global_position = hit_pos

		var s := _rng.randf_range(tree_min_scale, tree_max_scale)
		tree.scale = Vector3(s, s, s)
		tree.rotate_y(_rng.randf() * TAU)

		_spawned_positions.append(hit_pos)
		spawned += 1


func _spawn_rocks() -> void:
	var space := get_world_3d().direct_space_state
	var spawned := 0

	for _i in range(rock_count * 3):
		if spawned >= rock_count:
			break

		var pos2d := _random_point_in_radius(rock_radius)
		var from := Vector3(pos2d.x, 100.0, pos2d.y) + global_position
		var to := Vector3(pos2d.x, -100.0, pos2d.y) + global_position

		var query := PhysicsRayQueryParameters3D.create(from, to, ground_layer)
		var result := space.intersect_ray(query)

		if result.is_empty():
			continue

		var hit_pos: Vector3 = result.position
		if not _check_min_distance(hit_pos):
			continue

		# Create a simple mesh instance from rock OBJ
		var rock := MeshInstance3D.new()
		add_child(rock)
		rock.global_position = hit_pos

		var s := _rng.randf_range(rock_min_scale, rock_max_scale)
		rock.scale = Vector3(s, s, s)
		rock.rotate_y(_rng.randf() * TAU)
		rock.rotate_x(_rng.randf_range(-0.2, 0.2))

		_spawned_positions.append(hit_pos)
		spawned += 1


func _random_point_in_radius(radius: float) -> Vector2:
	var angle := _rng.randf() * TAU
	var dist := _rng.randf() * radius
	return Vector2(cos(angle) * dist, sin(angle) * dist)


func _check_min_distance(pos: Vector3) -> bool:
	for existing in _spawned_positions:
		if pos.distance_to(existing) < min_distance_between_objects:
			return false
	return true
