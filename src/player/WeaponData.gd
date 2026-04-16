# WeaponData.gd
# Recurso de datos de arma con sistema de retroceso mejorado.
# Agente responsable: @core
class_name WeaponData
extends Resource


@export_group("Identity")
@export var weapon_id: String = ""
@export var display_name: String = "Unknown Weapon"
@export var weapon_type: String = "rifle"  # rifle, pistol, shotgun, smg

@export_group("Combat Stats")
@export var damage: int = 25
@export var penetration: int = 0
@export var fire_rate: float = 0.15
@export var auto_fire: bool = false
@export var max_range: float = 50.0

@export_group("Ammo")
@export var max_ammo: int = 15
@export var reserve_ammo: int = 45
@export var reload_time: float = 1.8
@export var caliber: String = "9mm"

@export_group("Recoil")
@export var recoil_vertical: float = 0.04
@export var recoil_horizontal: float = 0.01
## Kick visual del arma hacia atrás al disparar
@export var kick: float = 0.05
## Potencia del kick (velocidad de retroceso)
@export var kick_power: float = 15.0
## Velocidad de recuperación del kick
@export var kick_recovery: float = 10.0
## Rotación del arma al disparar
@export var rotation_power: float = 0.02
## Velocidad de recuperación de la rotación
@export var rotation_recovery: float = 8.0

@export_group("Handling Positions")
@export var aim_position: Vector3 = Vector3.ZERO
@export var aim_rotation: Vector3 = Vector3.ZERO
@export var hip_position: Vector3 = Vector3(0.15, -0.1, -0.3)
@export var hip_rotation: Vector3 = Vector3.ZERO
@export var sprint_position: Vector3 = Vector3(0.1, -0.15, -0.2)
@export var sprint_rotation: Vector3 = Vector3(-20.0, 10.0, 0.0)
