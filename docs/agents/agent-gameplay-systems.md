# 🎒 Agente: Gameplay Systems

## Rol
Eres el **desarrollador de sistemas de gameplay** de *Escape From Zona Sur*. Tu trabajo es construir todos los sistemas que hacen al loop de juego: inventario, loot, crafteo, extracción, economía y progresión del personaje.

---

## 🎯 Responsabilidades

- Sistema de **inventario** (cuadrícula de slots con peso)
- Sistema de **loot** (SpawnItems en el mundo, tablas de probabilidad)
- Sistema de **crafteo** básico
- Sistema de **extracción** (zona + timer)
- Sistema de **economía** (comprar/vender con NPC)
- Sistema de **stash** (persistencia entre raids)
- Gestión de **ItemData** (Resources tipados por ítem)
- Durabilidad de armas y armaduras

---

## 📁 Módulos asignados

```
scripts/
  systems/
    inventory_system.gd
    loot_system.gd
    crafting_system.gd
    extraction_system.gd
    economy_system.gd
    stash_system.gd
  player/
    inventory_component.gd
scenes/
  ui/
    inventory_ui.tscn
    loot_container.tscn
  world/
    extraction_zone.tscn
    loot_zone.tscn
```

---

## 🛠️ Stack técnico

| Herramienta | Uso |
|-------------|-----|
| GDScript | Lógica de sistemas |
| Godot Resources (.tres) | Definición de datos de ítems |
| JSON | Tablas de loot importadas |
| Godot Signals | Comunicación con UI y Godot Core |

---

## 🗃️ Modelo de datos: ItemData

```gdscript
# scripts/systems/item_data.gd
class_name ItemData
extends Resource

enum ItemType { WEAPON, AMMO, ARMOR, MEDICAL, FOOD, KEY, MISC }

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var item_type: ItemType = ItemType.MISC
@export var weight: float = 0.5         # kg
@export var max_stack: int = 1
@export var base_value: int = 0         # pesos (moneda del juego)
@export var icon: Texture2D
@export var world_model: PackedScene

# Durabilidad (solo ítems que la usan)
@export var has_durability: bool = false
@export var max_durability: float = 100.0
```

### Ítems iniciales del juego (Sprint 1)

| ID | Nombre | Tipo | Peso | Valor |
|----|--------|------|------|-------|
| `pistol_9mm` | Bersa Thunder 9 | WEAPON | 0.8 kg | 5000 |
| `ammo_9mm` | Munición 9mm (30u) | AMMO | 0.3 kg | 300 |
| `medkit_basic` | Botiquín básico | MEDICAL | 0.5 kg | 800 |
| `bandage` | Venda | MEDICAL | 0.1 kg | 150 |
| `food_alfajor` | Alfajor (energía) | FOOD | 0.1 kg | 50 |
| `armor_vest_basic` | Chaleco antibalas desgastado | ARMOR | 3.0 kg | 3000 |
| `cash_pesos` | Fajos de pesos | MISC | 0.1 kg | variable |

---

## 🚀 Primeras tareas (Sprint 1)

### 1. Implementar InventoryComponent

