# StashSystem.gd
# Persiste el stash del jugador entre raids usando FileAccess.
# El stash nunca se pierde al morir — solo los ítems que el jugador lleva al raid.
# Serializa por {id, quantity}; la durabilidad se resetea al sacar del stash.
# Agente responsable: @gameplay
class_name StashSystem
extends Node


const STASH_PATH: String = "user://stash.json"

## Contenido del stash: Array de {id: String, quantity: int}
var _stash: Array[Dictionary] = []


func _ready() -> void:
	_load()
	EventBus.player_extracted.connect(_on_player_extracted)


# ── API pública ───────────────────────────────────────────────────────────────

## Agrega ítems al stash. Si el ítem ya existe, incrementa la cantidad.
func add_to_stash(item_id: String, quantity: int) -> void:
	for entry in _stash:
		if entry["id"] == item_id:
			entry["quantity"] += quantity
			_save()
			EventBus.stash_updated.emit()
			return
	_stash.append({"id": item_id, "quantity": quantity})
	_save()
	EventBus.stash_updated.emit()


## Retira ítems del stash. Retorna true si había suficiente cantidad.
func remove_from_stash(item_id: String, quantity: int) -> bool:
	for i in range(_stash.size()):
		if _stash[i]["id"] == item_id:
			if _stash[i]["quantity"] < quantity:
				return false
			_stash[i]["quantity"] -= quantity
			if _stash[i]["quantity"] <= 0:
				_stash.remove_at(i)
			_save()
			EventBus.stash_updated.emit()
			return true
	return false


## Retorna la cantidad de un ítem en el stash.
func get_stash_quantity(item_id: String) -> int:
	for entry in _stash:
		if entry["id"] == item_id:
			return entry["quantity"]
	return 0


## Retorna todos los ítems del stash como copia.
func get_all_stash_items() -> Array[Dictionary]:
	return _stash.duplicate(true)


## Vacía el stash completamente (solo para debug/reset).
func clear_stash() -> void:
	_stash.clear()
	_save()
	EventBus.stash_updated.emit()


# ── Privado ───────────────────────────────────────────────────────────────────

func _save() -> void:
	var file := FileAccess.open(STASH_PATH, FileAccess.WRITE)
	if not file:
		push_warning("StashSystem: no se pudo escribir en '%s'" % STASH_PATH)
		return
	file.store_string(JSON.stringify({"stash": _stash}))


func _load() -> void:
	if not FileAccess.file_exists(STASH_PATH):
		return
	var file := FileAccess.open(STASH_PATH, FileAccess.READ)
	if not file:
		push_warning("StashSystem: no se pudo leer '%s'" % STASH_PATH)
		return
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		push_warning("StashSystem: error al parsear stash.json")
		return
	var data: Array = json.data.get("stash", [])
	_stash.clear()
	for entry in data:
		if entry.has("id") and entry.has("quantity"):
			_stash.append({"id": str(entry["id"]), "quantity": int(entry["quantity"])})


## Al extraer con éxito, mueve todos los ítems del inventario al stash.
func _on_player_extracted(_map_id: String, loot_kept: Array) -> void:
	for entry in loot_kept:
		if entry.has("item") and entry.has("quantity"):
			add_to_stash(entry["item"].id, entry["quantity"])
