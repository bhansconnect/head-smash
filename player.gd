extends CharacterBody2D

@onready var _animation_player = $AnimationPlayer
@onready var _sprite2d = $Sprite2D
@onready var _front_ray_cast2d = $FrontRayCast2D
@onready var _back_ray_cast2d = $BackRayCast2D

@export var CROUCH_SPEED = 75.0
@export var WALK_SPEED = 400.0
@export var ACCELERATION = 100.0
@export var FRICTION = 200.0
@export var JUMP_VELOCITY = -400.0

enum State {WALK, CROUCH, JUMP, FALL}

var state = State.WALK

# Get the gravity from the project settings to be synced with RigidBody nodes.
var GRAVITY = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready():
	pass

func _physics_process(delta):
	var last_state = state
	state = next_state(state)
	
	var direction = Input.get_axis("left", "right")
	
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
		State.FALL:
			apply_gravity(delta)
			apply_x_movement(WALK_SPEED, direction)
			# TODO: Add all animation.
			pass

	move_and_slide()
	handle_sprite_flip(direction)
	
	# Emergency reset for now.
	if velocity.y > 2000:
		get_tree().reload_current_scene()

func next_state(current_state):
	var on_floor = is_on_floor()
	var crouch = Input.is_action_pressed("crouch")
	# TODO: Add coyote timing and pre jump
	var jump = Input.is_action_pressed("jump")
	match current_state:
		State.JUMP:
			if velocity.y >= 0:
				return State.FALL
			return State.JUMP
		State.WALK:
			if !on_floor:
				return State.FALL
			if jump:
				return State.JUMP
			if crouch:
				return State.CROUCH
			return State.WALK
		State.CROUCH:
			if _front_ray_cast2d.is_colliding() or _back_ray_cast2d.is_colliding():
				# Something is blocking uncrouching. Must stay crouched.
				return State.CROUCH
			if !on_floor:
				return State.FALL
			if jump:
				return State.JUMP
			if !crouch:
				return State.WALK
			return State.CROUCH
		State.FALL:
			if on_floor:
				if crouch:
					return State.CROUCH
				else:
					return State.WALK
			return State.FALL

func apply_x_movement(speed, direction):
	if direction:
		velocity.x = move_toward(velocity.x, direction * speed, ACCELERATION)
	else:
		velocity.x = move_toward(velocity.x, 0, FRICTION)

func apply_gravity(delta):
	if not is_on_floor():
		velocity.y += GRAVITY * delta

func handle_sprite_flip(direction):
	if velocity.x == 0:
		if direction < 0:
			_sprite2d.scale.x = -1
		elif direction > 0:
			_sprite2d.scale.x = 1
	if velocity.x < 0:
		_sprite2d.scale.x = -1
	elif velocity.x > 0:
		_sprite2d.scale.x = 1
