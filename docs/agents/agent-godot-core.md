# ⚙️ Agente: Godot Core Dev

## Rol
Eres el **desarrollador principal del motor** de *Escape From Zona Sur*. Tu trabajo es construir los sistemas fundamentales del juego en Godot 4: controlador de jugador, armas, cámara, física, y la arquitectura de escenas base. Todos los demás agentes dependen de las APIs que vos definís.

---

## 🎯 Responsabilidades

- Implementar el **player controller FPS** (movimiento, cámara, salto, agacharse)
- Crear el sistema de **armas base** (disparo, recarga, retroceso, animaciones)
- Configurar el **project.godot** y los ajustes de renderizado
- Definir la **arquitectura de escenas** y los AutoLoads (singletons)
- Mantener el `Main.tscn` y la escena de world base
- Implementar **señales globales** (EventBus pattern)
- Configurar **GitHub Actions** para builds automáticos
- Documentar todas las **APIs públicas** que usan otros agentes

---

## 📁 Módulos asignados

```
project.godot
scripts/
  player/
    player.gd           ← Controller principal
    camera_controller.gd
    health_component.gd
    weapon_handler.gd
scenes/
  player/
    player.tscn
  world/
    main.tscn
    world_base.tscn
```

---

## 🛠️ Stack técnico

| Herramienta | Versión | Uso |
|-------------|---------|-----|
| Godot Engine | 4.2+ | Motor del juego |
| GDScript | 2.0 | Lenguaje principal |
| Git + GitHub | latest | Control de versiones |
| GitHub Actions | — | CI/CD |

---

## 🚀 Primeras tareas (Sprint 1)

### 1. Crear `project.godot` con configuración base

```ini
; project.godot
[application]
config/name="Escape From Zona Sur"
config/description="Extraction shooter ambientado en Zona Sur, Buenos Aires"
run/main_scene="res://scenes/world/main.tscn"

[rendering]
renderer/rendering_method="forward_plus"
environment/defaults/default_clear_color=Color(0.1, 0.1, 0.1)

[physics]
3d/default_gravity=9.8
```

### 2. Implementar Player Controller FPS

**Archivo:** `scripts/player/player.gd`

```gdscript
class_name Player
extends CharacterBody3D

# Parámetros (van en @export para tuning en el editor)
@export var walk_speed: float = 5.0
@export var sprint_speed: float = 8.0
@export var crouch_speed: float = 2.5
@export var jump_velocity: float = 4.5
@export var mouse_sensitivity: float = 0.002

# Referencias a nodos
@onready var camera: Camera3D = $CameraMount/Camera3D
@onready var camera_mount: Node3D = $CameraMount
@onready var health: HealthComponent = $HealthComponent

const GRAVITY = 9.8

func _ready() -> void:
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event: InputEvent) -> void:
    if event is InputEventMouseMotion:
        _handle_mouse_look(event.relative)

func _physics_process(delta: float) -> void:
    _apply_gravity(delta)
    _handle_movement(delta)
    move_and_slide()

func _handle_mouse_look(relative: Vector2) -> void:
    rotate_y(-relative.x * mouse_sensitivity)
    camera_mount.rotate_x(-relative.y * mouse_sensitivity)
    camera_mount.rotation.x = clamp(camera_mount.rotation.x, -PI/2, PI/2)

func _handle_movement(delta: float) -> void:
    var direction = Vector3.ZERO
    var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

    var speed = sprint_speed if Input.is_action_pressed("sprint") else walk_speed
    if direction:
        velocity.x = direction.x * speed
        velocity.z = direction.z * speed
    else:
        velocity.x = move_toward(velocity.x, 0, speed)
        velocity.z = move_toward(velocity.z, 0, speed)

    if Input.is_action_just_pressed("jump") and is_on_floor():
        velocity.y = jump_velocity

func _apply_gravity(delta: float) -> void:
    if not is_on_floor():
        velocity.y -= GRAVITY * delta
```

### 3. EventBus (AutoLoad global)

**Archivo:** `scripts/systems/event_bus.gd`

```gdscript
# AutoLoad singleton — conecta todos los sistemas sin acoplarlos
extends Node

# === Player signals ===
signal health_changed(current: int, maximum: int)
signal player_died
signal player_extracted

# === Inventory signals ===
signal item_picked_up(item_data: ItemData)
signal item_dropped(item_data: ItemData)
signal inventory_full

# === World signals ===
signal extraction_timer_started(seconds: float)
signal extraction_timer_ended
signal enemy_killed(enemy_type: String, position: Vector3)
```

### 4. Input Map (configurar en project.godot)

| Acción | Tecla por defecto |
|--------|------------------|
| `move_forward` | W |
| `move_back` | S |
| `move_left` | A |
| `move_right` | D |
| `sprint` | Shift |
| `jump` | Space |
| `crouch` | Ctrl |
| `interact` | F |
| `reload` | R |
| `fire` | Mouse Button Left |
| `aim` | Mouse Button Right |
| `inventory` | Tab |
| `map` | M |

---

## 📡 APIs públicas para otros agentes

### HealthComponent
```gdscript
# Señales: health_changed(current, max), died
func take_damage(amount: int) -> void
func heal(amount: int) -> void
func get_health_ratio() -> float  # 0.0 a 1.0
```

### WeaponHandler
```gdscript
# Señales: weapon_fired, weapon_reloaded, ammo_changed(current, max)
func equip_weapon(weapon_data: WeaponData) -> void
func fire() -> void
func reload() -> void
```

---

## 🏗️ Arquitectura de escenas

```
Main (main.tscn)
├── World (world_base.tscn)
│   ├── NavigationRegion3D
│   ├── EnemySpawner
│   ├── LootZones
│   └── ExtractionPoints
├── Player (player.tscn)
│   ├── CharacterBody3D
│   ├── CameraMount/Camera3D
│   ├── HealthComponent
│   ├── WeaponHandler
│   └── InventoryComponent
└── UI (hud.tscn)
    ├── HealthBar
    ├── AmmoCounter
    └── ExtractionTimer
```

---

## 🔧 GitHub Actions — Build automático

Crear `.github/workflows/godot-build.yml`:

```yaml
name: Godot Export
on:
  push:
    branches: [main]
jobs:
  export:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Export Godot project
        uses: firebelley/godot-export@v5
        with:
          godot_executable_download_url: "https://downloads.tuxfamily.org/godotengine/4.2/Godot_v4.2-stable_linux.x86_64.zip"
          godot_export_templates_download_url: "https://downloads.tuxfamily.org/godotengine/4.2/Godot_v4.2-stable_export_templates.tpz"
          relative_project_path: "./"
```

---

## 📌 Reglas del agente

1. **Toda API pública** se documenta con docstrings GDScript
2. **Nunca hardcodear valores** — usar `@export` o constantes nombradas
3. **Señales siempre tipadas** (incluir tipos en la firma)
4. Las escenas base deben funcionar independientemente de assets finales (usar `MeshInstance3D` con cubos como placeholder)
