# CameraController.gd
# Controlador de cámara FPS con weapon sway, tilt y lean.
# Adjuntar como hijo de CameraMount/HeadBob/Impulse dentro del PlayerController.
# Agente responsable: @core
class_name CameraController
extends Camera3D


@export_group("Weapon Sway")
@export var sway_enabled: bool = true
@export var sway_base_multiplier: float = 0.2
@export var sway_aim_multiplier: float = 0.1
@export var sway_smoothing: float = 5.0

@export_group("Movement Tilt")
@export var tilt_enabled: bool = true
@export var tilt_horizontal: float = 0.1
@export var tilt_vertical: float = 0.01
@export var tilt_smoothing: float = 4.0
@export var hip_push_forward: float = 0.02
@export var hip_push_backward: float = 0.01
@export var push_smoothing: float = 1.0

@export_group("Lean")
@export var lean_enabled: bool = true
@export var lean_speed: float = 5.0
@export var lean_angle: float = 15.0
@export var lean_offset: float = 0.2

var _sway_original_rotation: Vector3
var _sway_target_rotation: Vector3 = Vector3.ZERO
var _sway_relative_input: Vector2 = Vector2.ZERO

var _tilt_target_rotation: Vector3 = Vector3.ZERO
var _tilt_target_push: Vector3 = Vector3.ZERO

var _lean_l_toggle: bool = false
var _lean_r_toggle: bool = false

var _base_position: Vector3


func _ready() -> void:
	_base_position = position
	_sway_original_rotation = rotation_degrees


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_sway_relative_input.x = event.relative.x
		_sway_relative_input.y = event.relative.y


func _process(delta: float) -> void:
	_apply_weapon_sway(delta)
	_apply_movement_tilt(delta)
	_apply_lean(delta)
	_decay_impulse(delta)


func _apply_weapon_sway(delta: float) -> void:
	if not sway_enabled:
		return

	_sway_target_rotation = Vector3(
		_sway_original_rotation.x + _sway_relative_input.y * sway_base_multiplier,
		_sway_original_rotation.y + -_sway_relative_input.x * sway_base_multiplier,
		_sway_original_rotation.z
	)
	rotation_degrees = rotation_degrees.lerp(_sway_target_rotation, delta * sway_smoothing)
	_sway_relative_input = Vector2.ZERO


func _apply_movement_tilt(delta: float) -> void:
	if not tilt_enabled:
		return

	var player: CharacterBody3D = _get_player()
	if player == null:
		return

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")

	if input_dir.y < 0:
		_tilt_target_push.z = hip_push_forward * input_dir.y
	else:
		_tilt_target_push.z = hip_push_backward * input_dir.y

	_tilt_target_rotation.z = tilt_horizontal * input_dir.x
	_tilt_target_rotation.x = tilt_vertical * -input_dir.y

	position.z = lerpf(position.z, _base_position.z + _tilt_target_push.z, delta * push_smoothing)
	rotation.x = lerpf(rotation.x, _tilt_target_rotation.x, delta * tilt_smoothing)
	rotation.z = lerpf(rotation.z, _tilt_target_rotation.z, delta * tilt_smoothing)


func _apply_lean(delta: float) -> void:
	if not lean_enabled:
		return

	# Hold mode
	if Input.is_action_pressed("lean_left"):
		rotation_degrees.z = lerpf(rotation_degrees.z, lean_angle, delta * lean_speed)
		position.x = lerpf(position.x, _base_position.x - lean_offset, delta * lean_speed)
	elif Input.is_action_pressed("lean_right"):
		rotation_degrees.z = lerpf(rotation_degrees.z, -lean_angle, delta * lean_speed)
		position.x = lerpf(position.x, _base_position.x + lean_offset, delta * lean_speed)
	else:
		rotation_degrees.z = lerpf(rotation_degrees.z, 0.0, delta * lean_speed)
		position.x = lerpf(position.x, _base_position.x, delta * lean_speed)


func _decay_impulse(delta: float) -> void:
	# Smooth decay of impulse node if it exists as sibling
	var impulse := get_parent() if get_parent() and get_parent().name == "Impulse" else null
	if impulse:
		impulse.position = impulse.position.lerp(Vector3.ZERO, delta * 20.0)
		impulse.rotation = impulse.rotation.lerp(Vector3.ZERO, delta * 5.0)


func _get_player() -> CharacterBody3D:
	var node := get_parent()
	while node:
		if node is CharacterBody3D:
			return node
		node = node.get_parent()
	return null
