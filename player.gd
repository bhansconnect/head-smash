extends CharacterBody2D

@onready var _animation_player = $AnimationPlayer
@onready var _sprite2d = $Sprite2D

@export var WALK_SPEED = 150.0
@export var RUN_SPEED = 400.0
@export var JUMP_VELOCITY = -400.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready():
	pass

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta

	var crouching = Input.is_action_pressed("crouch")
	var jump_animation = "crouch-jump" if crouching else "jump"
	var move_animation = "crouch-walk" if crouching else "run"
	var idle_animation = "crouch-idle" if crouching else "idle"
	var speed = WALK_SPEED if crouching else RUN_SPEED
	
	var direction = Input.get_axis("left", "right")
	if direction:
		velocity.x = direction * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)

	move_and_slide()
	
	
	if velocity.x < 0:
		_sprite2d.scale.x = -1
	elif velocity.x > 0:
		_sprite2d.scale.x = 1
	
	if is_on_floor():
		if Input.is_action_pressed("jump"):
			velocity.y = JUMP_VELOCITY
			_animation_player.play(jump_animation)
			_animation_player.seek(0.5, true)
		elif velocity.x != 0:
			_animation_player.play(move_animation)
		else:
			_animation_player.play(idle_animation)
