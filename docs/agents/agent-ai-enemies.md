# 🤖 Agente: AI & Enemies

## Rol
Eres el **desarrollador de IA y enemigos** de *Escape From Zona Sur*. Tu trabajo es crear enemigos con comportamiento táctico creíble, sistema de facciones, pathfinding y detección de jugador.

---

## 🎯 Responsabilidades

- Implementar la **máquina de estados** de enemigos (FSM)
- Configurar **NavigationAgent3D** y NavMesh para cada mapa
- Sistema de **detección**: visión en cono + detección por sonido
- Comportamiento de **escuadra**: flanqueo, apoyo, comunicación entre NPCs
- Sistema de **facciones** con relaciones entre ellas
- **Spawner dinámico** de enemigos según zona y dificultad
- IA de los enemigos debe verse **reactiva y creíble**, no perfecta

---

## 📁 Módulos asignados

```
scripts/
  enemies/
    enemy_base.gd          ← Clase base de todo enemigo
    enemy_states/
      state_patrol.gd
      state_alert.gd
      state_combat.gd
      state_flee.gd
    enemy_detection.gd     ← Visión y sonido
    enemy_squad.gd         ← Coordinación de grupo
    enemy_spawner.gd
  systems/
    faction_system.gd
scenes/
  enemies/
    enemy_base.tscn
    enemy_police.tscn
    enemy_gang_member.tscn
    enemy_survivor.tscn
```

---

## 🛠️ Stack técnico

| Herramienta | Uso |
|-------------|-----|
| GDScript | Lógica de IA |
| NavigationAgent3D | Pathfinding |
| Area3D / ShapeCast3D | Detección de jugador |
| AnimationTree | Animaciones de enemigos |

---

## 🗃️ Facciones del juego

| Facción | Descripción | Hostilidad hacia jugador | Base |
|---------|-------------|-------------------------|------|
| **Bonaerense** | Policía provincial corrupta | Alta | Comisaría |
| **La Banda** | Pandilla local con territorio | Media (si entrás su zona) | Villa |
| **Sobrevivientes** | Civiles desesperados | Baja (situacional) | Refugios |
| **Los Narcos** | Cartel organizado | Muy alta | Depósitos |
| **El Jugador** | Facción del protagonista | — | Stash |

### Matriz de relaciones entre facciones

| | Bonaerense | La Banda | Sobrevivientes | Los Narcos |
|---|---|---|---|---|
| **Bonaerense** | — | Hostil | Neutral | Aliado secreto |
| **La Banda** | Hostil | — | Neutral | Hostil |
| **Sobrevivientes** | Neutral | Neutral | — | Muy Hostil |
| **Los Narcos** | Aliado secreto | Hostil | Muy Hostil | — |

---

## 🚀 Primeras tareas (Sprint 1)

### 1. FSM base del enemigo

```gdscript
class_name EnemyBase
extends CharacterBody3D

enum State { PATROL, ALERT, COMBAT, FLEE, DEAD }

@export var faction: String = "generic"
@export var move_speed: float = 3.0
@export var health: float = 80.0
@export var detection_range: float = 15.0

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var detection: EnemyDetection = $EnemyDetection
@onready var anim_tree: AnimationTree = $AnimationTree

var current_state: State = State.PATROL
var target: Node3D = null
var patrol_points: Array[Vector3] = []
var current_patrol_index: int = 0

signal enemy_died(position: Vector3, faction: String)
signal player_spotted(enemy: EnemyBase)
signal alert_raised(position: Vector3)

func _ready() -> void:
    detection.target_spotted.connect(_on_target_spotted)

func _physics_process(delta: float) -> void:
    match current_state:
        State.PATROL: _process_patrol(delta)
        State.ALERT:  _process_alert(delta)
        State.COMBAT: _process_combat(delta)
        State.FLEE:   _process_flee(delta)
    move_and_slide()

func _change_state(new_state: State) -> void:
    current_state = new_state

func take_damage(amount: float) -> void:
    health -= amount
    if health <= 0:
        _die()
    elif current_state == State.PATROL:
        _change_state(State.ALERT)

func _die() -> void:
    _change_state(State.DEAD)
    enemy_died.emit(global_position, faction)
    # Spawn loot, desactivar colisiones, animación de muerte

func _on_target_spotted(spotted_target: Node3D) -> void:
    target = spotted_target
    _change_state(State.COMBAT)
    player_spotted.emit(self)
    alert_raised.emit(global_position)

func _process_patrol(delta: float) -> void:
    if patrol_points.is_empty():
        return
    nav_agent.target_position = patrol_points[current_patrol_index]
    if nav_agent.is_navigation_finished():
        current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
    _move_along_nav()

func _process_combat(delta: float) -> void:
    if not is_instance_valid(target):
        _change_state(State.PATROL)
        return
    nav_agent.target_position = target.global_position
    # Disparar si en rango
    if global_position.distance_to(target.global_position) < 20.0:
        _shoot_at_target()
    else:
        _move_along_nav()

func _move_along_nav() -> void:
    var next_pos = nav_agent.get_next_path_position()
    var direction = (next_pos - global_position).normalized()
    velocity = direction * move_speed

func _shoot_at_target() -> void:
    pass  # Implementar en Sprint 2
```

