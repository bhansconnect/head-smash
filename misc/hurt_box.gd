class_name HurtBox
extends Area2D

signal take_damage


func _on_area_entered(hit_box: HitBox):
	if hit_box == null:
		return
	
	emit_signal("take_damage", hit_box.damage)
