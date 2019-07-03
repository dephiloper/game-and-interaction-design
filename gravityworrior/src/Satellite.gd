extends Node2D

var HealthBarScene = preload("res://src/HealthBar.tscn")

class_name Satellite

const SATELLITE_IN_PLANET_Y_OFFSET = 1.5

var health: float = 100
var max_health: float = 100
var _health_bar
var _heal_radius: float
var _closest_planet: Planet
var _life_regeneration_value: float = 0.1
var _heal_area_position: Vector2
var _containing_players: Array = []

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
	
	_closest_planet = get_closest_planet()
	_heal_area_position = closest_planet.position - global_position
	_heal_radius = _closest_planet.radius + 40
	$HealArea.position = _heal_area_position
	$HealArea/CollisionShape2D.shape.radius = _heal_radius
	$HealTimer.connect("timeout", self, "_on_HealTimer_timeout")
	$HealArea.connect("body_entered", self, "_on_HealArea_body_entered")
	$HealArea.connect("body_exited", self, "_on_HealArea_body_exited")
	
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
	
func _draw() -> void:
	draw_circle(_heal_area_position, _heal_radius, Color(0, 1, 0, 0.3))

func _on_HealArea_body_entered(body: PhysicsBody2D) -> void:
	if body.is_in_group("Player"):
		var player = body as Player
		player.is_healing = true
		_containing_players.append(player)
		
func _on_HealArea_body_exited(body: PhysicsBody2D) -> void:
	if body.is_in_group("Player"):
		var player = body as Player
		player.is_healing = false
		_containing_players.erase(player)
		
func _on_HealTimer_timeout() -> void:
	for player in _containing_players:
		player.heal(_life_regeneration_value)