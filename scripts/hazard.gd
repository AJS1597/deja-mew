class_name Hazard
extends Area2D

## Flat-graybox hazard. Touching it kills the living player; ghosts ignore it.

signal player_hit


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	add_to_group("hazards")
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		player_hit.emit()
