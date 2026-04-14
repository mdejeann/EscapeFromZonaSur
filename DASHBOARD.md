# 📋 Escape From Zona Sur — Tablero de Proyecto (Trello Style)

> Última actualización: Kick-off del proyecto  
> Metodología: Kanban con sprints bimestrales

---

## 🏗️ ÉPICAS DEL PROYECTO

| ID | Épica | Descripción |
|----|-------|-------------|
| E1 | **Fundación técnica** | Setup del proyecto Godot, estructura de carpetas, CI/CD |
| E2 | **Prototipo jugable** | Player controller, arma básica, nivel de prueba |
| E3 | **Mapa — Adrogue** | Primer mapa completo con loot y extracción |
| E4 | **Mapa — Capital Federal** | Segundo mapa con nueva ambientación urbana |
| E5 | **Sistemas de gameplay** | Inventario, loot, crafteo, durabilidad |
| E6 | **IA de enemigos** | Facciones, pathfinding, comportamiento táctico |
| E7 | **Narrativa y lore** | Historia, personajes, documentos, radio |
| E8 | **Audio y música** | SFX, música ambiental, sistema FMOD-like |
| E9 | **UI/UX completa** | Menú principal, HUD, inventario visual |
| E10 | **Polish y lanzamiento** | Optimización, bug fixing, Early Access |

---

## 🗂️ TABLERO KANBAN

### 📦 BACKLOG

#### E1 — Fundación técnica
- [ ] Configurar Godot 4 con C# o GDScript (elegir stack)
- [ ] Definir estándares de código (GDScript style guide)
- [ ] Configurar GitHub Actions para export automático
- [ ] Setup de `.gitignore` para Godot
- [ ] Definir convenciones de nombrado de assets
- [ ] Crear plantillas de escena base

#### E2 — Prototipo jugable
- [ ] Controlador de jugador (FPS con CharacterBody3D)
- [ ] Sistema de cámara en primera persona con bob
- [ ] Mecánica básica de arma (disparo, recarga, retroceso)
- [ ] Sistema de colisiones y física básica
- [ ] Escena de prueba (greybox)
- [ ] Muerte del jugador y respawn de prueba

#### E3 — Mapa Adrogue
- [ ] Diseño de nivel en papel (layout del mapa)
- [ ] Blockout 3D de Adrogue (barrio residencial)
- [ ] Zona de la estación de tren de Adrogue
- [ ] Comercios abandonados (saqueo de loot)
- [ ] Puntos de extracción (2-3 opciones)
- [ ] Spawn points de jugador y enemigos
- [ ] Sistema de clima (lluvia, niebla bonaerense)

#### E4 — Mapa Capital Federal
- [ ] Diseño de nivel: ruta desde zona sur hasta CABA
- [ ] Zona del Riachuelo (frontera narrativa)
- [ ] La Boca / San Telmo colapsado
- [ ] Centro/Microcentro como zona final
- [ ] Eventos dinámicos en CABA
- [ ] Jefes de zona únicos para CABA

#### E5 — Sistemas de gameplay
- [ ] Sistema de inventario (cuadrícula de peso)
- [ ] Sistema de loot (tablas de probabilidad por zona)
- [ ] Sistema de crafteo básico
- [ ] Durabilidad de armas y armaduras
- [ ] Sistema de hambre/sed/salud
- [ ] Stash del jugador (base entre raids)
- [ ] Sistema de extracción (timer + zona segura)
- [ ] Economía del juego (vendedor NPC)

#### E6 — IA de enemigos
- [ ] NavigationAgent3D con NavMesh
- [ ] Estados de IA: patrol / alert / combat / flee
- [ ] Facciones: Policía corrupta, pandillas locales, sobrevivientes hostiles
- [ ] Comportamiento de escuadra (flanqueo, cobertura)
- [ ] Detección por visión y sonido
- [ ] Spawner dinámico de enemigos por zona