### 2. Sistema de detección

```gdscript
class_name EnemyDetection
extends Node3D

@export var vision_range: float = 15.0
@export var vision_angle: float = 90.0   # grados, campo de visión
@export var hearing_range: float = 25.0

signal target_spotted(target: Node3D)
signal noise_heard(origin: Vector3)

var _suspicion: float = 0.0  # 0 = tranquilo, 100 = en combate

func _physics_process(delta: float) -> void:
    _scan_for_player(delta)

func _scan_for_player(delta: float) -> void:
    var player = get_tree().get_first_node_in_group("player")
    if not player:
        return

    var to_player = player.global_position - global_position
    var distance = to_player.length()

    if distance > vision_range:
        _decrease_suspicion(delta)
        return

    # Verificar ángulo de visión
    var angle = rad_to_deg(global_transform.basis.z.angle_to(to_player.normalized()))
    if angle > vision_angle / 2.0:
        _decrease_suspicion(delta)
        return

    # Raycast para line of sight
    var space_state = get_world_3d().direct_space_state
    var query = PhysicsRayQueryParameters3D.create(
        global_position + Vector3.UP * 1.5,
        player.global_position + Vector3.UP * 1.0,
        0b11,  # collision mask
        [get_parent()]
    )
    var result = space_state.intersect_ray(query)

    if result and result.collider == player:
        _increase_suspicion(delta, distance)
    else:
        _decrease_suspicion(delta)

func _increase_suspicion(delta: float, distance: float) -> void:
    var rate = lerp(20.0, 5.0, distance / vision_range)  # más lento si está lejos
    _suspicion = min(100.0, _suspicion + rate * delta)
    if _suspicion >= 100.0:
        target_spotted.emit(get_tree().get_first_node_in_group("player"))

func _decrease_suspicion(delta: float) -> void:
    _suspicion = max(0.0, _suspicion - 10.0 * delta)

func notify_noise(origin: Vector3, loudness: float) -> void:
    if global_position.distance_to(origin) <= hearing_range * loudness:
        noise_heard.emit(origin)
```

---

## 📡 APIs públicas para otros agentes

```gdscript
# EnemyBase
func take_damage(amount: float) -> void
func get_faction() -> String
# Señales: enemy_died(position, faction), player_spotted(enemy), alert_raised(position)

# EnemyDetection
func notify_noise(origin: Vector3, loudness: float) -> void
# Señales: target_spotted(target), noise_heard(origin)
```

---

## 📌 Reglas del agente

1. La IA debe sentirse **humana pero falible** — los enemigos cometen errores
2. **Siempre usar NavigationAgent3D** — nunca trayectorias hardcodeadas
3. La facción determina comportamiento: policías son más organizados, pandillas más agresivos
4. Los enemigos en **escuadra** se comunican vía señales (no llamadas directas)
5. Cada tipo de enemigo tiene sus propios parámetros exportados
