class_name PressureButton
extends Area2D

## A floor pad that is pressed by the player or by a ghost body.
## Emits pressed_changed(bool) whenever its state changes.

signal pressed_changed(is_pressed: bool)
signal pressed
signal released

const UNPRESSED_COLOR := Color(0.88, 0.63, 0.25, 1.0)
const PRESSED_COLOR := Color(1.0, 0.82, 0.4, 1.0)
const PAD_DOWN_OFFSET := 2.0

var is_pressed: bool = false

var _was_pressed: bool = false
var _reset_cooldown: float = 0.0

@onready var pad: Polygon2D = $Pad


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1 | 2
	add_to_group("resettable")
	_apply_visual(false)


func _physics_process(delta: float) -> void:
	# The physics server can still report the old overlap for a frame after a
	# reset. Ignore polling briefly so the button does not flicker back on.
	if _reset_cooldown > 0.0:
		_reset_cooldown = maxf(_reset_cooldown - delta, 0.0)
		return

	var now_pressed := not get_overlapping_bodies().is_empty()
	if now_pressed == _was_pressed:
		return

	_was_pressed = now_pressed
	is_pressed = now_pressed
	_apply_visual(now_pressed)
	pressed_changed.emit(now_pressed)

	if now_pressed:
		pressed.emit()
	else:
		released.emit()


## Called by Level when the world resets after a death/give-up.
func reset_state() -> void:
	is_pressed = false
	_was_pressed = false
	_reset_cooldown = 0.1
	_apply_visual(false)


func _apply_visual(pressed_now: bool) -> void:
	if pad == null:
		return
	pad.color = PRESSED_COLOR if pressed_now else UNPRESSED_COLOR
	pad.position = Vector2(0.0, PAD_DOWN_OFFSET if pressed_now else 0.0)
