# PlayerController.gd
# Controlador FPS del jugador. Extiende CharacterBody3D.
# Agente responsable: @core
# Depende de: EventBus (autoload), CameraController (hijo), HealthComponent (hijo)
class_name PlayerController
extends CharacterBody3D


# ── Parámetros de movimiento (tuneable desde el editor) ─────────────────────
@export_group("Movement")
@export var walk_speed: float = 5.0
@export var sprint_speed: float = 8.0
@export var crouch_speed: float = 2.5
@export var jump_velocity: float = 4.5
@export var crouch_height: float = 1.0

# ── Parámetros de cámara ────────────────────────────────────────────────────
@export_group("Camera")
@export var mouse_sensitivity: float = 0.002

# ── Nodos hijos (configurar en la escena) ───────────────────────────────────
@onready var camera_mount: Node3D = $CameraMount
@onready var collision_stand: CollisionShape3D = $CollisionShapeStand
@onready var collision_crouch: CollisionShape3D = $CollisionShapeCrouch
@onready var health: Node = $HealthComponent  # HealthComponent.gd
@onready var footstep_raycast: RayCast3D = $FootstepRayCast

const GRAVITY: float = 9.8
const FOOTSTEP_INTERVAL_WALK: float = 0.5
const FOOTSTEP_INTERVAL_SPRINT: float = 0.3

var _is_crouching: bool = false
var _footstep_timer: float = 0.0


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	add_to_group("player")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_handle_mouse_look(event.relative)

	if event.is_action_pressed("inventory"):
		EventBus.inventory_toggle_requested.emit()

	if event.is_action_pressed("pause"):
		_toggle_pause()


func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	_handle_crouch()
	_handle_jump()
	_handle_movement(delta)
	_handle_footstep(delta)
	move_and_slide()

	# Update SimpleGrassTextured interactive position
	var grass_singleton := get_node_or_null("/root/SimpleGrass")
	if grass_singleton:
		grass_singleton.set("player_position", global_position)


func _handle_mouse_look(relative: Vector2) -> void:
	rotate_y(-relative.x * mouse_sensitivity)
	camera_mount.rotate_x(-relative.y * mouse_sensitivity)
	camera_mount.rotation.x = clamp(camera_mount.rotation.x, -PI / 2.0, PI / 2.0)


func _handle_movement(delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()

	var speed: float = walk_speed
	if Input.is_action_pressed("sprint") and not _is_crouching:
		speed = sprint_speed
	elif _is_crouching:
		speed = crouch_speed

	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed)
		velocity.z = move_toward(velocity.z, 0.0, speed)


func _handle_jump() -> void:
	if Input.is_action_just_pressed("jump") and is_on_floor() and not _is_crouching:
		velocity.y = jump_velocity


func _handle_crouch() -> void:
	if Input.is_action_just_pressed("crouch"):
		_is_crouching = not _is_crouching
		collision_stand.disabled = _is_crouching
		collision_crouch.disabled = not _is_crouching


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta


func _handle_footstep(delta: float) -> void:
	if not is_on_floor() or velocity.length() < 0.5:
		return

	var interval := FOOTSTEP_INTERVAL_SPRINT if Input.is_action_pressed("sprint") else FOOTSTEP_INTERVAL_WALK
	_footstep_timer += delta
	if _footstep_timer >= interval:
		_footstep_timer = 0.0
		var surface := _detect_surface()
		EventBus.player_footstep.emit(surface)


func _detect_surface() -> String:
	if footstep_raycast.is_colliding():
		var collider := footstep_raycast.get_collider()
		if collider is StaticBody3D:
			# Leer metadato de superficie si existe
			if collider.has_meta("surface_type"):
				return collider.get_meta("surface_type")
	return "concrete"  # superficie por defecto


func _toggle_pause() -> void:
	get_tree().paused = not get_tree().paused
	if get_tree().paused:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
