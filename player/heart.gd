class_name Heart
extends Sprite2D

@onready var _animation_player := $AnimationPlayer

func _ready():
	_animation_player.play("gain")
	_animation_player.queue("idle")


func destroy():
	_animation_player.play("lose")
