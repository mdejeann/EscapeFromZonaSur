# PlayerController.gd
# Controlador FPS del jugador con sistema de inercia inspirado en RTV.
# Agente responsable: @core
# Depende de: EventBus (autoload), CameraController (hijo), HealthComponent (hijo)
class_name PlayerController
extends CharacterBody3D


# ── Parámetros de movimiento ────────────────────────────────────────────────
@export_group("Movement")
@export var walk_speed: float = 2.5
@export var sprint_speed: float = 5.0
@export var crouch_speed: float = 1.0
@export var jump_velocity: float = 7.0
@export var crouch_height: float = 0.5
@export var lerp_speed: float = 5.0

@export_group("Inertia")
## Inercia mientras camina hacia atrás/lateral
@export var walk_inertia_side: float = 0.8
## Inercia mientras camina hacia atrás
@export var walk_inertia_back: float = 0.6
## Inercia mientras corre lateral
@export var run_inertia_side: float = 0.7
## Inercia mientras corre hacia atrás
@export var run_inertia_back: float = 0.6
## Velocidad de transición de inercia
@export var inertia_lerp_speed: float = 2.0

@export_group("Jump")
## Control aéreo (mayor = menos control en el aire)
@export var jump_control: float = 8.0
## Multiplicador de gravedad
@export var gravity_multiplier: float = 2.0
## Umbral de caída para daño (metros)
@export var fall_damage_threshold: float = 5.0

@export_group("Headbob")
@export var headbob_walk_speed: float = 10.0
@export var headbob_sprint_speed: float = 20.0
@export var headbob_crouch_speed: float = 8.0
@export var headbob_walk_intensity: float = 0.02
@export var headbob_sprint_intensity: float = 0.05
@export var headbob_crouch_intensity: float = 0.02

# ── Parámetros de cámara ────────────────────────────────────────────────────
@export_group("Camera")
@export var mouse_sensitivity: float = 0.002

# ── Nodos hijos (configurar en la escena) ───────────────────────────────────
@onready var camera_mount: Node3D = $CameraMount
@onready var head_bob_node: Node3D = $CameraMount/HeadBob
@onready var impulse_node: Node3D = $CameraMount/HeadBob/Impulse
@onready var collision_stand: CollisionShape3D = $CollisionShapeStand
@onready var collision_crouch: CollisionShape3D = $CollisionShapeCrouch
@onready var health: Node = $HealthComponent
@onready var footstep_raycast: RayCast3D = $FootstepRayCast
@onready var above_raycast: RayCast3D = $AboveRayCast

const GRAVITY: float = 9.8

# ── State variables ─────────────────────────────────────────────────────────
var _is_crouching: bool = false
var _is_sprinting: bool = false
var _is_moving: bool = false
var _is_grounded: bool = true
var _is_falling: bool = false

var _current_speed: float = 0.0
var _inertia: float = 1.0
var _velocity_multiplier: float = 1.0
var _movement_direction: Vector3 = Vector3.ZERO
var _input_direction: Vector2 = Vector2.ZERO

# Headbob
var _headbob_index: float = 0.0
var _headbob_intensity: float = 0.0
var _headbob_vector: Vector2 = Vector2.ZERO
var _can_step: bool = false

# Jump/Land/Crouch impulse
var _has_jumped: bool = false
var _has_landed: bool = true
var _last_velocity: Vector3 = Vector3.ZERO
var _fall_start_y: float = 0.0

# Impulse timers
var _jump_impulse: float = 0.0
var _jump_impulse_timer: float = 0.0
var _land_impulse: float = 0.0
var _land_impulse_timer: float = 0.0
var _crouch_impulse: float = 0.0
var _crouch_impulse_timer: float = 0.0
var _stand_impulse: float = 0.0
var _stand_impulse_timer: float = 0.0

# Surface detection
var _current_surface: String = "asphalt"
var _scan_timer: float = 0.0
const SCAN_CYCLE: float = 0.2


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	add_to_group("player")
	collision_stand.disabled = false
	collision_crouch.disabled = true


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_handle_mouse_look(event.relative)

	if event.is_action_pressed("inventory"):
		EventBus.inventory_toggle_requested.emit()

	if event.is_action_pressed("pause"):
		_toggle_pause()


func _physics_process(delta: float) -> void:
	_surface_detection(delta)
	_input_direction = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	_movement_states(delta)
	_movement(delta)
	_inertia_update(delta)
	_apply_gravity(delta)
	_falling()
	_landing(delta)
	_handle_crouch(delta)
	_handle_jump(delta)
	_jump_impulse_update(delta)
	_land_impulse_update(delta)
	_crouch_impulse_update(delta)
	_stand_impulse_update(delta)
	_headbob(delta)

	# Update SimpleGrassTextured interactive position
	var grass_singleton := get_node_or_null("/root/SimpleGrass")
	if grass_singleton:
		grass_singleton.set("player_position", global_position)


