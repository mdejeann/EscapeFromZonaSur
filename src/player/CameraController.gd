# CameraController.gd
# Controlador de cámara FPS con head bob y suavizado.
# Adjuntar como hijo de CameraMount (Node3D) dentro del PlayerController.
# Agente responsable: @core
class_name CameraController
extends Camera3D


@export_group("Head Bob")
@export var bob_enabled: bool = true
@export var bob_frequency: float = 2.0   # ciclos por segundo
@export var bob_amplitude: float = 0.05  # metros de desplazamiento vertical

@export_group("Tilt")
@export var tilt_enabled: bool = true
@export var tilt_max_angle: float = 3.0  # grados de inclinación lateral al moverse

var _bob_time: float = 0.0
var _base_position: Vector3


func _ready() -> void:
	_base_position = position


func _process(delta: float) -> void:
	_apply_head_bob(delta)


func _apply_head_bob(delta: float) -> void:
	if not bob_enabled:
		return

	var player: CharacterBody3D = get_parent().get_parent()
	var speed := Vector2(player.velocity.x, player.velocity.z).length()

	if player.is_on_floor() and speed > 0.5:
		_bob_time += delta * bob_frequency * TAU
		var bob_offset := Vector3(
			sin(_bob_time * 0.5) * bob_amplitude * 0.5,
			sin(_bob_time) * bob_amplitude,
			0.0
		)
		position = _base_position + bob_offset
	else:
		_bob_time = 0.0
		position = position.lerp(_base_position, delta * 10.0)
