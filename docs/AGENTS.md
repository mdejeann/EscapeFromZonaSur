# 🤖 AGENTS — Escape From Zona Sur
> Copilot Workspace context file — cargar en cada sesión de trabajo
> Godot 4.4 · GDScript · Extraction Shooter · Zona Sur, Buenos Aires

---

## Arquitectura de comunicación (leer primero)

Todos los sistemas se comunican **exclusivamente** a través de `EventBus.gd` (autoload).
Nunca hagas referencias directas entre sistemas de distintos agentes — emití una señal y dejá que el receptor la escuche.

```
src/autoloads/EventBus.gd   ← eje central de señales tipadas
src/autoloads/GameState.gd  ← estado global del raid en curso
```

---

## @core — Core Systems

**Goal:** Set up Godot 4.4 project with FPS player controller, camera and weapon handling base.

**Stack:** GDScript, Godot 4.4+, CharacterBody3D, GitHub Actions

**Start with:** `src/autoloads/EventBus.gd`, `src/player/PlayerController.gd`

**Tasks:**

1. Crear `project.godot` con renderer `forward_plus`, input map completo (WASD + mouse + acciones de juego) y autoloads registrados (`EventBus`, `GameState`).

2. Implementar `src/autoloads/EventBus.gd` con todas las señales tipadas del juego (ver arquitectura en `docs/architecture.md`). Este archivo es el contrato de comunicación entre todos los agentes — documentar cada señal.

3. Implementar `src/player/PlayerController.gd` extendiendo `CharacterBody3D`: movimiento (walk/sprint/crouch), salto con gravedad real, y `src/player/CameraController.gd` con mouse look suavizado y head bob configurable por `@export`.

4. Crear `src/player/HealthComponent.gd` como nodo reutilizable (también lo usan los enemigos): `take_damage()`, `heal()`, señales `health_changed(current, maximum)` y `died`. Toda muerte pasa por `EventBus.player_died` o `EventBus.enemy_died`.

---

## @world — World & Level Design

**Goal:** Mapa de Adrogue jugable con CSG blockout, NavMesh, zonas de loot y puntos de extracción — sin esperar assets de arte.

**Stack:** GDScript, Godot CSG nodes, NavigationRegion3D, GridMap (opcional)

**Start with:** `scenes/world/adrogue/adrogue.tscn`, `src/world/ExtractionZone.gd`

**Tasks:**

1. Crear el blockout de Adrogue **solo con nodos CSG** (`CSGBox3D`, `CSGCylinder3D`, etc.): 4 zonas diferenciadas — barrio residencial, estación de tren, comercios saqueados, zona industrial. Dimensiones orientativas: mapa 200×200m, zonas de ~40×40m cada una. **No importar ningún asset de Blender todavía.**

2. Configurar `NavigationRegion3D` con `NavigationMesh` y hacer bake del navmesh. Ajustar `agent_radius`, `agent_height` y `cell_size` para movimiento FPS. Los enemigos del agente `@ai` dependen de esto.

3. Implementar `src/world/ExtractionZone.gd` (extends `Area3D`): jugador entra a la zona, aparece un timer progresivo, al completarlo emite `EventBus.extraction_completed`. Crear 3 instancias en el mapa con distintos `zone_name` y `extraction_time`.

4. Implementar `src/world/LootContainer.gd` (extends `Node3D`): referencia a un `loot_table_id: String`, al ser abierto por el jugador solicita al `LootSystem` los ítems y los instancia en el mundo. Emitir `EventBus.container_opened(container_id)`. Colocar 12+ contenedores distribuidos en el mapa de Adrogue.

---

## @gameplay — Gameplay Systems

**Goal:** Inventario con peso, tablas de loot, sistema de stash persistente entre raids y economía básica.

**Stack:** GDScript, Godot Resources (`.tres`), JSON, FileAccess

**Start with:** `src/systems/inventory/InventoryComponent.gd`, `src/systems/loot/LootSystem.gd`

**Tasks:**

1. Definir `src/systems/inventory/ItemData.gd` como `class_name ItemData extends Resource` con campos `@export`: `id`, `display_name`, `item_type` (enum), `weight`, `max_stack`, `base_value`, `icon: Texture2D`, `world_scene: PackedScene`. Crear al menos 7 recursos `.tres` de ítems iniciales en `assets/data/items/` (pistola Bersa, munición 9mm, botiquín, venda, alfajor, chaleco, fajos de pesos).

