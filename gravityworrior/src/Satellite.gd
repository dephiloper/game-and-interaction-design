extends Node2D

var HealthBarScene = preload("res://src/HealthBar.tscn")

class_name Satellite

const SATELLITE_IN_PLANET_Y_OFFSET = 1

var health: float = 100
var max_health: float = 100
var _health_bar

signal game_over

func _init() -> void:
	GameManager.set_satellite(self)

func is_dead():
	return health <= 0

func _get_max_health():
	return max_health

func _ready() -> void:
	var closest_planet = get_closest_planet()
	position = closest_planet.position
	position.y -= closest_planet.radius - SATELLITE_IN_PLANET_Y_OFFSET

	_health_bar = HealthBarScene.instance()
	_health_bar.transform = _health_bar.transform.scaled(Vector2(2.0, 2.0))
	_health_bar.color = Color.green
	_health_bar.init(self, Vector2(-25.0, 0.0))
	get_parent().call_deferred("add_child", _health_bar)

	_health_bar.update()

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