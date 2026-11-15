class_name Ghost
extends AnimatableBody2D

## A recorded past attempt. It replays from frame 0 in sync with the living
## player, then stays at its final position. It is always detectable by
## buttons (sensor layer), and becomes physically solid after a short delay.

const SENSOR_LAYER := 2
const SOLID_LAYER := 4

const NON_SOLID_TINT := Color(0.55, 0.85, 1.0, 0.45)
const SOLID_TINT := Color(0.6, 0.9, 1.0, 0.85)

@export var solid_delay: float = 2.0

@onready var sprite: Sprite2D = $Sprite2D

var _positions := PackedVector2Array()
var _sprite_positions := PackedVector2Array()
var _rotations := PackedFloat32Array()
var _flips := PackedByteArray()
var _next_frame: int = 0
var _elapsed: float = 0.0
var _is_solid: bool = false
var _playing: bool = false


func setup(
	positions: PackedVector2Array,
	sprite_positions: PackedVector2Array,
	rotations: PackedFloat32Array,
	flips: PackedByteArray
) -> void:
	_positions = positions
	_sprite_positions = sprite_positions
	_rotations = rotations
	_flips = flips


func start_playback() -> void:
	_next_frame = 0
	_elapsed = 0.0
	_is_solid = false
	collision_layer = SENSOR_LAYER
	sprite.modulate = NON_SOLID_TINT
	_playing = true

	if _positions.is_empty():
		_playing = false
		return

	_apply_frame(0)
	_next_frame = 1


func reset_playback() -> void:
	start_playback()


func _physics_process(delta: float) -> void:
	if not _playing:
		return

	_elapsed += delta
	if not _is_solid and _elapsed >= solid_delay:
		_become_solid()

	if _next_frame < _positions.size():
		_apply_frame(_next_frame)
		_next_frame += 1


func _apply_frame(index: int) -> void:
	global_position = _positions[index]
	sprite.position = _sprite_positions[index]
	sprite.rotation = _rotations[index]
	sprite.flip_h = _flips[index] != 0


func _become_solid() -> void:
	_is_solid = true
	collision_layer = SENSOR_LAYER | SOLID_LAYER
	sprite.modulate = SOLID_TINT
