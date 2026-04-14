# GameState.gd
# Autoload singleton — estado global del raid en curso.
# Agente responsable: @core
extends Node


enum RaidState {
	MENU,       ## En el menú principal o stash
	PREPARING,  ## Cargando el mapa
	IN_RAID,    ## Jugador activo en la zona
	EXTRACTED,  ## Extracción completada
	DEAD        ## Jugador muerto en este raid
}

## Estado actual del raid.
var current_state: RaidState = RaidState.MENU

## ID del mapa actual (ej: "adrogue", "capital_federal").
var current_map_id: String = ""

## Segundos transcurridos desde el inicio del raid.
var raid_timer: float = 0.0

## Duración máxima del raid en segundos (30 min por defecto).
@export var raid_duration: float = 1800.0


func _process(delta: float) -> void:
	if current_state == RaidState.IN_RAID:
		raid_timer += delta
		if raid_timer >= raid_duration:
			_on_raid_timeout()


## Inicia un nuevo raid en el mapa indicado.
func start_raid(map_id: String) -> void:
	current_map_id = map_id
	raid_timer = 0.0
	current_state = RaidState.IN_RAID


## Registra una extracción exitosa.
func end_raid_success(loot_kept: Array) -> void:
	current_state = RaidState.EXTRACTED
	EventBus.player_extracted.emit(current_map_id, loot_kept)


## Registra la muerte del jugador.
func end_raid_death() -> void:
	current_state = RaidState.DEAD
	EventBus.player_died.emit()


## Devuelve el tiempo restante del raid en segundos.
func get_time_remaining() -> float:
	return max(0.0, raid_duration - raid_timer)


func _on_raid_timeout() -> void:
	# Tiempo agotado — si el jugador está vivo, muere
	if current_state == RaidState.IN_RAID:
		end_raid_death()
