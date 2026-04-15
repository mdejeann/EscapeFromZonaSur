## Runtime level controller for the Barrios de Adrogué map.
## Handles player spawn, zone detection, ambient audio switching,
## and extraction zone activation.
extends Node3D

const _BarriosMapData = preload("res://src/world/map_data/BarriosMapData.gd")

@export var player_scene: PackedScene
@export var enemy_scene: PackedScene

var _current_zone: String = ""
var _player: CharacterBody3D


func _ready() -> void:
	_spawn_player()
	_setup_extraction_zones()
	_spawn_enemies()
	_start_ambient_audio()

	EventBus.player_died.connect(_on_player_died)
	EventBus.extraction_completed.connect(_on_extraction_completed)


func _process(_delta: float) -> void:
	if _player:
		_update_current_zone(_player.global_position)


func _spawn_player() -> void:
	if not player_scene:
		push_warning("[BarriosLevel] No player_scene assigned")
		return

	var spawn_points: Array = _BarriosMapData.SPAWN_POINTS
	var spawn_idx := randi() % spawn_points.size()
	_player = player_scene.instantiate()
	_player.global_position = spawn_points[spawn_idx]
	add_child(_player)

	EventBus.hud_message_requested.emit("Entraste a Barrios de Adrogué. Encontrá loot y llegá a las vías para extraer.", 5.0)


func _setup_extraction_zones() -> void:
	var ext_parent := get_node_or_null("ExtractionZones")
	if not ext_parent:
		return

	for child in ext_parent.get_children():
		if child is Area3D:
			child.body_entered.connect(_on_extraction_body_entered.bind(child))
			child.body_exited.connect(_on_extraction_body_exited.bind(child))


func _spawn_enemies() -> void:
	if not enemy_scene:
		return

	for spawn_data in _BarriosMapData.ENEMY_SPAWNS:
		var count := randi_range(spawn_data["count_range"][0], spawn_data["count_range"][1])
		var patrol_pts: Array = spawn_data["patrol_points"]

		for i in range(count):
			var enemy := enemy_scene.instantiate()
			var spawn_pos: Vector3 = patrol_pts[i % patrol_pts.size()]
			spawn_pos.x += randf_range(-10.0, 10.0)
			spawn_pos.z += randf_range(-10.0, 10.0)
			spawn_pos.y = 1.0
			enemy.global_position = spawn_pos
			enemy.set("faction", spawn_data["faction"])
			enemy.set("loot_table_id", "enemy_%s" % spawn_data["faction"])
			add_child(enemy)


func _update_current_zone(pos: Vector3) -> void:
	var new_zone := ""
	for zone_name in _BarriosMapData.ZONES:
		var rect: Array = _BarriosMapData.ZONES[zone_name]["rect"]
		if pos.x >= rect[0] and pos.x <= rect[2] and pos.z >= rect[1] and pos.z <= rect[3]:
			new_zone = zone_name
			break

	if new_zone != _current_zone:
		_current_zone = new_zone
		_on_zone_changed(new_zone)


func _on_zone_changed(zone_name: String) -> void:
	if zone_name.is_empty():
		return

	var audio_data: Dictionary = _BarriosMapData.AUDIO_ZONES.get(zone_name, {})
	if audio_data.is_empty():
		return

	var ambient_path: String = audio_data.get("ambient", "")
	if not ambient_path.is_empty() and ResourceLoader.exists(ambient_path):
		var ambient_stream := load(ambient_path) as AudioStream
		if ambient_stream:
			AudioManager.play_ambient(ambient_stream)


func _on_extraction_body_entered(body: Node3D, zone: Area3D) -> void:
	if body == _player:
		EventBus.extraction_zone_entered.emit(zone.name)


func _on_extraction_body_exited(body: Node3D, zone: Area3D) -> void:
	if body == _player:
		EventBus.extraction_zone_exited.emit(zone.name)


func _on_player_died() -> void:
	GameState.end_raid_death()
	EventBus.hud_message_requested.emit("Moriste en Barrios de Adrogué.", 3.0)


func _on_extraction_completed(zone_name: String) -> void:
	GameState.end_raid_success([])
	EventBus.hud_message_requested.emit("¡Extracción exitosa desde %s!" % zone_name, 5.0)


func _start_ambient_audio() -> void:
	# Start with default suburban desolate ambient
	var default_ambient := "res://assets/audio/ambient/suburban_desolate.ogg"
	if ResourceLoader.exists(default_ambient):
		var stream := load(default_ambient) as AudioStream
		if stream:
			AudioManager.play_ambient(stream)
