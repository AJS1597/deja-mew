class_name GameHUD
extends CanvasLayer

@onready var level_label: Label = $LevelLabel


func set_level(level_number: int, level_count: int, level_title: String = "") -> void:
	var text := "Level %d / %d" % [level_number, level_count]
	if not level_title.is_empty():
		text += "  -  " + level_title
	level_label.text = text
