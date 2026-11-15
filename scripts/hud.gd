class_name GameHUD
extends CanvasLayer

@onready var level_label: Label = $LevelLabel
@onready var ghost_label: Label = $GhostLabel
@onready var hint_label: Label = $HintLabel


func set_level(level_number: int, level_count: int, level_title: String = "") -> void:
	var text := "Level %d / %d" % [level_number, level_count]
	if not level_title.is_empty():
		text += "  -  " + level_title
	level_label.text = text


func set_ghosts(placed: int, total: int) -> void:
	ghost_label.visible = total > 0
	ghost_label.text = "Ghosts %d / %d" % [placed, total]


func set_hint(text: String) -> void:
	hint_label.text = text
	hint_label.visible = not text.is_empty()