2. Implementar `src/systems/inventory/InventoryComponent.gd`: cuadrícula por peso (`max_weight: float @export`), `add_item()` con detección de stack y sobrepeso, `remove_item()`, `get_all_items()`. Emitir señales a través de `EventBus`: `item_picked_up`, `item_dropped`, `inventory_full`.

3. Crear `src/systems/loot/LootSystem.gd` (autoload): lee `assets/data/loot_tables.json`, expone `roll_table(table_id: String) -> Array[ItemData]` con lógica de peso/probabilidad. Crear tablas para: `residential_house`, `police_station`, `train_station`, `industrial_zone`.

4. Implementar `src/systems/inventory/StashSystem.gd`: persiste el inventario del stash entre raids usando `FileAccess` a `user://stash.json`. Serializar/deserializar ítems por `id + quantity`. El stash no se pierde al morir — solo los ítems equipados en el raid.

---

## @ai — AI & Enemies

**Goal:** 4 facciones de enemigos con comportamiento táctico via behavior trees (Beehave), detección por visión y sonido.

**Stack:** GDScript, Godot 4.4+, [Beehave](https://github.com/bitbrain/beehave) plugin, NavigationAgent3D

**Start with:** `addons/beehave/`, `src/enemies/EnemyBase.gd`

**Tasks:**

1. Instalar el plugin **Beehave** (copiar `addons/beehave/` al proyecto y habilitarlo en `Project → Plugins`). Familiarizarse con `BTRoot`, `Selector`, `Sequence` y `ActionLeaf`/`ConditionLeaf`. Crear una escena de prueba `scenes/enemies/test_bt.tscn` con un behavior tree que haga patrol simple.

2. Crear `src/enemies/EnemyBase.gd` (extends `CharacterBody3D`): campos `@export` para `faction: String`, `move_speed`, `health`. Adjuntar `HealthComponent` reutilizable del agente `@core`. Al morir, emitir `EventBus.enemy_died(position, faction, loot_table_id)` para que `@gameplay` spawne loot.

3. Implementar `src/enemies/SensorComponent.gd`: cono de visión configurable (`vision_range`, `vision_angle`), detección de sonido (`hearing_range`), raycast de line-of-sight. Suscribirse a `EventBus.noise_emitted(origin, loudness)`. Emitir `EventBus.enemy_spotted_player` y `EventBus.enemy_heard_noise(origin)`.

4. Construir behavior trees específicos para las **4 facciones** usando hojas Beehave propias en `src/enemies/bt_actions/` y `src/enemies/bt_conditions/`: **Bonaerense** (patrulla organizada, busca cobertura), **La Banda** (agresivo, flanquea), **Sobreviviente** (huye si muy dañado), **Los Narcos** (coordinación de escuadra, no ataca si no invadís su zona). Cada facción tiene su propio `bt_root.tscn`.

---

## @art — Art & Assets

**Goal:** Pipeline Blender → Godot, placeholders de jugador y arma, convenciones de assets para todo el equipo.

**Stack:** Blender 3.6+ LTS, Godot import pipeline (.glb), GDScript (importers)

**Start with:** `assets/models/`, `docs/agents/agent-art-assets.md`

**Tasks:**

1. Definir y documentar el **pipeline de exportación**: Blender → `.glb` con animaciones embebidas → import en Godot con `GenerateImporter`. Crear `docs/art-pipeline.md` con capturas de cada paso. Convenciones: `snake_case` para archivos, escala `1 unit = 1 metro`, origin al centro de masa.

2. Crear modelo placeholder del jugador (arms first-person): solo manos y cañón de arma en Blender, rig simple con 3 huesos, exportar como `assets/models/player/fp_arms.glb`. Crear `assets/models/weapons/pistol_9mm.glb` como placeholder geométrico (sin texturas fancy).

3. Diseñar el **atlas de texturas de entorno** para Adrogue: un atlas 2048×2048 con tiles de vereda, asfalto, ladrillo, rejas metálicas, paredes con humedad. Exportar como `assets/textures/environment/adrogue_atlas.png` con su `.import` configurado.

4. Documentar en `docs/agents/agent-art-assets.md` las convenciones de nombrado para todos los assets del proyecto. El agente `@world` y `@ui` deben seguir esta guía antes de importar cualquier recurso visual.

---

## @audio — Audio & Sound Design

**Goal:** Sistema de audio espacial dinámico con capas de ambiente por zona, SFX de armas y pasos según superficie.

**Stack:** GDScript, Godot AudioServer, AudioStreamPlayer3D, AudioBus

**Start with:** `src/systems/audio/AudioManager.gd`

**Tasks:**

1. Crear `src/systems/audio/AudioManager.gd` como autoload: layout de buses (`Master → SFX`, `Master → Music`, `Master → Ambience`) con control de volumen por bus. Exponer `play_sfx(stream: AudioStream, position: Vector3)`, `play_music(stream: AudioStream, fade_time: float)`. Registrar en autoloads del proyecto.

2. Implementar `src/systems/audio/FootstepSystem.gd`: detectar superficie bajo el jugador con `RayCast3D` + `PhysicsMaterial`, reproducir SFX diferente para asfalto/tierra/madera/metal/agua. Escuchar el evento de paso via `EventBus.player_footstep(surface_type)` para no acoplar con `@core`.

3. Crear `src/systems/audio/AmbientZoneAudio.gd` (extends `Area3D`): al entrar a la zona, hace crossfade al `ambient_stream` asignado. Zonas definidas: exterior-día (viento, perros, tráfico lejano), interior-abandonado (goteras, crujidos), zona de combate (tiros lejanos, helicóptero). Colocar volúmenes en la escena de Adrogue.

4. Conectar efectos de arma a `EventBus.weapon_fired(weapon_id, position)` y `EventBus.weapon_reloaded(weapon_id)`. Crear carpeta `assets/audio/sfx/weapons/` con placeholders (`AudioStreamGenerator` sintético si no hay grabaciones reales todavía). Integrar reverb dinámico: `AudioEffectReverb` en el bus SFX, modulado por un parámetro `reverb_amount` que varía según si el jugador está interior/exterior.

---

## @ui — UI/UX

**Goal:** HUD de combate, pantalla de inventario con drag-and-drop, menú principal y theme consistente.

**Stack:** GDScript, Godot Control nodes, Theme resources, Tween

**Start with:** `src/ui/HUD.gd`, `scenes/ui/hud.tscn`

**Tasks:**

1. Crear `assets/ui/GameTheme.tres` con la paleta de colores del juego: fondo oscuro (`#0D0D0D`), acento verde militar (`#4A5C3A`), texto principal (`#D4C9A8`), alerta roja (`#C0392B`). Definir fuentes (`assets/fonts/`), tamaños y estilos para todos los controles. **Todo nodo UI del proyecto hereda este theme.**

2. Construir `scenes/ui/hud.tscn`: barra de salud (animada con Tween al recibir daño), contador de munición (`ammo_current / ammo_reserve`), brújula con marcadores de extracción, timer de extracción (aparece solo cuando el jugador está en zona), crosshair dinámico. Conectar todo via `EventBus` — el HUD solo escucha señales, nunca llama métodos del jugador.

3. Implementar `scenes/ui/inventory.tscn` con grid drag-and-drop: la cuadrícula refleja los slots de `InventoryComponent`, cada celda muestra ícono + cantidad + durabilidad si aplica. Al hacer drop fuera del inventario, emitir `EventBus.item_dropped`. Incluir panel de peso actual/máximo con barra visual. Abrir/cerrar con `Tab` (pausa el juego, no detiene el timer de raid).

4. Crear `scenes/ui/main_menu.tscn`: pantalla de título con fondo animado (shader de lluvia bonaerense o imagen estática + parallax), botones "Nueva partida", "Continuar", "Opciones" y "Salir". La pantalla "Opciones" contiene sliders para volumen (SFX / Música / Ambiente) y resolución/pantalla completa. Persistir opciones con `ConfigFile` en `user://settings.cfg`.

---

## Convenciones compartidas

| Convención | Regla |
|------------|-------|
| Comunicación entre sistemas | Solo via `EventBus.gd` — sin `get_node()` cross-system |
| Nombrado de archivos | `snake_case` siempre |
| Nombrado de clases | `PascalCase` + `class_name` en todos los scripts |
| Señales | Verbo pasado + sustantivo: `player_died`, `item_picked_up` |
| `@export` | Todo valor de gameplay es `@export` — nunca hardcoded |
| Escenas placeholder | CSG o `MeshInstance3D` con `BoxMesh` — nunca bloquear por falta de arte |
| Ramas Git | `feat/<agente>/<feature>` — ej: `feat/core/player-controller` |
| Commits | Conventional Commits: `feat:`, `fix:`, `docs:`, `chore:` |
