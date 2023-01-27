extends CanvasLayer

@export var BASE_HEART_POSITION := Vector2(16, 16)
@export var HEART_X_OFFSET := 24

var heart_scene := preload("res://hud/heart.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	for _i in PlayerData.health:
		add_heart()
	
	PlayerData.health_changed.connect(_on_player_health_changed)

func add_heart():
	var i = get_child_count()
	var h = heart_scene.instantiate()
	h.position = BASE_HEART_POSITION
	h.position.x += i*HEART_X_OFFSET
	add_child(h)

func _on_player_health_changed(health: int):
	var hearts := get_child_count()
	if health < hearts:
		for i in range(health, hearts):
			var heart := get_child(i) as Heart
			heart.destroy()
	elif health > hearts:
		for i in range(hearts, health):
			add_heart()
