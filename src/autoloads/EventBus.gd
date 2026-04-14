# EventBus.gd
# Autoload singleton — eje central de comunicación entre todos los sistemas.
# REGLA: Ningún sistema llama métodos de otro sistema directamente.
#        Todo pasa por señales emitidas aquí.
# Agente responsable: @core
extends Node


# ─── PLAYER ──────────────────────────────────────────────────────────────────

## Emitida por HealthComponent cuando la salud del jugador cambia.
signal health_changed(current: int, maximum: int)

## Emitida cuando el jugador muere. Desencadena pantalla de muerte y pérdida de ítems.
signal player_died

## Emitida cuando el jugador completa una extracción exitosa.
signal player_extracted(map_id: String, loot_kept: Array)

## Emitida en cada paso del jugador. AudioManager escucha esto para SFX de pasos.
signal player_footstep(surface_type: String)


# ─── WEAPONS ─────────────────────────────────────────────────────────────────

## Emitida cuando el jugador dispara. AudioManager y SensorComponent de enemigos la escuchan.
signal weapon_fired(weapon_id: String, position: Vector3)

## Emitida cuando el jugador recarga.
signal weapon_reloaded(weapon_id: String)

## Emitida cuando cambia la munición disponible. HUD la escucha.
signal ammo_changed(current: int, reserve: int)

## Emitida por cualquier disparo/explosión. SensorComponent.gd de enemigos la escucha.
## loudness va de 0.0 (silencioso) a 1.0 (máximo ruido).
signal noise_emitted(origin: Vector3, loudness: float)


# ─── INVENTORY ───────────────────────────────────────────────────────────────

## Emitida cuando el jugador recoge un ítem del mundo.
signal item_picked_up(item_data: Resource, quantity: int)

## Emitida cuando el jugador descarta un ítem del inventario.
signal item_dropped(item_data: Resource, quantity: int)

## Emitida cuando el inventario está lleno y no se puede agregar más peso.
signal inventory_full

## Emitida cuando el peso del inventario cambia. HUD la escucha para la barra de peso.
signal weight_changed(current: float, maximum: float)


# ─── WORLD ───────────────────────────────────────────────────────────────────

## Emitida cuando el jugador abre un contenedor de loot.
signal container_opened(container_id: String)

## Emitida cuando el jugador entra a un área de extracción.
signal extraction_zone_entered(zone_name: String)

## Emitida cuando el jugador sale de un área de extracción antes de completarla.
signal extraction_zone_exited(zone_name: String)

## Emitida durante la extracción. Valor de 0.0 (inicio) a 1.0 (completado).
signal extraction_progress_changed(progress: float)

## Emitida cuando el jugador completa el tiempo en la zona de extracción.
signal extraction_completed(zone_name: String)


# ─── ENEMIES ─────────────────────────────────────────────────────────────────

## Emitida cuando un enemigo muere. LootSystem escucha esto para spawnear loot.
signal enemy_died(position: Vector3, faction: String, loot_table_id: String)

## Emitida cuando un enemigo detecta visualmente al jugador.
signal enemy_spotted_player(enemy_position: Vector3, faction: String)

## Emitida cuando un enemigo escucha un ruido (disparo, pasos, etc.).
signal enemy_heard_noise(origin: Vector3, enemy_position: Vector3)

## Emitida para propagar el estado de alerta a otros enemigos de la misma facción.
signal alert_raised(position: Vector3, faction: String)


# ─── UI ──────────────────────────────────────────────────────────────────────

## Solicitar al HUD que muestre un mensaje temporal en pantalla.
signal hud_message_requested(text: String, duration: float)

## Solicitar toggle del inventario (lo escucha la escena de UI).
signal inventory_toggle_requested
