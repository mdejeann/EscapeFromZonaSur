# InventoryComponent.gd
# Sistema de inventario con peso. Adjuntar al nodo Player.
# Comunica cambios vía EventBus — nunca modifica UI directamente.
# Agente responsable: @gameplay
class_name InventoryComponent
extends Node


@export var max_weight: float = 20.0  # kg

## Lista de entradas: {item: ItemData, quantity: int, durability: float}
var items: Array[Dictionary] = []


func _ready() -> void:
	EventBus.container_opened.connect(_on_container_opened)


# ── API pública ──────────────────────────────────────────────────────────────

## Intenta agregar cantidad `qty` del ítem. Retorna true si tuvo éxito.
func add_item(item_data: ItemData, qty: int = 1) -> bool:
	if get_current_weight() + (item_data.weight * qty) > max_weight:
		EventBus.inventory_full.emit()
		return false

	# Buscar stack existente
	for entry in items:
		if entry["item"].id == item_data.id and entry["quantity"] < item_data.max_stack:
			var can_add := min(qty, item_data.max_stack - entry["quantity"])
			entry["quantity"] += can_add
			_emit_changes(item_data, can_add)
			return can_add == qty  # false si solo se agregó parcialmente

	# Nuevo slot
	items.append({
		"item": item_data,
		"quantity": qty,
		"durability": item_data.max_durability
	})
	_emit_changes(item_data, qty)
	return true


## Elimina `qty` unidades del ítem con el id dado. Retorna true si tuvo éxito.
func remove_item(item_id: String, qty: int = 1) -> bool:
	for i in range(items.size()):
		if items[i]["item"].id == item_id:
			if items[i]["quantity"] < qty:
				return false
			var removed_item: ItemData = items[i]["item"]
			items[i]["quantity"] -= qty
			if items[i]["quantity"] <= 0:
				items.remove_at(i)
			EventBus.item_dropped.emit(removed_item, qty)
			EventBus.weight_changed.emit(get_current_weight(), max_weight)
			return true
	return false


## Retorna true si el inventario contiene al menos `qty` del ítem.
func has_item(item_id: String, qty: int = 1) -> bool:
	return get_item_quantity(item_id) >= qty


## Retorna la cantidad total del ítem en el inventario.
func get_item_quantity(item_id: String) -> int:
	for entry in items:
		if entry["item"].id == item_id:
			return entry["quantity"]
	return 0


## Retorna el peso total actual del inventario.
func get_current_weight() -> float:
	var total := 0.0
	for entry in items:
		total += entry["item"].weight * entry["quantity"]
	return total


## Retorna una copia de la lista de ítems (para UI).
func get_all_items() -> Array[Dictionary]:
	return items.duplicate()


## Vacía el inventario completo (al morir en raid).
func clear() -> void:
	items.clear()
	EventBus.weight_changed.emit(0.0, max_weight)


# ── Privado ──────────────────────────────────────────────────────────────────

func _emit_changes(item_data: ItemData, qty: int) -> void:
	EventBus.item_picked_up.emit(item_data, qty)
	EventBus.weight_changed.emit(get_current_weight(), max_weight)


func _on_container_opened(_container_id: String) -> void:
	# El LootSystem spawnea ítems; el jugador los recoge manualmente.
	# Esta función puede usarse para auto-loot si se implementa esa opción.
	pass
