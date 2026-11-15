class_name Player
extends CharacterBody2D

## Celeste-inspired platformer controller.
## Every movement value is exported so the feel can be tuned in the Inspector.

@export_group("Run")
@export var max_run_speed: float = 180.0
@export var run_acceleration: float = 2000.0
@export var run_deceleration: float = 2400.0
@export_range(0.0, 1.0, 0.05) var air_control: float = 0.65

@export_group("Jump")
@export var jump_speed: float = -300.0
@export var gravity: float = 1500.0
@export var max_fall_speed: float = 320.0
@export_range(0.0, 1.0, 0.05) var jump_cut_multiplier: float = 0.5
@export var apex_gravity_multiplier: float = 0.5
@export var apex_gravity_threshold: float = 40.0
@export var coyote_time: float = 0.10
@export var jump_buffer_time: float = 0.10

@export_group("Dash")
@export var dash_speed: float = 480.0
@export var dash_time: float = 0.15
@export var dash_freeze_time: float = 0.05
@export var dash_end_speed: float = 320.0
@export var dashes_per_airtime: int = 1

@export_group("Wall")
@export var wall_slide_speed: float = 60.0
@export var wall_grab_slide_speed: float = 20.0
@export var wall_jump_horizontal_speed: float = 200.0
@export var wall_jump_vertical_speed: float = -300.0
@export var wall_jump_lockout: float = 0.12
@export var scamper_speed: float = 160.0
@export var scamper_distance: float = 34.0
@export var wall_stick_speed: float = 30.0

var facing: int = 1
var dashes_left: int = 1
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var wall_jump_lock_timer: float = 0.0
var scamper_left: float = 0.0

var _is_dashing: bool = false
var _dash_timer: float = 0.0
var _dash_freeze_timer: float = 0.0
var _dash_direction: Vector2 = Vector2.ZERO

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	dashes_left = dashes_per_airtime
	scamper_left = scamper_distance


func _physics_process(delta: float) -> void:
	if _dash_freeze_timer > 0.0:
		_dash_freeze_timer -= delta
		velocity = Vector2.ZERO
		return

	if _is_dashing:
		_process_dash(delta)
		return

	coyote_timer = maxf(coyote_timer - delta, 0.0)
	jump_buffer_timer = maxf(jump_buffer_timer - delta, 0.0)
	wall_jump_lock_timer = maxf(wall_jump_lock_timer - delta, 0.0)

	if is_on_floor():
		coyote_timer = coyote_time
		dashes_left = dashes_per_airtime
		scamper_left = scamper_distance

	var input_axis := Input.get_axis("move_left", "move_right")
	if input_axis != 0.0 and wall_jump_lock_timer <= 0.0:
		facing = 1 if input_axis > 0.0 else -1
	if wall_jump_lock_timer <= 0.0:
		_face_direction(Vector2(float(facing), 0.0))

	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= jump_cut_multiplier

	if Input.is_action_just_pressed("dash") and dashes_left > 0:
		_start_dash()
		return

	var wall_normal := _probe_wall()
	var touching_wall := wall_normal != Vector2.ZERO
	var airborne_wall := touching_wall and not is_on_floor()
	var wall_lock_active := wall_jump_lock_timer > 0.0

	if jump_buffer_timer > 0.0:
		if is_on_floor() or coyote_timer > 0.0:
			_do_jump()
		elif airborne_wall and not wall_lock_active:
			_do_wall_jump(wall_normal)

	if not wall_lock_active:
		var target := input_axis * max_run_speed
		var acceleration := run_acceleration if input_axis != 0.0 else run_deceleration
		if not is_on_floor():
			acceleration *= air_control
		velocity.x = move_toward(velocity.x, target, acceleration * delta)

	if not is_on_floor():
		var active_gravity := gravity
		if Input.is_action_pressed("jump") and absf(velocity.y) < apex_gravity_threshold:
			active_gravity *= apex_gravity_multiplier
		velocity.y = minf(velocity.y + active_gravity * delta, max_fall_speed)

	if touching_wall and not wall_lock_active:
		var press_into_wall := input_axis * -wall_normal.x > 0.0
		var grab_held := Input.is_action_pressed("grab")
		var up_held := Input.is_action_pressed("move_up")

		if grab_held and up_held and scamper_left > 0.0:
			velocity.y = -scamper_speed
			velocity.x = -wall_normal.x * wall_stick_speed
			scamper_left = maxf(scamper_left - scamper_speed * delta, 0.0)
			_face_direction(Vector2(0.0, -1.0))
		elif grab_held and velocity.y >= 0.0:
			velocity.y = minf(velocity.y, wall_grab_slide_speed)
			velocity.x = -wall_normal.x * wall_stick_speed
			_face_direction(Vector2(-wall_normal.x, 0.0))
		elif press_into_wall and velocity.y > 0.0 and not is_on_floor():
			velocity.y = minf(velocity.y, wall_slide_speed)

	move_and_slide()


