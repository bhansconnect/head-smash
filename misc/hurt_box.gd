class_name HurtBox
extends Area2D

signal take_damage(damage, position)


func _on_area_entered(hit_box: HitBox):
	if hit_box == null:
		return
	
	take_damage.emit(hit_box.damage, hit_box.global_position)
