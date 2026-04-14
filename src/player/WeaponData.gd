# WeaponData.gd
# Recurso de datos de arma. Crear instancias .tres en assets/data/weapons/.
# Los campos @export permiten tunear cada arma desde el editor sin cambiar código.
# Agente responsable: @core
class_name WeaponData
extends Resource


@export_group("Identity")
## Identificador único del arma (ej: "pistol_9mm"). Usado en señales EventBus.
@export var weapon_id: String = ""
@export var display_name: String = "Unknown Weapon"

@export_group("Combat Stats")
## Daño por impacto en puntos de salud.
@export var damage: int = 25
## Tiempo mínimo entre disparos (segundos). Menor = mayor cadencia.
@export var fire_rate: float = 0.15
## Si true, mantener el botón dispara automáticamente.
@export var auto_fire: bool = false
## Alcance máximo del raycast de disparo (metros).
@export var max_range: float = 50.0

@export_group("Ammo")
## Capacidad del cargador.
@export var max_ammo: int = 15
## Munición de reserva inicial.
@export var reserve_ammo: int = 45
## Duración de la animación de recarga (segundos).
@export var reload_time: float = 1.8

@export_group("Recoil")
## Retroceso vertical en radianes por disparo.
@export var recoil_vertical: float = 0.04
## Retroceso horizontal máximo en radianes por disparo (aleatório ±).
@export var recoil_horizontal: float = 0.01
