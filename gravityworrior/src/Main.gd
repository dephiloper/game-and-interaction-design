extends Node2D

var planets: Array = []

func _ready() -> void:
	for child in get_children():
		var planet = child as Planet
		if planet:
			planets.append(planet)