class_name Player
extends CharacterBody2D

@onready var _animation_player := $AnimationPlayer
@onready var _sprite2d := $Sprite2D
@onready var _front_ray_cast2d := $FrontRayCast2D
@onready var _back_ray_cast2d := $BackRayCast2D
@onready var _jump_buffer_timer := $JumpBufferTimer
@onready var _coyote_timer := $CoyoteTimer

@export var CROUCH_SPEED: float = 75.0
@export var WALK_SPEED: float = 400.0
@export var ACCELERATION: float = 50.0
@export var FRICTION: float = 75.0
@export var JUMP_VELOCITY: float = -500.0
@export var JUMP_RELEASE_VELOCITY: float = -60.0
@export var ADDITIONAL_FALL_GRAVITY: float = 400.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var GRAVITY: float = ProjectSettings.get_setting("physics/2d/default_gravity")

enum State {WALK, CROUCH, JUMP, FALL}

var state: State = State.WALK

# TODO: bools are very not DOD. Is there a better way to do this?
var buffered_jump: bool = false
var just_fell: bool = false

func _ready():
	pass

func _physics_process(delta: float):
	var last_state: State = state
	state = next_state(state)
	
	var direction: float = Input.get_axis("left", "right")
	
	match (state):
		State.WALK:
			apply_gravity(delta)
			apply_x_movement(WALK_SPEED, direction)
			if velocity.x != 0:
				_animation_player.play("walk")
			else:
				_animation_player.play("idle")
		State.CROUCH:
			apply_gravity(delta)
			apply_x_movement(CROUCH_SPEED, direction)
			if velocity.x != 0:
				_animation_player.play("crouch-walk")
			else:
				_animation_player.play("crouch-idle")
		State.JUMP:
			apply_gravity(delta)
			apply_x_movement(WALK_SPEED, direction)
			if last_state != State.JUMP:
				var jump_animation = "crouch-jump" if last_state == State.CROUCH else "jump"
				velocity.y = JUMP_VELOCITY
				_animation_player.play(jump_animation)
				_animation_player.seek(0.5, true)
			if !Input.is_action_pressed("jump") and velocity.y < JUMP_RELEASE_VELOCITY:
				velocity.y = JUMP_RELEASE_VELOCITY
		State.FALL:
			apply_gravity(delta)
			velocity.y += ADDITIONAL_FALL_GRAVITY * delta
			apply_x_movement(WALK_SPEED, direction)
			# TODO: Add all animation.
			pass

	move_and_slide()
	handle_sprite_flip(direction)
	
	# Emergency reset for now.
	if velocity.y > 2000:
		get_tree().reload_current_scene()

func next_state(current_state: State) -> State:
	var on_floor: bool = is_on_floor()
	var crouch: bool = Input.is_action_pressed("crouch")
	# TODO: Add coyote timing and pre jump
	if Input.is_action_just_pressed("jump"):
		_jump_buffer_timer.start()
		buffered_jump = true

	match current_state:
		State.JUMP:
			if velocity.y >= 0:
				return State.FALL
			return State.JUMP
		State.WALK:
			if !on_floor:
				_coyote_timer.start()
				just_fell = true
				return State.FALL
			if buffered_jump:
				buffered_jump = false
				return State.JUMP
			if crouch:
				return State.CROUCH
			return State.WALK
		State.CROUCH:
			if _front_ray_cast2d.is_colliding() or _back_ray_cast2d.is_colliding():
				# Something is blocking uncrouching. Must stay crouched.
				return State.CROUCH
			if !on_floor:
				_coyote_timer.start()
				just_fell = true
				return State.FALL
			if buffered_jump:
				buffered_jump = false
				return State.JUMP
			if !crouch:
				return State.WALK
			return State.CROUCH
		State.FALL:
			if just_fell and buffered_jump:
				buffered_jump = false
				return State.JUMP
			if on_floor:
				if crouch:
					return State.CROUCH
				else:
					return State.WALK
			return State.FALL
	# Defualt
	# TODO: If we add an IDLE switch this to idle.
	return State.WALK

func apply_x_movement(speed: float, direction: float):
	if direction:
		velocity.x = move_toward(velocity.x, direction * speed, ACCELERATION)
	else:
		velocity.x = move_toward(velocity.x, 0, FRICTION)

func apply_gravity(delta: float):
	if not is_on_floor():
		velocity.y += GRAVITY * delta

func handle_sprite_flip(direction: float):
	if velocity.x == 0:
		if direction < 0:
			_sprite2d.scale.x = -1
		elif direction > 0:
			_sprite2d.scale.x = 1
	if velocity.x < 0:
		_sprite2d.scale.x = -1
	elif velocity.x > 0:
		_sprite2d.scale.x = 1


func _on_jump_buffer_timer_timeout():
	buffered_jump = false


func _on_coyote_timer_timeout():
	just_fell = false
