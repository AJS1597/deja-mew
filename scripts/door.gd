class_name Door
extends AnimatableBody2D

## A sliding door driven by one or more pressure buttons.
## Drag PressureButton nodes into the `buttons` array in the Inspector.

enum OpenMode { WHILE_PRESSED, PERMANENT }

@export var buttons: Array[PressureButton] = []
@export var open_mode: OpenMode = OpenMode.WHILE_PRESSED
@export var require_all_buttons: bool = false
@export var slide_distance: float = 32.0
@export var slide_time: float = 0.15

var _closed_y: float
var _is_open: bool = false
var _latched: bool = false
var _tween: Tween


func _ready() -> void:
	collision_layer = 1
	collision_mask = 1
	_closed_y = position.y
	add_to_group("resettable")

	for button in buttons:
		if button != null:
			button.pressed_changed.connect(_on_button_changed)

	_refresh()


func _on_button_changed(_is_pressed: bool) -> void:
	_refresh()


func _refresh() -> void:
	var has_buttons := false
	var any_pressed := false
	var all_pressed := true

	for button in buttons:
		if button == null:
			continue
		has_buttons = true
		any_pressed = any_pressed or button.is_pressed
		all_pressed = all_pressed and button.is_pressed

	var active := false
	if has_buttons:
		active = all_pressed if require_all_buttons else any_pressed

	if open_mode == OpenMode.PERMANENT and active:
		_latched = true

	_set_open(active or _latched)


func _set_open(open: bool) -> void:
	if open == _is_open:
		return

	_is_open = open
	if _tween != null:
		_tween.kill()

	_tween = create_tween()
	var target_y := _closed_y - slide_distance if open else _closed_y
	_tween.tween_property(self, "position:y", target_y, slide_time) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_IN_OUT)


## Called by Level when the world resets after a death/give-up.
func reset_state() -> void:
	if _tween != null:
		_tween.kill()
		_tween = null

	_latched = false
	_is_open = false
	position.y = _closed_y
