# InventoryUI.gd
# Pantalla de inventario con grid drag-and-drop.
# Refleja los slots de InventoryComponent. Abre/cierra con Tab.
# Agente responsable: @ui
class_name InventoryUI
extends Control


@onready var grid_container: GridContainer = $PanelContainer/MarginContainer/VBoxContainer/ScrollContainer/GridContainer
@onready var weight_label: Label = $PanelContainer/MarginContainer/VBoxContainer/WeightPanel/WeightLabel
@onready var weight_bar: ProgressBar = $PanelContainer/MarginContainer/VBoxContainer/WeightPanel/WeightBar

## Referencia al InventoryComponent del jugador (configurar en la escena).
var inventory: InventoryComponent = null

var _is_open: bool = false


func _ready() -> void:
	EventBus.inventory_toggle_requested.connect(_toggle)
	EventBus.item_picked_up.connect(_on_inventory_changed)
	EventBus.item_dropped.connect(_on_inventory_changed)
	EventBus.weight_changed.connect(_on_weight_changed)
	visible = false


func _toggle() -> void:
	_is_open = not _is_open
	visible = _is_open

	if _is_open:
		_refresh_grid()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _refresh_grid() -> void:
	# Limpiar grid actual
	for child in grid_container.get_children():
		child.queue_free()

	if inventory == null:
		_find_inventory()

	if inventory == null:
		return

	# Crear un slot por cada entrada del inventario
	for entry in inventory.get_all_items():
		var slot := _create_slot(entry)
		grid_container.add_child(slot)


func _create_slot(entry: Dictionary) -> PanelContainer:
	var slot := PanelContainer.new()
	slot.custom_minimum_size = Vector2(64, 64)

	var vbox := VBoxContainer.new()
	slot.add_child(vbox)

	# Ícono del ítem
	var icon_rect := TextureRect.new()
	icon_rect.custom_minimum_size = Vector2(48, 48)
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var item_data: ItemData = entry["item"]
	if item_data.icon:
		icon_rect.texture = item_data.icon
	vbox.add_child(icon_rect)

	# Cantidad
	var qty_label := Label.new()
	qty_label.text = "x%d" % entry["quantity"]
	qty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(qty_label)

	# Tooltip con nombre y peso
	slot.tooltip_text = "%s\nPeso: %.1f kg" % [item_data.display_name, item_data.weight * entry["quantity"]]

	return slot


func _find_inventory() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player:
		for child in player.get_children():
			if child is InventoryComponent:
				inventory = child
				break


func _on_inventory_changed(_item_data: Resource, _quantity: int) -> void:
	if _is_open:
		_refresh_grid()


func _on_weight_changed(current: float, maximum: float) -> void:
	weight_label.text = "Peso: %.1f / %.1f kg" % [current, maximum]
	weight_bar.max_value = maximum
	weight_bar.value = current
