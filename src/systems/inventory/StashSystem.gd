# StashSystem.gd
# Persiste el inventario del stash entre raids usando FileAccess.
# El stash NO se pierde al morir — solo los ítems equipados en el raid se pierden.
# Agente responsable: @gameplay
extends Node


const STASH_PATH := "user://stash.json"

## Peso máximo del stash (mayor que el inventario de raid).
@export var max_weight: float = 100.0

## Lista de entradas: {item_id: String, quantity: int}
var items: Array[Dictionary] = []


func _ready() -> void:
	load_stash()
	EventBus.player_extracted.connect(_on_player_extracted)


# ── API pública ──────────────────────────────────────────────────────────────

## Agrega un ítem al stash. Retorna true si hubo espacio.
func add_item(item_id: String, qty: int = 1) -> bool:
	var item_data: Resource = _load_item_resource(item_id)
	if item_data == null:
		push_warning("StashSystem: ítem '%s' no encontrado." % item_id)
		return false

	if get_current_weight() + (item_data.weight * qty) > max_weight:
		return false

	# Buscar stack existente
	for entry in items:
		if entry["item_id"] == item_id:
			entry["quantity"] += qty
			save_stash()
			return true

	# Nuevo slot
	items.append({"item_id": item_id, "quantity": qty})
	save_stash()
	return true


## Elimina cantidad del ítem del stash. Retorna true si tuvo éxito.
func remove_item(item_id: String, qty: int = 1) -> bool:
	for i in range(items.size()):
		if items[i]["item_id"] == item_id:
			if items[i]["quantity"] < qty:
				return false
			items[i]["quantity"] -= qty
			if items[i]["quantity"] <= 0:
				items.remove_at(i)
			save_stash()
			return true
	return false


## Retorna true si el stash contiene al menos qty del ítem.
func has_item(item_id: String, qty: int = 1) -> bool:
	return get_item_quantity(item_id) >= qty


## Retorna la cantidad del ítem en el stash.
func get_item_quantity(item_id: String) -> int:
	for entry in items:
		if entry["item_id"] == item_id:
			return entry["quantity"]
	return 0


## Retorna el peso total actual del stash.
func get_current_weight() -> float:
	var total := 0.0
	for entry in items:
		var item_data: Resource = _load_item_resource(entry["item_id"])
		if item_data:
			total += item_data.weight * entry["quantity"]
	return total


## Retorna una copia de la lista de ítems del stash.
func get_all_items() -> Array[Dictionary]:
	return items.duplicate()


## Guarda el stash a disco.
func save_stash() -> void:
	var save_data: Array[Dictionary] = []
	for entry in items:
		save_data.append({
			"item_id": entry["item_id"],
			"quantity": entry["quantity"]
		})

	var file := FileAccess.open(STASH_PATH, FileAccess.WRITE)
	if file:
		var json_str := JSON.stringify({"stash": save_data}, "\t")
		file.store_string(json_str)
		file.close()


## Carga el stash desde disco.
func load_stash() -> void:
	items.clear()
	if not FileAccess.file_exists(STASH_PATH):
		return

	var file := FileAccess.open(STASH_PATH, FileAccess.READ)
	if file == null:
		return

	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		push_warning("StashSystem: error al parsear stash.json")
		return

	var data: Dictionary = json.data
	var entries: Array = data.get("stash", [])
	for entry in entries:
		items.append({
			"item_id": entry.get("item_id", ""),
			"quantity": entry.get("quantity", 0)
		})


# ── Privado ──────────────────────────────────────────────────────────────────

func _load_item_resource(item_id: String) -> Resource:
	var path := "res://assets/data/items/" + item_id + ".tres"
	if ResourceLoader.exists(path):
		var res: Resource = ResourceLoader.load(path)
		return res
	return null


func _on_player_extracted(_map_id: String, loot_kept: Array) -> void:
	# Al extraerse, transferir loot del raid al stash
	for entry in loot_kept:
		if entry is Dictionary and entry.has("item") and entry.has("quantity"):
			var item_data: Resource = entry["item"]
			add_item(item_data.id, entry["quantity"])