#### E7 — Narrativa y lore
- [ ] Biblia del mundo: ¿qué pasó en Argentina?
- [ ] Facciones del mundo con motivaciones
- [ ] Documentos encontrables (notas, diarios)
- [ ] Radio AM con transmisiones ambientales
- [ ] Personaje del comerciante con diálogos
- [ ] Sistema de misiones principales (5 misiones arco 1)
- [ ] Sistema de misiones secundarias

#### E8 — Audio
- [ ] Efectos de disparo por tipo de arma
- [ ] Pasos diferenciados por superficie
- [ ] Música ambiental generativa por zona
- [ ] Efectos de ambiente (viento, perros, tráfico lejano)
- [ ] Audio 3D espacializado
- [ ] Sistema de reverb dinámico (interior/exterior)
- [ ] Voces de enemigos en lunfardo

#### E9 — UI/UX
- [ ] Menú principal (nueva partida, continuar, opciones)
- [ ] HUD de combate (salud, munición, indicadores)
- [ ] Pantalla de inventario (drag & drop)
- [ ] Mapa de extracción con waypoints
- [ ] Pantalla de muerte (lista de ítems perdidos)
- [ ] Pantalla de extracción exitosa
- [ ] Menú de opciones (gráficos, audio, controles)
- [ ] Subtítulos y localización (ES/EN)

#### E10 — Polish y lanzamiento
- [ ] Optimización de rendimiento (LOD, culling)
- [ ] Perfilado y corrección de bottlenecks
- [ ] Playtest con jugadores externos
- [ ] Corrección de bugs críticos (P0/P1)
- [ ] Página de Steam / itch.io
- [ ] Trailer de Early Access
- [ ] Build de Early Access

---

### 📋 TODO (Sprint 1 — Fundación)

| # | Tarea | Épica | Agente responsable | Prioridad |
|---|-------|-------|-------------------|-----------|
| 1 | Crear `project.godot` y estructura de carpetas | E1 | @core | 🔴 Alta |
| 2 | `EventBus.gd` con todas las señales tipadas | E1 | @core | 🔴 Alta |
| 3 | Player FPS controller (CharacterBody3D) | E2 | @core | 🔴 Alta |
| 4 | CSG blockout de Adrogue (4 zonas) | E3 | @world | 🔴 Alta |
| 5 | `ItemData.gd` Resource + 7 ítems base (.tres) | E5 | @gameplay | 🔴 Alta |
| 6 | Instalar Beehave plugin | E6 | @ai | 🟡 Media |
| 7 | `AudioManager.gd` autoload + buses | E8 | @audio | 🟡 Media |
| 8 | `GameTheme.tres` con paleta de colores | E9 | @ui | 🟡 Media |

---

### 🔄 EN PROGRESO

| # | Tarea | Épica | Agente | Inicio |
|---|-------|-------|--------|--------|
| — | *Vacío — Proyecto en kick-off* | — | — | — |

---

### ✅ HECHO

| # | Tarea | Épica | Completado |
|---|-------|-------|-----------|
| 1 | Crear repositorio GitHub | E1 | ✅ |
| 2 | `README.md` del proyecto | E1 | ✅ |
| 3 | `DASHBOARD.md` inicial | E1 | ✅ |
| 4 | `docs/AGENTS.md` — contexto Copilot Workspace (7 agentes × 4 tareas) | E1 | ✅ |
| 5 | `docs/architecture.md` — jerarquía, EventBus, CSG, Beehave | E1 | ✅ |
| 6 | `project.godot` — Godot 4.4 config, autoloads, input map | E1 | ✅ |
| 7 | `src/autoloads/EventBus.gd` — señales tipadas | E1 | ✅ |
| 8 | `src/autoloads/GameState.gd` — estado del raid | E1 | ✅ |
| 9 | `src/player/PlayerController.gd` — esqueleto FPS | E2 | ✅ |
| 10 | `src/player/CameraController.gd` + `HealthComponent.gd` | E2 | ✅ |
| 11 | `src/systems/inventory/ItemData.gd` + `InventoryComponent.gd` | E5 | ✅ |
| 12 | `src/systems/loot/LootSystem.gd` + `assets/data/loot_tables.json` | E5 | ✅ |
| 13 | `src/systems/audio/AudioManager.gd` | E8 | ✅ |
| 14 | `src/enemies/EnemyBase.gd` + `SensorComponent.gd` | E6 | ✅ |
| 15 | `src/world/ExtractionZone.gd` + `LootContainer.gd` | E3 | ✅ |
| 16 | `.gitignore` para Godot 4 | E1 | ✅ |

