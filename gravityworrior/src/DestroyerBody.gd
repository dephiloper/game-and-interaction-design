extends KinematicBody2D

signal got_hit(damage)

func hit(damage: float):
	emit_signal("got_hit", damage)