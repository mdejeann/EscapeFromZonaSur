# FactionSystem.gd
# Sistema de facciones con relaciones entre ellas.
# Determina hostilidad entre facciones y hacia el jugador.
# Agente responsable: @ai
class_name FactionSystem
extends Node


## Niveles de relación entre facciones.
enum Relation {
	ALLIED,          ## Cooperan activamente
	FRIENDLY,        ## No atacan, pueden ayudar
	NEUTRAL,         ## Ignoran al otro
	HOSTILE,         ## Atacan a la vista
	VERY_HOSTILE,    ## Atacan agresivamente, prioridad máxima
}

## Hostilidad base de cada facción hacia el jugador (0.0 = amigable, 1.0 = hostil máximo).
const PLAYER_HOSTILITY: Dictionary = {
	"bonaerense": 0.8,
	"la_banda": 0.5,
	"sobrevivientes": 0.2,
	"los_narcos": 1.0,
}

## Matriz de relaciones entre facciones.
## Clave: "faction_a->faction_b", Valor: Relation enum.
var _relations: Dictionary = {}


func _ready() -> void:
	_build_relation_matrix()


## Devuelve la relación de faction_a hacia faction_b.
func get_relation(faction_a: String, faction_b: String) -> Relation:
	if faction_a == faction_b:
		return Relation.ALLIED
	var key := faction_a + "->" + faction_b
	return _relations.get(key, Relation.NEUTRAL)


## Devuelve true si faction_a es hostil hacia faction_b.
func is_hostile(faction_a: String, faction_b: String) -> bool:
	var rel := get_relation(faction_a, faction_b)
	return rel == Relation.HOSTILE or rel == Relation.VERY_HOSTILE


## Devuelve true si faction_a es aliado o amigable con faction_b.
func is_friendly(faction_a: String, faction_b: String) -> bool:
	var rel := get_relation(faction_a, faction_b)
	return rel == Relation.ALLIED or rel == Relation.FRIENDLY


## Devuelve la hostilidad base de una facción hacia el jugador (0.0–1.0).
func get_player_hostility(faction: String) -> float:
	return PLAYER_HOSTILITY.get(faction, 0.5)


## Devuelve true si la facción es hostil hacia el jugador por defecto.
func is_hostile_to_player(faction: String) -> bool:
	return get_player_hostility(faction) >= 0.5


## Permite modificar la relación en runtime (ej: traicionar aliado).
func set_relation(faction_a: String, faction_b: String, relation: Relation) -> void:
	_relations[faction_a + "->" + faction_b] = relation


func _build_relation_matrix() -> void:
	# Bonaerense
	_set_both("bonaerense", "la_banda", Relation.HOSTILE)
	_set_both("bonaerense", "sobrevivientes", Relation.NEUTRAL)
	_set_relation("bonaerense", "los_narcos", Relation.FRIENDLY)  # aliado secreto
	_set_relation("los_narcos", "bonaerense", Relation.FRIENDLY)  # aliado secreto

	# La Banda
	_set_both("la_banda", "sobrevivientes", Relation.NEUTRAL)
	_set_both("la_banda", "los_narcos", Relation.HOSTILE)

	# Sobrevivientes
	_set_both("sobrevivientes", "los_narcos", Relation.VERY_HOSTILE)


## Establece relación en una dirección.
func _set_relation(from: String, to: String, rel: Relation) -> void:
	_relations[from + "->" + to] = rel


## Establece relación simétrica (ambas direcciones).
func _set_both(a: String, b: String, rel: Relation) -> void:
	_set_relation(a, b, rel)
	_set_relation(b, a, rel)
