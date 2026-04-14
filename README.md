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
├── project.godot              # Configuración del proyecto Godot
├── README.md                  # Este archivo
├── DASHBOARD.md               # Tablero Trello del proyecto
├── .gitignore                 # Reglas de ignore para Godot
├── docs/
│   ├── agents/                # Roles y READMEs de cada agente IA
│   │   ├── README.md          # Índice de agentes
│   │   ├── agent-game-design.md
│   │   ├── agent-godot-core.md
│   │   ├── agent-gameplay-systems.md
│   │   ├── agent-ai-enemies.md
│   │   ├── agent-art-assets.md
│   │   ├── agent-audio.md
│   │   ├── agent-narrative.md
│   │   └── agent-ui-ux.md
│   └── uml/
│       ├── architecture.md    # Diagrama de arquitectura
│       ├── game-flow.md       # Flujo de juego
│       └── class-diagram.md   # Diagrama de clases principal
├── scenes/
│   ├── main_menu/
│   ├── world/
│   ├── player/
│   ├── enemies/
│   └── ui/
├── scripts/
│   ├── player/
│   ├── enemies/
│   ├── systems/
│   └── ui/
└── assets/
    ├── models/
    ├── textures/
    ├── audio/
    └── fonts/
```

---

## 🤖 Agentes de desarrollo

Este proyecto usa **8 agentes especializados** de GitHub Copilot para acelerar el desarrollo. Cada agente tiene un rol específico y sus instrucciones en [`docs/agents/`](docs/agents/README.md).

| Agente | Rol |
|--------|-----|
| 🎮 Game Designer | Diseño de mecánicas, niveles y balance |
| ⚙️ Godot Core Dev | Motor, sistemas base, física y controles |
| 🎒 Gameplay Systems | Inventario, loot, extracción, crafteo |
| 🤖 AI & Enemies | IA de enemigos, facciones, pathfinding |
| 🎨 Art & Assets | Modelos, texturas, animaciones |
| 🔊 Audio | Efectos de sonido, música ambiental, mezcla |
| 📖 Narrative | Historia, lore, diálogos, worldbuilding |
| 🖥️ UI/UX | Menús, HUD, inventario visual, accesibilidad |

---

## 🗂️ Tablero de proyecto

Ver el tablero completo en [`DASHBOARD.md`](DASHBOARD.md).

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
