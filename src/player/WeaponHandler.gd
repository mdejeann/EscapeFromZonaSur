# WeaponHandler.gd
# Gestión de armas: equipar, disparar, recargar y retroceso.
# Se comunica exclusivamente via EventBus — no referencia otros sistemas directamente.
# Agente responsable: @core
class_name WeaponHandler
extends Node


@export_group("References")
## Nodo CameraMount del jugador. Asignar en la escena player.tscn.
@export var camera_mount: Node3D
## RayCast3D posicionado en la cámara apuntando hacia adelante. Asignar en escena.
@export var raycast: RayCast3D

@export_group("Default Weapon")
## Datos del arma equipada por defecto al iniciar.
@export var default_weapon: WeaponData

var _weapon: WeaponData
var _current_ammo: int = 0
var _reserve_ammo: int = 0
var _is_reloading: bool = false
var _fire_cooldown: float = 0.0


func _ready() -> void:
	if default_weapon != null:
		equip_weapon(default_weapon)
	else:
		_apply_weapon_defaults()


func _process(delta: float) -> void:
	if _fire_cooldown > 0.0:
		_fire_cooldown -= delta

	if _weapon == null:
		return

	if _weapon.auto_fire and Input.is_action_pressed("fire"):
		fire()
	elif not _weapon.auto_fire and Input.is_action_just_pressed("fire"):
		fire()

	if Input.is_action_just_pressed("reload"):
		reload()


# ── API pública ───────────────────────────────────────────────────────────────

## Equipa el arma con los datos proporcionados y reinicia el estado de munición.
func equip_weapon(weapon_data: WeaponData) -> void:
	if weapon_data == null:
		return
	_weapon = weapon_data
	_current_ammo = _weapon.max_ammo
	_reserve_ammo = _weapon.reserve_ammo
	_is_reloading = false
	_fire_cooldown = 0.0
	EventBus.ammo_changed.emit(_current_ammo, _reserve_ammo)


## Intenta realizar un disparo. Falla silenciosamente si recarga, en cooldown o sin bala.
func fire() -> void:
	if _weapon == null or _is_reloading or _fire_cooldown > 0.0:
		return
	if _current_ammo <= 0:
		if _reserve_ammo > 0:
			reload()
		return

	_current_ammo -= 1
	_fire_cooldown = _weapon.fire_rate

	var origin := _get_fire_origin()
	EventBus.weapon_fired.emit(_weapon.weapon_id, origin)
	EventBus.noise_emitted.emit(origin, 1.0)
	EventBus.ammo_changed.emit(_current_ammo, _reserve_ammo)

	_apply_recoil()
	_perform_raycast()


## Inicia la recarga si el cargador no está lleno y hay munición de reserva.
func reload() -> void:
	if _weapon == null or _is_reloading:
		return
	if _current_ammo == _weapon.max_ammo or _reserve_ammo <= 0:
		return

	_is_reloading = true
	await get_tree().create_timer(_weapon.reload_time).timeout

	var needed := _weapon.max_ammo - _current_ammo
	var taken := min(needed, _reserve_ammo)
	_current_ammo += taken
	_reserve_ammo -= taken
	_is_reloading = false

	EventBus.weapon_reloaded.emit(_weapon.weapon_id)
	EventBus.ammo_changed.emit(_current_ammo, _reserve_ammo)


## Devuelve true si actualmente hay una recarga en curso.
func is_reloading() -> bool:
	return _is_reloading


## Devuelve la munición actual del cargador.
func get_current_ammo() -> int:
	return _current_ammo


## Devuelve la munición de reserva disponible.
func get_reserve_ammo() -> int:
	return _reserve_ammo


# ── Privado ───────────────────────────────────────────────────────────────────

func _perform_raycast() -> void:
	if raycast == null:
		return
	raycast.force_raycast_update()
	if not raycast.is_colliding():
		return
	var collider := raycast.get_collider()
	if collider == null:
		return
	# Intentar aplicar daño al colisionador o a su padre (para componentes hijo)
	if collider.has_method("take_damage"):
		collider.take_damage(_weapon.damage)
	elif collider.get_parent() != null and collider.get_parent().has_method("take_damage"):
		collider.get_parent().take_damage(_weapon.damage)


func _apply_recoil() -> void:
	if camera_mount == null or _weapon == null:
		return
	camera_mount.rotation.x -= _weapon.recoil_vertical
	camera_mount.rotation.x = clamp(camera_mount.rotation.x, -PI / 2.0, PI / 2.0)
	camera_mount.rotation.y += randf_range(-_weapon.recoil_horizontal, _weapon.recoil_horizontal)


func _get_fire_origin() -> Vector3:
	if raycast != null:
		return raycast.global_position
	if get_parent() != null:
		return get_parent().global_position
	return Vector3.ZERO


func _apply_weapon_defaults() -> void:
	EventBus.ammo_changed.emit(0, 0)
