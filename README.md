# 🔫 Escape From Zona Sur

> **Extraction shooter** de primera persona desarrollado en **Godot 4**, ambientado en la Zona Sur del Gran Buenos Aires — desde las calles de Adrogue hasta el corazón de Capital Federal.

---

## 🗺️ Concepto del juego

Inspirado en *Road To Vostok* y *Escape From Tarkov*, **Escape From Zona Sur** es un survival extraction shooter en primera persona donde el jugador debe infiltrarse en zonas de cuarentena y conflicto urbano en la provincia de Buenos Aires, recolectar recursos, sobrevivir encuentros con facciones hostiles y llegar a los puntos de extracción antes de que sea demasiado tarde.

### Ambientación
- **Región inicial:** Adrogue, Almirante Brown — suburbios abandonados, vías del tren, comercios saqueados.
- **Zona final:** Capital Federal — centros urbanos colapsados, autopistas vacías, el Riachuelo como frontera de no retorno.

### Pilares del juego
| Pilar | Descripción |
|-------|-------------|
| 🎯 Extracción | Entra a la zona, recoge loot, llega al punto de extracción |
| 💀 Riesgo permanente | La muerte tiene consecuencias reales (pierdes lo que llevas) |
| 🧠 IA de facciones | Enemigos con comportamiento táctico y facciones en conflicto |
| 🔧 Inventario y crafteo | Sistema de slots de peso y durabilidad de ítems |
| 📖 Narrativa ambiental | Lore oculto en documentos, grafitis y radio AM |

---

## 🛠️ Stack tecnológico

| Herramienta | Uso |
|-------------|-----|
| **Godot 4.x** | Motor principal del juego |
| **GDScript / C#** | Lógica de juego |
| **Blender** | Modelos 3D y animaciones |
| **FMOD / Godot AudioServer** | Sistema de audio dinámico |
| **GitHub + GitHub Copilot** | Control de versiones + asistencia de agentes IA |

---

## 📁 Estructura del proyecto

```
EscapeFromZonaSur/
├── project.godot              # Config Godot 4.4: autoloads, input map, renderer
├── README.md                  # Este archivo
├── DASHBOARD.md               # Tablero Trello del proyecto
├── .gitignore                 # Reglas de ignore para Godot
├── docs/
│   ├── AGENTS.md              # ★ Contexto Copilot Workspace — 7 agentes × 4 tareas
│   ├── architecture.md        # Jerarquía de sistemas, EventBus, CSG, Beehave
│   └── agents/                # READMEs detallados por agente
├── src/                       # Todo el código GDScript
│   ├── autoloads/
│   │   ├── EventBus.gd        # ★ Eje de comunicación entre sistemas
│   │   └── GameState.gd       # Estado global del raid
│   ├── player/                # PlayerController, CameraController, HealthComponent
│   ├── enemies/               # EnemyBase, SensorComponent, bt_actions/, bt_conditions/
│   ├── systems/
│   │   ├── inventory/         # ItemData, InventoryComponent, StashSystem
│   │   ├── loot/              # LootSystem
│   │   └── audio/             # AudioManager, FootstepSystem, AmbientZoneAudio
│   ├── world/                 # ExtractionZone, LootContainer
│   └── ui/                    # HUD, InventoryUI, MainMenu
├── scenes/
│   ├── player/
│   ├── enemies/
│   ├── world/
│   │   ├── adrogue/           # Primer mapa (CSG blockout → assets finales)
│   │   └── capital_federal/   # Segundo mapa
│   └── ui/
├── assets/
│   ├── models/
│   ├── textures/
│   ├── audio/
│   ├── fonts/
│   ├── ui/
│   └── data/
│       ├── items/             # *.tres ItemData resources
│       └── loot_tables.json
└── addons/
    └── beehave/               # Plugin: behavior trees para @ai
```

---

## 🤖 Agentes de desarrollo

Este proyecto usa **7 agentes especializados** de GitHub Copilot. El archivo [`docs/AGENTS.md`](docs/AGENTS.md) es el contexto principal para Copilot Workspace — cargarlo al iniciar cada sesión.

| Agente | Rol | Start files |
|--------|-----|------------|
| ⚙️ @core | Motor base, player controller, EventBus | `src/autoloads/EventBus.gd`, `src/player/PlayerController.gd` |
| 🌍 @world | Mapa CSG, NavMesh, zonas de loot y extracción | `scenes/world/adrogue/`, `src/world/ExtractionZone.gd` |
| 🎒 @gameplay | Inventario, loot tables, stash, economía | `src/systems/inventory/`, `src/systems/loot/` |
| 🤖 @ai | Facciones + Beehave behavior trees | `src/enemies/EnemyBase.gd`, `addons/beehave/` |
| 🎨 @art | Pipeline Blender→Godot, modelos, texturas | `assets/models/`, `docs/art-pipeline.md` |
| 🔊 @audio | Audio espacial, ambiente por zona, SFX | `src/systems/audio/AudioManager.gd` |
| 🖥️ @ui | HUD, inventario drag-and-drop, menú | `src/ui/HUD.gd`, `scenes/ui/` |

### Arquitectura clave
- **`EventBus.gd`** (autoload): todos los sistemas se comunican solo via señales — sin referencias cruzadas entre módulos
- **CSG blockout primero**: el mapa de Adrogue se construye con primitivas CSG antes de importar assets de Blender
- **Beehave**: plugin de behavior trees para IA de las 4 facciones

---

## 🗂️ Tablero de proyecto y documentación

- 📋 Tablero completo: [`DASHBOARD.md`](DASHBOARD.md)
- 🎮 Game Design Document: [`docs/gdd/GDD.md`](docs/gdd/GDD.md)
- 🤖 Contexto de agentes (Copilot Workspace): [`docs/AGENTS.md`](docs/AGENTS.md)
- 🏗️ Arquitectura del proyecto: [`docs/architecture.md`](docs/architecture.md)

---

## 🚀 Cómo empezar

1. Instalar [Godot 4.x](https://godotengine.org/download/)
2. Clonar el repositorio: `git clone https://github.com/mdejeann/EscapeFromZonaSur.git`
3. Abrir `project.godot` en Godot Engine
4. Revisar [`DASHBOARD.md`](DASHBOARD.md) para el estado actual de tareas
5. Leer el README del agente correspondiente antes de contribuir

---

## 📜 Licencia

Proyecto privado — todos los derechos reservados © 2024 mdejeann
