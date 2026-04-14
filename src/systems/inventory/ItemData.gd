# ItemData.gd
# Resource base para todos los ítems del juego.
# Guardar instancias como archivos .tres en assets/data/items/
# Agente responsable: @gameplay
class_name ItemData
extends Resource


enum ItemType {
	WEAPON,   ## Armas de fuego o cuerpo a cuerpo
	AMMO,     ## Munición por tipo de calibre
	ARMOR,    ## Chalecos, cascos, protectores
	MEDICAL,  ## Botiquines, vendas, analgésicos
	FOOD,     ## Alimentos que restauran energía/hidratación
	KEY,      ## Llaves de puertas o cofres especiales
	MISC      ## Objetos de valor, electrónica, documentos
}

@export_group("Identificación")
@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var item_type: ItemType = ItemType.MISC

@export_group("Economía y peso")
@export var weight: float = 0.5          # kilogramos
@export var max_stack: int = 1           # 1 = no stackeable
@export var base_value: int = 0          # pesos (moneda del juego)

@export_group("Visuales")
@export var icon: Texture2D
@export var world_scene: PackedScene     # escena instanciada cuando cae al suelo

@export_group("Durabilidad")
@export var has_durability: bool = false
@export var max_durability: float = 100.0
