class_name Player
extends CharacterBody2D

@onready var _animation_player := $AnimationPlayer
@onready var _sprite2d := $Sprite2D
@onready var _front_ray_cast2d := $FrontRayCast2D
@onready var _back_ray_cast2d := $BackRayCast2D
@onready var _jump_buffer_timer := $JumpBufferTimer
@onready var _coyote_timer := $CoyoteTimer
@onready var _knockback_timer := $KnockbackTimer
@onready var _reset_timer := $ResetTimer

@export var CRAWL_SPEED: float = 75.0
@export var RUN_SPEED: float = 300.0
@export var KNOCKBACK_SPEED: float = 500.0
@export var KNOCKUP_MIN: float = 0.5
@export var ACCELERATION: float = 1800.0
@export var ONGROUND_FRICTION: float = 2000.0
@export var INAIR_FRICTION: float = 1000.0
@export var JUMP_VELOCITY: float = -500.0
@export var JUMP_RELEASE_VELOCITY: float = -60.0
@export var ADDITIONAL_FALL_GRAVITY: float = 400.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var GRAVITY: float = ProjectSettings.get_setting("physics/2d/default_gravity")

enum State {RUN, CRAWL, JUMP, FALL, KNOCKBACK}

var state: State = State.RUN

# TODO: bools are very not DOD. Is there a better way to do this?
var buffered_jump: bool = false
var just_fell: bool = false
var apply_knockback: bool = false

func _ready():
	PlayerData.health_changed.connect(_on_health_changed)

func _physics_process(delta: float):
	var last_state: State = state
	state = next_state(state)
	
	var direction: float = Input.get_axis("left", "right")
	
	match (state):
		State.RUN:
			apply_gravity(delta)
			apply_x_movement(delta, RUN_SPEED, direction, ONGROUND_FRICTION)
			var flipped_dir := signf(velocity.x) * signf(direction) == -1
			var matched_dir := signf(velocity.x) * signf(direction) == 1
			if flipped_dir:
				_animation_player.play("turn")
				_animation_player.queue("run")
			if velocity.x != 0:
				if matched_dir || _animation_player.current_animation != "turn":
					_animation_player.play("run")
			else:
				_animation_player.play("standing-idle")
		State.CRAWL:
			apply_gravity(delta)
			apply_x_movement(delta, CRAWL_SPEED, direction, ONGROUND_FRICTION)
			if velocity.x != 0:
				_animation_player.play("crawl")
			else:
				_animation_player.play("crawl-idle")
		State.JUMP:
			apply_gravity(delta)
			apply_x_movement(delta, RUN_SPEED, direction, INAIR_FRICTION)
			if last_state != State.JUMP:
				var jump_animation = "crawl-jump" if last_state == State.CRAWL else "jump"
				velocity.y = JUMP_VELOCITY
				_animation_player.play(jump_animation)
				_animation_player.seek(0.5, true)
				_animation_player.queue("up-air")
			if !Input.is_action_pressed("jump") and velocity.y < JUMP_RELEASE_VELOCITY:
				velocity.y = JUMP_RELEASE_VELOCITY
		State.FALL:
			_animation_player.play("falling")
			apply_gravity(delta)
			velocity.y += ADDITIONAL_FALL_GRAVITY * delta
			apply_x_movement(delta, RUN_SPEED, direction, INAIR_FRICTION)
			# TODO: Add all animation.
			pass
		State.KNOCKBACK:
			_animation_player.play("falling")
			apply_gravity(delta)

	move_and_slide()
	if state != State.KNOCKBACK && _animation_player.current_animation != "turn":
		handle_sprite_flip(direction)
	
	# Emergency reset for now.
	if velocity.y > 2000:
		PlayerData.reset_health()
		get_tree().reload_current_scene()

func next_state(current_state: State) -> State:
	var on_floor: bool = is_on_floor()
	var crawl: bool = Input.is_action_pressed("crawl")
	if Input.is_action_just_pressed("jump"):
		_jump_buffer_timer.start()
		buffered_jump = true

	if apply_knockback:
		return State.KNOCKBACK

	match current_state:
		State.JUMP:
			if velocity.y >= 0:
				return State.FALL
			return State.JUMP
		State.RUN:
			if !on_floor:
				_coyote_timer.start()
				just_fell = true
				return State.FALL
			if buffered_jump:
				buffered_jump = false
				return State.JUMP
			if crawl:
				return State.CRAWL
			return State.RUN
		State.CRAWL:
			if _front_ray_cast2d.is_colliding() or _back_ray_cast2d.is_colliding():
				# Something is blocking standing up. Must stay crawling.
				return State.CRAWL
			if !on_floor:
				_coyote_timer.start()
				just_fell = true
				return State.FALL
			if buffered_jump:
				buffered_jump = false
				return State.JUMP
			if !crawl:
				return State.RUN
			return State.CRAWL
		State.FALL, State.KNOCKBACK:
			if just_fell and buffered_jump:
				buffered_jump = false
				return State.JUMP
			if on_floor:
				if crawl:
					return State.CRAWL
				else:
					return State.RUN
			return State.FALL
	# Defualt
	# TODO: If we add an IDLE switch this to idle.
	return State.RUN

func apply_x_movement(delta: float, speed: float, direction: float, friction: float):
	if direction:
		velocity.x = move_toward(velocity.x, direction * speed, ACCELERATION * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, friction * delta)

func apply_gravity(delta: float):
	if not is_on_floor():
		velocity.y += GRAVITY * delta

func handle_sprite_flip(direction: float):
	if velocity.x == 0 and direction == 0:
		# No data, don't update.
		return

	_sprite2d.flip_h = (velocity.x == 0 and direction < 0) or velocity.x < 0


func _on_jump_buffer_timer_timeout():
	buffered_jump = false


func _on_coyote_timer_timeout():
	just_fell = false


func _on_knockback_timer_timeout():
	apply_knockback = false


func _on_take_damage(damage: int, hit_position: Vector2):
	if apply_knockback:
		# already in knockback. ignore
		return

	var knockback_dir := hit_position.direction_to(global_position)
	knockback_dir.y = minf(-KNOCKUP_MIN, knockback_dir.y)
	velocity = knockback_dir.normalized() * KNOCKBACK_SPEED
	apply_knockback = true
	
	var knockback_tween := get_tree().create_tween()
	_sprite2d.modulate = Color(1,0,0,1)
	knockback_tween.parallel().tween_property(_sprite2d, "modulate", Color(1,1,1,1), _knockback_timer.wait_time)
	
	_knockback_timer.start()
	
	PlayerData.change_health(-1*damage)


func _on_health_changed(new_health: int):
	if new_health == 0:
		# Trap the player in knockback and reset the game.
		_knockback_timer.stop()
		_reset_timer.start()


func _on_reset_timer_timeout():
	# TODO: Proper game over and restart.
	PlayerData.reset_health()
	get_tree().reload_current_scene()
