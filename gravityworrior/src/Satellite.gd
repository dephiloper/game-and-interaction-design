extends Node2D

class_name Satellite

var health: float = 100
var max_health: float = 100

signal game_over

func _init() -> void:
	GameManager.set_satellite(self)

func _ready() -> void:
	var closest_planet = get_closest_planet()
	position = closest_planet.position
	position.y -= closest_planet.radius
	$"/root/Main/UILayer/SatteliteBar".adjust_position(position)

func hit(damage: float) -> void:
	health = max(health - damage, 0)
	if health <= 0:
		emit_signal("game_over")
	
func get_closest_planet() -> Planet:
	var closest_distance: float = INF
	var closest_planet: Planet
	for planet in GameManager.planets:
		var distance: float = position.distance_squared_to(planet.position)
		if distance < closest_distance:
			closest_distance = distance
			closest_planet = planet
	
	return closest_planet