func _do_jump() -> void:
	velocity.y = jump_speed
	coyote_timer = 0.0
	jump_buffer_timer = 0.0


func _do_wall_jump(wall_normal: Vector2) -> void:
	velocity.x = wall_normal.x * wall_jump_horizontal_speed
	velocity.y = wall_jump_vertical_speed
	facing = 1 if wall_normal.x > 0.0 else -1
	_face_direction(Vector2(wall_normal.x, -1.0))
	wall_jump_lock_timer = wall_jump_lockout
	coyote_timer = 0.0
	jump_buffer_timer = 0.0


func _start_dash() -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction == Vector2.ZERO:
		direction = Vector2(float(facing), 0.0)

	_dash_direction = direction.normalized()
	if absf(_dash_direction.x) > 0.01:
		facing = 1 if _dash_direction.x > 0.0 else -1
	_face_direction(_dash_direction)

	dashes_left -= 1
	_is_dashing = true
	_dash_timer = dash_time
	_dash_freeze_timer = dash_freeze_time
	velocity = Vector2.ZERO
	sprite.modulate = Color(0.65, 0.85, 1.0, 1.0)


func _process_dash(delta: float) -> void:
	_dash_timer -= delta
	velocity = _dash_direction * dash_speed

	if _dash_timer <= 0.0:
		_is_dashing = false
		velocity = _dash_direction * dash_end_speed
		sprite.modulate = Color.WHITE

	move_and_slide()


## Points the cat's long axis along [param direction]. The cat is horizontal
## (on all fours) by default; dashes, scampering, and wall jumps rotate it.
func _face_direction(direction: Vector2) -> void:
	if sprite == null or direction == Vector2.ZERO:
		return

	var normalized := direction.normalized()
	var angle := normalized.angle()
	if normalized.x < 0.0:
		sprite.flip_h = true
		sprite.rotation = wrapf(angle + PI, -PI, PI)
	else:
		sprite.flip_h = false
		sprite.rotation = angle

	# The 20x12 on-all-fours sprite is shorter than the 12x20 hitbox. Lower it
	# while horizontal so its feet sit on the bottom of the hitbox.
	var ground_offset := 4.0 if absf(normalized.y) < 0.01 else 0.0
	sprite.position = Vector2(0.0, ground_offset)


## Called by the level on respawn/death. Clears all transient movement state.
func respawn_at(target: Vector2) -> void:
	global_position = target
	velocity = Vector2.ZERO
	_is_dashing = false
	_dash_timer = 0.0
	_dash_freeze_timer = 0.0
	_dash_direction = Vector2.ZERO
	coyote_timer = 0.0
	jump_buffer_timer = 0.0
	wall_jump_lock_timer = 0.0
	dashes_left = dashes_per_airtime
	scamper_left = scamper_distance
	facing = 1
	sprite.modulate = Color.WHITE
	_face_direction(Vector2.RIGHT)


## Returns the normal of a wall the player is touching, or Vector2.ZERO.
## is_on_wall() only updates after movement, so a short probe makes grabbing and
## scampering work even when standing still next to a wall.
func _probe_wall() -> Vector2:
	if is_on_wall():
		var normal := get_wall_normal()
		if absf(normal.x) > 0.5:
			return normal

	for direction in [-1.0, 1.0]:
		var collision := move_and_collide(Vector2(direction * 2.0, 0.0), true)
		if collision != null:
			var normal := collision.get_normal()
			if absf(normal.x) > 0.5:
				return normal

	return Vector2.ZERO