```gdscript
class_name InventoryComponent
extends Node

@export var max_weight: float = 20.0  # kg
var items: Array[Dictionary] = []  # [{item: ItemData, quantity: int, durability: float}]

signal item_added(item_data: ItemData, quantity: int)
signal item_removed(item_data: ItemData, quantity: int)
signal weight_changed(current: float, maximum: float)
signal inventory_full

func add_item(item_data: ItemData, quantity: int = 1) -> bool:
    if get_current_weight() + (item_data.weight * quantity) > max_weight:
        inventory_full.emit()
        return false
    # Buscar stack existente si el ítem es stackeable
    for entry in items:
        if entry.item.id == item_data.id and entry.quantity < item_data.max_stack:
            entry.quantity += quantity
            item_added.emit(item_data, quantity)
            weight_changed.emit(get_current_weight(), max_weight)
            return true
    # Agregar nuevo slot
    items.append({"item": item_data, "quantity": quantity, "durability": item_data.max_durability})
    item_added.emit(item_data, quantity)
    weight_changed.emit(get_current_weight(), max_weight)
    return true

func remove_item(item_id: String, quantity: int = 1) -> bool:
    for i in range(items.size()):
        if items[i].item.id == item_id:
            items[i].quantity -= quantity
            if items[i].quantity <= 0:
                items.remove_at(i)
            item_removed.emit(items[i].item if i < items.size() else null, quantity)
            weight_changed.emit(get_current_weight(), max_weight)
            return true
    return false

func get_current_weight() -> float:
    var total := 0.0
    for entry in items:
        total += entry.item.weight * entry.quantity
    return total
```

### 2. Sistema de extracción

```gdscript
class_name ExtractionZone
extends Area3D

@export var extraction_time: float = 5.0  # segundos en zona para extraer
@export var zone_name: String = "Extracción"
@export var is_active: bool = true

var player_in_zone: bool = false
var extraction_progress: float = 0.0

signal extraction_completed
signal extraction_progress_changed(progress: float)
signal player_entered_zone
signal player_left_zone

func _process(delta: float) -> void:
    if player_in_zone and is_active:
        extraction_progress += delta / extraction_time
        extraction_progress_changed.emit(extraction_progress)
        if extraction_progress >= 1.0:
            extraction_completed.emit()
    elif not player_in_zone:
        extraction_progress = max(0.0, extraction_progress - delta)
```

### 3. Tabla de loot (JSON)

**Archivo:** `assets/data/loot_tables.json`

```json
{
  "loot_tables": {
    "residential_house": {
      "rolls": 3,
      "entries": [
        {"id": "food_alfajor", "weight": 30, "min": 1, "max": 3},
        {"id": "bandage", "weight": 20, "min": 1, "max": 2},
        {"id": "cash_pesos", "weight": 40, "min": 100, "max": 500},
        {"id": "medkit_basic", "weight": 10, "min": 1, "max": 1}
      ]
    },
    "police_station": {
      "rolls": 5,
      "entries": [
        {"id": "pistol_9mm", "weight": 15, "min": 1, "max": 1},
        {"id": "ammo_9mm", "weight": 35, "min": 10, "max": 30},
        {"id": "armor_vest_basic", "weight": 10, "min": 1, "max": 1},
        {"id": "bandage", "weight": 40, "min": 2, "max": 5}
      ]
    },
    "train_station": {
      "rolls": 4,
      "entries": [
        {"id": "cash_pesos", "weight": 50, "min": 200, "max": 2000},
        {"id": "food_alfajor", "weight": 30, "min": 2, "max": 5},
        {"id": "medkit_basic", "weight": 20, "min": 1, "max": 1}
      ]
    }
  }
}
```

---

## 📡 APIs públicas para otros agentes

### InventoryComponent
```gdscript
func add_item(item_data: ItemData, quantity: int) -> bool
func remove_item(item_id: String, quantity: int) -> bool
func has_item(item_id: String) -> bool
func get_item_quantity(item_id: String) -> int
func get_current_weight() -> float
func get_all_items() -> Array[Dictionary]
# Señales: item_added, item_removed, inventory_full, weight_changed
```

### ExtractionZone
```gdscript
# Señales: extraction_completed, extraction_progress_changed(float)
# Para conectar desde UI/UX: escuchar extraction_progress_changed
```

---

## 📌 Reglas del agente

1. **Nunca guardar lógica de negocio en UI** — la UI solo muestra datos
2. **Toda tabla de datos** va en archivos JSON/Resource, no hardcodeada
3. Usar **Godot Resources** para ItemData (`.tres` files)
4. Conectar con UI únicamente a través de señales
