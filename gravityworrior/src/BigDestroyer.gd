extends "res://src/Destroyer.gd"

func _get_damage_scale():
	return 2.0

func _get_max_health():
	return MAX_HEALTH * 1.5

func _get_healthbar_scale():
	return 1.5

func _get_healthbar_offset():
	return Vector2(-20, 0)