# CraftingSystem.gd
# Autoload — lee crafting_recipes.json y permite craftear ítems consumiendo ingredientes
# del inventario del jugador.
# Agente responsable: @gameplay
extends Node


@export var recipes_path: String = "res://assets/data/crafting_recipes.json"
@export var items_base_path: String = "res://assets/data/items/"

## Array de recetas cargadas: [{id, result_id, result_quantity, ingredients: [{id, quantity}]}]
var _recipes: Array[Dictionary] = []
var _item_cache: Dictionary = {}  # id -> ItemData


func _ready() -> void:
	_load_recipes()


# ── API pública ───────────────────────────────────────────────────────────────

## Intenta craftear la receta indicada usando el inventario dado.
## Retorna true si el crafteo fue exitoso.
func craft(recipe_id: String, inventory: InventoryComponent) -> bool:
	var recipe := _get_recipe(recipe_id)
	if recipe.is_empty():
		push_warning("CraftingSystem: receta '%s' no encontrada." % recipe_id)
		return false

	if not can_craft(recipe_id, inventory):
		EventBus.hud_message_requested.emit("No tenés los materiales necesarios", 2.0)
		return false

	# Consumir ingredientes
	for ingredient in recipe["ingredients"]:
		inventory.remove_item(ingredient["id"], ingredient["quantity"])

	# Entregar resultado
	var result := _get_item(recipe["result_id"])
	if not result:
		push_warning("CraftingSystem: ítem resultado '%s' no encontrado." % recipe["result_id"])
		return false

	var qty: int = recipe.get("result_quantity", 1)
	if not inventory.add_item(result, qty):
		# Inventario lleno — intentar devolver ingredientes
		for ingredient in recipe["ingredients"]:
			var ing_item := _get_item(ingredient["id"])
			if ing_item:
				if not inventory.add_item(ing_item, ingredient["quantity"]):
					push_warning("CraftingSystem: no se pudo devolver '%s' x%d — inventario lleno." % [ingredient["id"], ingredient["quantity"]])
		return false

	EventBus.item_crafted.emit(result, qty)
	return true


## Retorna true si el jugador tiene todos los materiales para la receta.
func can_craft(recipe_id: String, inventory: InventoryComponent) -> bool:
	var recipe := _get_recipe(recipe_id)
	if recipe.is_empty():
		return false
	for ingredient in recipe["ingredients"]:
		if not inventory.has_item(ingredient["id"], ingredient["quantity"]):
			return false
	return true


## Retorna todas las recetas disponibles.
func get_all_recipes() -> Array[Dictionary]:
	return _recipes.duplicate(true)


## Retorna las recetas que el jugador puede craftear con su inventario actual.
func get_available_recipes(inventory: InventoryComponent) -> Array[Dictionary]:
	var available: Array[Dictionary] = []
	for recipe in _recipes:
		if can_craft(recipe["id"], inventory):
			available.append(recipe)
	return available


# ── Privado ───────────────────────────────────────────────────────────────────

func _load_recipes() -> void:
	if not FileAccess.file_exists(recipes_path):
		push_warning("CraftingSystem: no se encontró crafting_recipes.json en '%s'" % recipes_path)
		return
	var file := FileAccess.open(recipes_path, FileAccess.READ)
	var json := JSON.new()
	if json.parse(file.get_as_text()) == OK:
		var raw: Array = json.data.get("recipes", [])
		for r in raw:
			_recipes.append(r)
	else:
		push_warning("CraftingSystem: error al parsear crafting_recipes.json")


func _get_recipe(recipe_id: String) -> Dictionary:
	for recipe in _recipes:
		if recipe["id"] == recipe_id:
			return recipe
	return {}


func _get_item(item_id: String) -> ItemData:
	if _item_cache.has(item_id):
		return _item_cache[item_id]
	var path := items_base_path + item_id + ".tres"
	if ResourceLoader.exists(path):
		var item := ResourceLoader.load(path) as ItemData
		_item_cache[item_id] = item
		return item
	push_warning("CraftingSystem: ítem '%s' no encontrado en '%s'" % [item_id, path])
	return null
