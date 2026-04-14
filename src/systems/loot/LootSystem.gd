# LootSystem.gd
# Autoload — lee loot_tables.json y provee rolls de loot para contenedores y enemigos.
# Agente responsable: @gameplay
extends Node


## Ruta al archivo JSON de tablas de loot. Configurable desde Project Settings.
@export var loot_tables_path: String = "res://assets/data/loot_tables.json"

## Ruta base donde se buscan los recursos ItemData (.tres).
@export var items_base_path: String = "res://assets/data/items/"

var _tables: Dictionary = {}
var _item_cache: Dictionary = {}  # id -> ItemData


func _ready() -> void:
	_load_tables()
	EventBus.enemy_died.connect(_on_enemy_died)
	EventBus.container_opened.connect(_on_container_opened)


## Realiza un roll de loot para la tabla dada.
## Retorna un array de {item: ItemData, quantity: int}.
func roll_table(table_id: String) -> Array[Dictionary]:
	if not _tables.has(table_id):
		push_warning("LootSystem: tabla '%s' no encontrada." % table_id)
		return []

	var table: Dictionary = _tables[table_id]
	var rolls: int = table.get("rolls", 1)
	var entries: Array = table.get("entries", [])
	var result: Array[Dictionary] = []

	for _i in range(rolls):
		var entry := _weighted_random(entries)
		if entry.is_empty():
			continue
		var item := _get_item(entry["id"])
		if item:
			var qty := randi_range(entry.get("min", 1), entry.get("max", 1))
			result.append({"item": item, "quantity": qty})

	return result


# ── Privado ──────────────────────────────────────────────────────────────────

func _load_tables() -> void:
	if not FileAccess.file_exists(loot_tables_path):
		push_warning("LootSystem: no se encontró loot_tables.json en '%s'" % loot_tables_path)
		return
	var file := FileAccess.open(loot_tables_path, FileAccess.READ)
	var json := JSON.new()
	if json.parse(file.get_as_text()) == OK:
		_tables = json.data.get("loot_tables", {})


func _get_item(item_id: String) -> ItemData:
	if _item_cache.has(item_id):
		return _item_cache[item_id]
	var path := items_base_path + item_id + ".tres"
	if ResourceLoader.exists(path):
		var item := ResourceLoader.load(path) as ItemData
		_item_cache[item_id] = item
		return item
	push_warning("LootSystem: ítem '%s' no encontrado en '%s'" % [item_id, path])
	return null


## Selección aleatoria ponderada por el campo "weight" de cada entrada.
func _weighted_random(entries: Array) -> Dictionary:
	var total_weight := 0.0
	for e in entries:
		total_weight += e.get("weight", 1.0)

	var roll := randf() * total_weight
	var accumulated := 0.0
	for e in entries:
		accumulated += e.get("weight", 1.0)
		if roll <= accumulated:
			return e
	return {}


func _on_enemy_died(position: Vector3, _faction: String, loot_table_id: String) -> void:
	# Sprint 2: instanciar ítems en el mundo en `position`
	var drops := roll_table(loot_table_id)
	# TODO: spawnear WorldItem.tscn por cada drop cerca de `position`
	pass


func _on_container_opened(container_id: String) -> void:
	# Los contenedores tienen su propio loot_table_id almacenado en la escena.
	# LootContainer.gd llama interact() que emite container_opened.
	# En Sprint 2: buscar el nodo del contenedor y spawnear ítems.
	pass
