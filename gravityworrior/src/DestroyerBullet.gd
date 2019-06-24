extends "res://src/Bullet.gd"

func _set_collision_mask():
	collision_mask = 1 + 2 + 8

func _get_drag():
	return 1.0

func _apply_hit(collision):
	if collision.collider.has_method("hit") and collision.collider.is_in_group("Player"):
		collision.collider.hit(_damage)
	queue_free()

func _calculate_gravitational_pull():
	return Vector2.ZERO