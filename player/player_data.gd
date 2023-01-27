extends Node

var max_health: int = 3
var health: int = max_health

signal health_changed(new_health)

func change_health(delta: int):
	health += delta
	health = maxi(health, 0)
	health = mini(health, max_health)
	health_changed.emit(health)

func reset_health():
	health = max_health
	health_changed.emit(health)
