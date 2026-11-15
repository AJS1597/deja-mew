@tool
class_name MovingPlatform
extends AnimationPlayer

## A button-powered platform driven by a looping animation of
## PlatformBody:position. The platform plays while a linked button is held,
## then waits briefly and rewinds to the start after release.
##
## The first keyframe is also the platform's resting position, so the platform
## appears at its dock before the button is pressed.

@export var buttons: Array[PressureButton] = []
@export var require_all_buttons: bool = false
@export var animation_name: StringName = &"Move"
@export var rewind_delay: float = 2.0
@export var rewind_speed: float = 1.0

var _active: bool = false
var _release_timer: float = 0.0
var _rewinding: bool = false


func _ready() -> void:
	if Engine.is_editor_hint():
		# Show the platform at its first keyframe while editing.
		reset_state()
		return

	add_to_group("resettable")
	for button in buttons:
		if button != null:
			button.pressed_changed.connect(_on_button_changed)
	reset_state()
	_refresh()


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	if _active:
		return

	if _rewinding:
		var next_position := current_animation_position - delta * rewind_speed
		if next_position <= 0.0:
			seek(0.0, true)
			_rewinding = false
		else:
			seek(next_position, true)
	elif _release_timer > 0.0:
		_release_timer = maxf(_release_timer - delta, 0.0)
		if _release_timer <= 0.0:
			_rewinding = true


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

	if active == _active:
		return

	_active = active
	if _active:
		_release_timer = 0.0
		_rewinding = false
		_resume_forward()
	else:
		pause()
		_release_timer = rewind_delay
		_rewinding = false


func _resume_forward() -> void:
	if not has_animation(animation_name):
		push_warning("MovingPlatform has no animation named '%s'." % animation_name)
		return

	var resume_position := 0.0
	if current_animation == animation_name:
		resume_position = current_animation_position
	play(animation_name)
	seek(resume_position, true)


## Called by Level when the world resets after a death/give-up, and on ready.
func reset_state() -> void:
	_active = false
	_release_timer = 0.0
	_rewinding = false

	if has_animation(animation_name):
		play(animation_name)
		pause()
		seek(0.0, true)
