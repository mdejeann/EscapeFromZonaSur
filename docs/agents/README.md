# 🤖 Agentes de Desarrollo — Escape From Zona Sur

Este documento es el **índice maestro** de los 7 agentes especializados de GitHub Copilot asignados al proyecto.

> El contexto completo para Copilot Workspace está en [`docs/AGENTS.md`](../AGENTS.md) — ese es el archivo a cargar en cada sesión.

---

## ¿Cómo funciona el modelo de agentes?

Cada agente es un perfil de GitHub Copilot configurado para actuar como un especialista en su área. Cada uno tiene:
- Un **README propio** con su rol, responsabilidades, stack y primeras tareas
- Un **skill set** diferenciado
- Acceso **limitado** a los módulos del código que le corresponden

---

## 🗺️ Mapa de agentes

```
┌──────────────────────────────────────────────────────────────────┐
│                    PROYECTO: Escape From Zona Sur                │
├──────────────────┬───────────────────────────────────────────────┤
│  PILAR           │  AGENTE                                       │
├──────────────────┼───────────────────────────────────────────────┤
│  Motor / Player  │  ⚙️  @core                                    │
│  Mundo / Mapas   │  🌍 @world                                    │
│  Sistemas        │  🎒 @gameplay                                 │
│  IA              │  🤖 @ai                                       │
│  Arte            │  🎨 @art                                      │
│  Audio           │  🔊 @audio                                    │
│  Interfaz        │  🖥️  @ui                                      │
└──────────────────┴───────────────────────────────────────────────┘
```

---

## 📋 Tabla de agentes

| Agente | Contexto principal | Módulos del proyecto | Herramientas principales |
|--------|-------------------|---------------------|--------------------------|
| ⚙️ @core | [AGENTS.md](../AGENTS.md#core--core-systems) | `src/autoloads/`, `src/player/` | GDScript, Godot 4.4, GitHub Actions |
| 🌍 @world | [AGENTS.md](../AGENTS.md#world--world--level-design) | `src/world/`, `scenes/world/` | GDScript, Godot CSG, NavigationRegion3D |
| 🎒 @gameplay | [AGENTS.md](../AGENTS.md#gameplay--gameplay-systems) | `src/systems/inventory/`, `src/systems/loot/` | GDScript, Godot Resources (.tres), JSON |
| 🤖 @ai | [AGENTS.md](../AGENTS.md#ai--ai--enemies) | `src/enemies/`, `addons/beehave/` | GDScript, Beehave, NavigationAgent3D |
| 🎨 @art | [AGENTS.md](../AGENTS.md#art--art--assets) | `assets/`, `scenes/world/` | Blender, Godot import pipeline |
| 🔊 @audio | [AGENTS.md](../AGENTS.md#audio--audio--sound-design) | `src/systems/audio/`, `assets/audio/` | GDScript, Godot AudioServer |
| 🖥️ @ui | [AGENTS.md](../AGENTS.md#ui--uiux) | `src/ui/`, `scenes/ui/` | GDScript, Godot Control nodes, Theme |

---

## 🔄 Flujo de comunicación entre agentes

```
Todos los sistemas se comunican via EventBus.gd (autoload)
— sin referencias directas entre módulos de distintos agentes.

@core      → define EventBus y APIs del player  → todos los agentes
@world     → provee NavMesh y layout de mapa    → @ai
@gameplay  → expone señales de inventario/loot  → @ui, @audio
@ai        → emite enemy_died con loot_table_id → @gameplay
@art       → provee assets visuales             → @world, @ui
@audio     → escucha EventBus                   → (produce sonido)
@ui        → escucha EventBus                   → (muestra datos)
```

---

## 📌 Convenciones generales

- Todo el código en **GDScript** (Godot 4.4)
- Comentarios en **español** (para este proyecto)
- Nombres de archivos: `snake_case`
- Nombres de clases: `PascalCase` + declarar `class_name`
- Señales: `snake_case` prefijadas con verbo pasado (ej: `health_changed`, `item_picked_up`)
- Escenas: una escena por concepto de juego
- **Toda comunicación cross-sistema** vía `EventBus.gd` — sin `get_node()` entre agentes
- Ramas Git: `feat/<agente>/<feature>` — ej: `feat/core/player-controller`
- Antes de empezar cualquier tarea, consultar el [DASHBOARD](../../DASHBOARD.md) y [AGENTS.md](../AGENTS.md)
