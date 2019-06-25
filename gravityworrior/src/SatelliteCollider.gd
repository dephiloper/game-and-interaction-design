extends StaticBody2D

func _ready():
	add_to_group("Satellite")

func hitSatellite(damage):
	GameManager.satellite.hit(damage)