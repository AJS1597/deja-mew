class_name Level
extends Node2D

signal completed

@export var level_number: int = 1
@export var level_count: int = 9
@export var level_name: String = ""

@onready var spawn: Marker2D = $Spawn
@onready var player: Player = $Player
@onready var exit: Area2D = $Exit
@onready var hud: GameHUD = $HUD


func _ready() -> void:
	player.global_position = spawn.global_position
	hud.set_level(level_number, level_count, level_name)
	exit.body_entered.connect(_on_exit_body_entered)


func _unhandled_input(event: InputEvent) -> void:
	# When launched directly with F6, this level is the current scene.
	if get_tree().current_scene != self:
		return

	if event.is_action_pressed("reset"):
		get_tree().reload_current_scene()
	elif event.is_action_pressed("quit"):
		get_tree().quit()


func _on_exit_body_entered(body: Node2D) -> void:
	if body is Player:
		exit.set_deferred("monitoring", false)
		completed.emit()
