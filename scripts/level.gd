class_name Level
extends Node2D

signal completed

const GHOST_SCENE := preload("res://scenes/objects/ghost.tscn")
const ROOM_SIZE := Vector2(512.0, 288.0)
const FALL_LIMIT := 320.0

@export var level_number: int = 1
@export var level_count: int = 9
@export var level_name: String = ""
@export_multiline var hint: String = ""
@export var ghost_solid_delay: float = 2.0

@onready var spawn: Marker2D = $Spawn
@onready var player: Player = $Player
@onready var player_sprite: Sprite2D = $Player/Sprite2D
@onready var exit: Area2D = $Exit
@onready var hud: GameHUD = $HUD

var _max_ghosts: int = 0
var _ghosts: Array[Ghost] = []
var _respawning: bool = false
var _death_pending: bool = false
var _recording: bool = false

var _rec_positions := PackedVector2Array()
var _rec_sprite_positions := PackedVector2Array()
var _rec_rotations := PackedFloat32Array()
var _rec_flips := PackedByteArray()


func _ready() -> void:
	# Record after the player has moved this physics frame.
	process_physics_priority = 100
	set_process_unhandled_input(true)

	player.global_position = spawn.global_position

	_max_ghosts = maxi(level_number - 1, 0)
	hud.set_level(level_number, level_count, level_name)
	hud.set_ghosts(0, _max_ghosts)
	hud.set_hint(hint)

	exit.body_entered.connect(_on_exit_body_entered)
	_connect_hazards()
	_start_recording()


func _physics_process(_delta: float) -> void:
	if _respawning:
		return

	if _recording:
		_append_frame()

	if player.global_position.y > FALL_LIMIT:
		_die(true)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("give_up"):
		_die(false)
		get_viewport().set_input_as_handled()
		return

	# Under Main, Main owns R/Esc. When running a level directly with F6,
	# this level handles them itself.
	if get_tree().current_scene != self:
		return

	if event.is_action_pressed("reset"):
		get_tree().reload_current_scene()
	elif event.is_action_pressed("quit"):
		get_tree().quit()


func _start_recording() -> void:
	_rec_positions = PackedVector2Array()
	_rec_sprite_positions = PackedVector2Array()
	_rec_rotations = PackedFloat32Array()
	_rec_flips = PackedByteArray()
	_recording = true
	_append_frame()


func _append_frame() -> void:
	_rec_positions.append(player.global_position)
	_rec_sprite_positions.append(player_sprite.position)
	_rec_rotations.append(player_sprite.rotation)
	_rec_flips.append(1 if player_sprite.flip_h else 0)


func _die(is_fall: bool = false) -> void:
	if _respawning:
		return

	_respawning = true
	_death_pending = false
	_recording = false

	# Capture the exact final pose before respawning.
	_append_frame()

	var positions := _rec_positions.duplicate()
	var sprite_positions := _rec_sprite_positions.duplicate()
	var rotations := _rec_rotations.duplicate()
	var flips := _rec_flips.duplicate()

	var valid_frames := positions.size()
	if is_fall:
		valid_frames = _clip_to_room(positions, sprite_positions, rotations, flips)

	if valid_frames > 0 and _ghosts.size() < _max_ghosts:
		_spawn_ghost(positions, sprite_positions, rotations, flips)

	_reset_world()

	for ghost in _ghosts:
		ghost.reset_playback()

	player.respawn_at(spawn.global_position)
	_start_recording()
	_respawning = false


## Trims a fall recording to the last frame whose player centre is still inside
## the visible room, so the ghost ends at the room edge rather than off-screen.
func _clip_to_room(
	positions: PackedVector2Array,
	sprite_positions: PackedVector2Array,
	rotations: PackedFloat32Array,
	flips: PackedByteArray
) -> int:
	var last := -1
	for i in positions.size():
		var point := positions[i]
		if point.x >= 0.0 and point.x <= ROOM_SIZE.x \
				and point.y >= 0.0 and point.y <= ROOM_SIZE.y:
			last = i

	if last < 0:
		return 0

	var count := last + 1
	positions.resize(count)
	sprite_positions.resize(count)
	rotations.resize(count)
	flips.resize(count)
	return count


func _spawn_ghost(
	positions: PackedVector2Array,
	sprite_positions: PackedVector2Array,
	rotations: PackedFloat32Array,
	flips: PackedByteArray
) -> void:
	var ghost: Ghost = GHOST_SCENE.instantiate()
	ghost.solid_delay = ghost_solid_delay
	ghost.setup(positions, sprite_positions, rotations, flips)
	add_child(ghost)
	_ghosts.append(ghost)
	hud.set_ghosts(_ghosts.size(), _max_ghosts)


func _reset_world() -> void:
	for node in get_tree().get_nodes_in_group("resettable"):
		if is_ancestor_of(node) and node.has_method("reset_state"):
			node.call("reset_state")


func _connect_hazards() -> void:
	var callback := Callable(self, "_on_hazard_hit")
	for node in get_tree().get_nodes_in_group("hazards"):
		if is_ancestor_of(node) and not node.is_connected("player_hit", callback):
			node.connect("player_hit", callback)


func _on_hazard_hit() -> void:
	# body_entered fires while the physics server is flushing queries. Adding a
	# ghost body at that point is illegal, so defer the respawn by one frame.
	if _respawning or _death_pending:
		return
	_death_pending = true
	_die.call_deferred(false)


func _on_exit_body_entered(body: Node2D) -> void:
	if body is Player:
		exit.set_deferred("monitoring", false)
		completed.emit()
