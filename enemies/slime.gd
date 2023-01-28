extends CharacterBody2D

@onready var _animation_player := $AnimationPlayer
@onready var _sprite2d := $Sprite2D
@onready var _collision_shape2d := $CollisionShape2D
@onready var _hitbox := $HitBox

@export var DAMAGE: int = 1
@export var SPEED: float = 50.0
@export var ANIMATION_SPEED: float = 1.0
@export var START_FLIPPED: bool = false

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

var direction: float = 1.0

func _ready():
	$HitBox.damage = DAMAGE
	if START_FLIPPED:
		flip()
	_animation_player.play("move")
	_animation_player.playback_speed = ANIMATION_SPEED

func _physics_process(delta: float):
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta

	velocity.x = direction * SPEED

	move_and_slide()
	
	if velocity.x == 0:
		# Blocked by a wall. Flip direction.
		flip()
		
func flip():
	direction *= -1
	_sprite2d.scale.x *= -1
	_collision_shape2d.position.x *= -1
	_hitbox.position.x *= -1
