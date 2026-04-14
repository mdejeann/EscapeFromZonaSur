# 🤖 Agentes de Desarrollo — Escape From Zona Sur

Este documento es el **índice maestro** de los 8 agentes especializados de GitHub Copilot asignados al proyecto.

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
│  Diseño          │  🎮 Game Designer                             │
│  Motor           │  ⚙️  Godot Core Dev                           │
│  Sistemas        │  🎒 Gameplay Systems                          │
│  IA              │  🤖 AI & Enemies                              │
│  Arte            │  🎨 Art & Assets                              │
│  Audio           │  🔊 Audio                                     │
│  Historia        │  📖 Narrative                                 │
│  Interfaz        │  🖥️  UI/UX                                    │
└──────────────────┴───────────────────────────────────────────────┘
```

---

## 📋 Tabla de agentes

| Agente | Archivo | Módulos del proyecto | Herramientas principales |
|--------|---------|---------------------|--------------------------|
| 🎮 Game Designer | [agent-game-design.md](agent-game-design.md) | `docs/`, `DASHBOARD.md` | Markdown, Miro, GDD templates |
| ⚙️ Godot Core Dev | [agent-godot-core.md](agent-godot-core.md) | `scripts/player/`, `project.godot`, `scenes/player/` | GDScript, Godot 4, Git |
| 🎒 Gameplay Systems | [agent-gameplay-systems.md](agent-gameplay-systems.md) | `scripts/systems/`, `scenes/ui/` | GDScript, JSON, Godot Resources |
| 🤖 AI & Enemies | [agent-ai-enemies.md](agent-ai-enemies.md) | `scripts/enemies/`, `scenes/enemies/` | GDScript, NavigationServer3D |
| 🎨 Art & Assets | [agent-art-assets.md](agent-art-assets.md) | `assets/`, `scenes/world/` | Blender, Godot Import Pipeline |
| 🔊 Audio | [agent-audio.md](agent-audio.md) | `assets/audio/`, `scripts/systems/audio*` | Godot AudioServer, FMOD (opcional) |
| 📖 Narrative | [agent-narrative.md](agent-narrative.md) | `docs/lore/`, `scripts/systems/quest*` | GDScript, Markdown, Ink (opcional) |
| 🖥️ UI/UX | [agent-ui-ux.md](agent-ui-ux.md) | `scenes/ui/`, `scripts/ui/` | GDScript, Godot Control nodes, Figma |

---

## 🔄 Flujo de comunicación entre agentes

```
Game Designer ──► define mecánicas ──► todos los agentes
Narrative ──────► define lore ──────► Art & Assets, Audio
Godot Core Dev ─► define APIs ──────► Gameplay Systems, AI & Enemies, UI/UX
Art & Assets ───► provee assets ────► Godot Core Dev, UI/UX
Audio ──────────► integra en ───────► Godot Core Dev
Gameplay Systems► expone signals ───► UI/UX
AI & Enemies ───► usa Navigation ───► Godot Core Dev
```

---

## 📌 Convenciones generales

- Todo el código en **GDScript** (a menos que se decida C# por performance)
- Comentarios en **español** (para este proyecto)
- Nombres de archivos: `snake_case`
- Nombres de clases: `PascalCase`
- Señales: `snake_case` prefijadas con verbo pasado (ej: `health_changed`, `item_picked_up`)
- Escenas: una escena por concepto de juego
- Antes de empezar cualquier tarea, consultar el [DASHBOARD](../../DASHBOARD.md)