func _handle_mouse_look(relative: Vector2) -> void:
	rotate_y(-relative.x * mouse_sensitivity)
	camera_mount.rotate_x(-relative.y * mouse_sensitivity)
	camera_mount.rotation.x = clamp(camera_mount.rotation.x, -PI / 2.0, PI / 2.0)


# ── Movement States ─────────────────────────────────────────────────────────

func _movement_states(delta: float) -> void:
	if _input_direction != Vector2.ZERO:
		_is_moving = true

		if _is_crouching:
			_is_sprinting = false
			_current_speed = lerp(_current_speed, crouch_speed, delta * 2.5)
		elif Input.is_action_pressed("sprint"):
			_is_sprinting = true
			_current_speed = lerp(_current_speed, sprint_speed, delta * 1.0)
		else:
			_is_sprinting = false
			_current_speed = lerp(_current_speed, walk_speed, delta * 2.5)
	else:
		_current_speed = lerp(_current_speed, 0.0, delta * 5.0)
		_is_moving = false
		_is_sprinting = false


# ── Core Movement with Inertia ──────────────────────────────────────────────

func _movement(delta: float) -> void:
	if is_on_floor():
		_is_grounded = true
		_velocity_multiplier = 1.0
		_movement_direction = _movement_direction.lerp(
			(transform.basis * Vector3(_input_direction.x, 0.0, _input_direction.y)).normalized(),
			delta * lerp_speed
		)
	else:
		_is_grounded = false
		_velocity_multiplier = 0.8
		if _input_direction != Vector2.ZERO:
			_movement_direction = _movement_direction.lerp(
				(transform.basis * Vector3(_input_direction.x, 0.0, _input_direction.y)).normalized(),
				delta * lerp_speed / jump_control
			)

	if _movement_direction:
		velocity.x = _movement_direction.x * (_current_speed * _velocity_multiplier * _inertia)
		velocity.z = _movement_direction.z * (_current_speed * _velocity_multiplier * _inertia)
	else:
		velocity.x = 0.0
		velocity.z = 0.0

	_last_velocity = velocity
	move_and_slide()


# ── Inertia System ──────────────────────────────────────────────────────────
# Penaliza movimiento lateral y hacia atrás para dar sensación de peso.

func _inertia_update(delta: float) -> void:
	if not _is_moving:
		_inertia = lerpf(_inertia, 1.0, delta * inertia_lerp_speed)
		return

	if _is_sprinting:
		if _input_direction.y >= 0.0 and _input_direction.y < 0.5:
			_inertia = lerpf(_inertia, run_inertia_side, delta * inertia_lerp_speed)
		elif _input_direction.y > 0.5:
			_inertia = lerpf(_inertia, run_inertia_back, delta * inertia_lerp_speed)
		else:
			_inertia = lerpf(_inertia, 1.0, delta * inertia_lerp_speed)
	else:
		if _input_direction.y >= 0.0 and _input_direction.y < 0.5:
			_inertia = lerpf(_inertia, walk_inertia_side, delta * inertia_lerp_speed)
		elif _input_direction.y > 0.5:
			_inertia = lerpf(_inertia, walk_inertia_back, delta * inertia_lerp_speed)
		else:
			_inertia = lerpf(_inertia, 1.0, delta * inertia_lerp_speed)


# ── Gravity & Falling ───────────────────────────────────────────────────────

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta * gravity_multiplier


func _falling() -> void:
	if is_on_floor():
		if _is_falling:
			_is_falling = false
			var fall_distance := _fall_start_y - global_position.y
			if fall_distance > fall_damage_threshold:
				EventBus.player_took_fall_damage.emit(fall_distance)
			if fall_distance > 0.5:
				if not _has_jumped:
					_has_jumped = true
					_has_landed = false
	else:
		if not _is_falling:
			_is_falling = true
			_fall_start_y = global_position.y


func _landing(_delta: float) -> void:
	if is_on_floor():
		if _last_velocity.y < 0.0 and _has_jumped:
			_land_impulse = 0.1
			if not _has_landed:
				EventBus.player_footstep.emit(_current_surface)
			_has_landed = true
			_has_jumped = false


# ── Jump ────────────────────────────────────────────────────────────────────

func _handle_jump(_delta: float) -> void:
	if Input.is_action_just_pressed("jump") and is_on_floor() and not _is_crouching:
		_has_jumped = true
		_has_landed = false
		velocity.y = jump_velocity
		_jump_impulse = 0.1
		EventBus.player_footstep.emit(_current_surface)


# ── Crouch ──────────────────────────────────────────────────────────────────

func _handle_crouch(delta: float) -> void:
	if Input.is_action_just_pressed("crouch") and is_on_floor():
		if above_raycast and above_raycast.is_colliding() and _is_crouching:
			return  # No salir de crouch si hay algo arriba
		_is_crouching = not _is_crouching
		if _is_crouching:
			_crouch_impulse = 0.1
			collision_stand.disabled = true
			collision_crouch.disabled = false
		else:
			_stand_impulse = 0.1
			collision_stand.disabled = false
			collision_crouch.disabled = true

	# Lerp pelvis height
	var target_y := crouch_height if _is_crouching else 0.0
	camera_mount.position.y = lerpf(camera_mount.position.y, target_y, delta * 5.0)


