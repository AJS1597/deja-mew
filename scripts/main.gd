extends Node

## Loads levels in order and handles progression, restart, and quit.
## The levels array is populated in main.tscn; edit it in the Inspector.

@export var levels: Array[PackedScene] = []

@onready var level_holder: Node2D = $LevelHolder
@onready var complete_overlay: Control = $UI/CompleteOverlay

var current_index: int = 0
var current_level: Level = null


func _ready() -> void:
	complete_overlay.hide()
	if levels.is_empty():
		push_error("Main has no levels assigned.")
		return
	_load_level(0)


func _load_level(index: int) -> void:
	if index < 0 or index >= levels.size():
		return

	if is_instance_valid(current_level):
		level_holder.remove_child(current_level)
		current_level.queue_free()
		current_level = null

	current_index = index
	current_level = levels[index].instantiate() as Level
	if current_level == null:
		push_error("Entry %d in Main.levels is not a Level scene." % index)
		return

	level_holder.add_child(current_level)
	current_level.completed.connect(_on_level_completed)
	complete_overlay.hide()
	get_tree().paused = false


func _on_level_completed() -> void:
	call_deferred("_advance_level")


func _advance_level() -> void:
	if current_index + 1 >= levels.size():
		complete_overlay.show()
		get_tree().paused = true
		return

	_load_level(current_index + 1)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("reset"):
		get_tree().paused = false
		if complete_overlay.visible:
			complete_overlay.hide()
			_load_level(0)
		else:
			_load_level(current_index)
	elif event.is_action_pressed("quit"):
		get_tree().quit()