---

### 🚫 BLOQUEADO

| # | Tarea | Razón del bloqueo | Responsable resolución |
|---|-------|------------------|----------------------|
| — | *Sin bloqueos actualmente* | — | — |

---

## 🏃 SPRINTS

### Sprint 1 — Fundación técnica (Semanas 1-2)
**Objetivo:** EventBus funcionando, player FPS moviéndose en un CSG greybox de Adrogue.

**Criterios de aceptación:**
- [x] Repositorio configurado con estructura `src/` y `docs/AGENTS.md`
- [x] `project.godot` con autoloads, input map y renderer configurados
- [x] `EventBus.gd` con todas las señales tipadas
- [ ] Player puede moverse, saltar, agacharse y apuntar en primera persona
- [ ] CSG blockout de Adrogue con 4 zonas y NavMesh bakeado
- [ ] `ItemData.gd` + 7 recursos `.tres` de ítems base
- [ ] `InventoryComponent.gd` funcional con sistema de peso

---

### Sprint 2 — Sistemas core (Semanas 3-4)
**Objetivo:** Inventario, loot y primer enemigo IA funcional.

**Criterios de aceptación:**
- [ ] Sistema de inventario con drag & drop funcional
- [ ] Tabla de loot con al menos 10 ítems
- [ ] Enemigo básico con estados: patrol / alert / attack
- [ ] HUD básico (salud + munición)
- [ ] Punto de extracción funcional

---

### Sprint 3 — Mapa Adrogue Alpha (Semanas 5-8)
**Objetivo:** Mapa de Adrogue jugable con loop completo (entrar → lootear → extraer).

**Criterios de aceptación:**
- [ ] Mapa de 3-4 zonas diferenciadas (barrio, estación, comercios, villa)
- [ ] 3-4 tipos de enemigos con facciones distintas
- [ ] Sistema de clima (lluvia bonaerense)
- [ ] Loop de extracción completo y funcional
- [ ] Música y SFX básicos integrados

---

### Sprint 4 — Narrativa y mapa CABA (Semanas 9-14)
**Objetivo:** Segundo mapa y arco narrativo principal.

---

### Sprint 5 — Polish y EA Launch (Semanas 15-20)
**Objetivo:** Early Access en itch.io o Steam.

---

## 📊 MÉTRICAS DE ÉXITO

| Métrica | Objetivo Sprint 1 | Objetivo EA |
|---------|------------------|-------------|
| FPS en escena de prueba | 60 fps constantes | 60 fps en mapas finales |
| Tiempo de carga de mapa | < 5 seg | < 8 seg |
| Ítems de loot implementados | 5 | 50+ |
| Enemigos únicos | 1 | 8+ |
| Mapas jugables | 0 (greybox) | 2 completos |
| Líneas de diálogo/lore | 0 | 200+ |

---

## 🔗 RECURSOS Y REFERENCIAS

- 🎮 Road To Vostok: https://roadtovostok.com/ (referencia principal)
- 🎮 Escape From Tarkov (mecánicas de extracción y loot)
- 📚 Godot 4 Docs: https://docs.godotengine.org/en/stable/
- 🌳 Beehave (behavior trees para Godot 4): https://github.com/bitbrain/beehave
- 🗺️ Google Maps — Adrogue zona (para referencia de layout)
- 📐 Arquitectura del proyecto: [docs/architecture.md](docs/architecture.md)
- 🤖 Contexto de agentes: [docs/AGENTS.md](docs/AGENTS.md)