# ── Headbob ─────────────────────────────────────────────────────────────────

func _headbob(delta: float) -> void:
	if head_bob_node == null:
		return

	if _is_sprinting and _is_moving:
		_headbob_intensity = headbob_sprint_intensity
		_headbob_index += headbob_sprint_speed * delta
	elif _is_moving and not _is_crouching:
		_headbob_intensity = headbob_walk_intensity
		_headbob_index += headbob_walk_speed * delta
	elif _is_crouching and _is_moving:
		_headbob_intensity = headbob_crouch_intensity
		_headbob_index += headbob_crouch_speed * delta

	if is_on_floor() and _input_direction != Vector2.ZERO:
		_headbob_vector.x = sin(_headbob_index / 2.0)
		_headbob_vector.y = sin(_headbob_index)
		head_bob_node.position.x = lerpf(head_bob_node.position.x, _headbob_vector.x * _headbob_intensity, delta * lerp_speed)
		head_bob_node.position.y = lerpf(head_bob_node.position.y, _headbob_vector.y * (_headbob_intensity * 2.0), delta * lerp_speed)

		# Trigger footstep on headbob cycle
		if _headbob_vector.y < -0.5 and not _can_step:
			_can_step = true
		if _headbob_vector.y > 0.5 and _can_step:
			EventBus.player_footstep.emit(_current_surface)
			_can_step = false
	else:
		head_bob_node.position.x = lerpf(head_bob_node.position.x, 0.0, delta * lerp_speed)
		head_bob_node.position.y = lerpf(head_bob_node.position.y, 0.0, delta * lerp_speed)


# ── Impulse Updates ─────────────────────────────────────────────────────────

func _jump_impulse_update(delta: float) -> void:
	if _jump_impulse_timer < _jump_impulse:
		_jump_impulse_timer += delta
		_apply_impulse_kick(1.5 if _is_sprinting else 1.0, true)
	else:
		_jump_impulse_timer = 0.0
		_jump_impulse = 0.0


func _land_impulse_update(delta: float) -> void:
	if _land_impulse_timer < _land_impulse:
		_land_impulse_timer += delta
		_apply_impulse_kick(1.5 if _is_sprinting else 1.0, false)
	else:
		_land_impulse_timer = 0.0
		_land_impulse = 0.0


func _crouch_impulse_update(delta: float) -> void:
	if _crouch_impulse_timer < _crouch_impulse:
		_crouch_impulse_timer += delta
		_apply_impulse_kick(0.5, true)
	else:
		_crouch_impulse_timer = 0.0
		_crouch_impulse = 0.0


func _stand_impulse_update(delta: float) -> void:
	if _stand_impulse_timer < _stand_impulse:
		_stand_impulse_timer += delta
		_apply_impulse_kick(0.5, false)
	else:
		_stand_impulse_timer = 0.0
		_stand_impulse = 0.0


func _apply_impulse_kick(multiplier: float, is_jump: bool) -> void:
	if impulse_node == null:
		return
	var kick_amount := 0.02 * multiplier
	var rot_x := 0.1 * multiplier
	var rot_y := 0.02 * multiplier
	if is_jump:
		impulse_node.position.y = lerpf(impulse_node.position.y, kick_amount, 0.3)
		impulse_node.rotation.x = lerpf(impulse_node.rotation.x, rot_x, 0.3)
	else:
		impulse_node.position.y = lerpf(impulse_node.position.y, -kick_amount, 0.3)
		impulse_node.rotation.x = lerpf(impulse_node.rotation.x, -rot_x, 0.3)
	impulse_node.rotation.y = lerpf(impulse_node.rotation.y, rot_y, 0.3)


# ── Surface Detection ───────────────────────────────────────────────────────

func _surface_detection(delta: float) -> void:
	_scan_timer += delta
	if _scan_timer < SCAN_CYCLE:
		return
	_scan_timer = 0.0

	if footstep_raycast and footstep_raycast.is_colliding():
		var collider := footstep_raycast.get_collider()
		if collider and collider.has_meta("surface_type"):
			_current_surface = collider.get_meta("surface_type")
		elif collider and collider.get_parent() and collider.get_parent().has_meta("surface_type"):
			# CSGBox3D collision bodies are children of the CSG node
			_current_surface = collider.get_parent().get_meta("surface_type")
		else:
			_current_surface = "asphalt"


# ── Utility ─────────────────────────────────────────────────────────────────

func is_sprinting() -> bool:
	return _is_sprinting


func is_crouching() -> bool:
	return _is_crouching


func get_inertia() -> float:
	return _inertia


func _toggle_pause() -> void:
	get_tree().paused = not get_tree().paused
	if get_tree().paused:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
