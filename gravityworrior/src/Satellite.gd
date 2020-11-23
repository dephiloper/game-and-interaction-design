extends Node2D

var HealthBarScene = preload("res://src/HealthBar.tscn")

class_name Satellite

const SATELLITE_IN_PLANET_Y_OFFSET = 1.7

const MAX_HEALTH = 1000
var health: float = 1000
var _health_bar
var _heal_radius: float
var _pulsating_radius: float
var _closest_planet: Planet
var _life_regeneration_value: float = 5
var _heal_area_position: Vector2
var _containing_players: Array = []
var _elapsed_time: float
var _life_regeneration_color: Color = Color(0, 0.67, 0.4, 0.25)

signal game_over

func _init() -> void:
	add_to_group("Satellite")
	GameManager.set_satellite(self)

func is_dead():
	return health <= 0

func get_max_health():
	return MAX_HEALTH

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
	
func _process(delta: float) -> void:
	if GameManager.current_game_state != GameManager.GameState.Fight: return
	_elapsed_time += delta
	_pulsating_radius = sin(_elapsed_time) * _heal_radius
	update()

func damage(damage: float) -> void:
	health = max(health - damage, 0)
	
	$HitTween.interpolate_property($Sprite, "modulate", 
	Color(1, 1, 1, 1), Color(1, 0, 0, 1), 0.1, Tween.TRANS_LINEAR, Tween.EASE_IN)

	$HitTween.interpolate_property($Sprite, "modulate", Color(1, 0, 0, 1), 
	Color(1, 1, 1, 1), 0.1, Tween.TRANS_LINEAR, Tween.EASE_IN, 0.1)
	
	$HitTween.start()
	
	GameManager.trigger_camera_shake()
	
	if health < MAX_HEALTH * 0.25:
		add_child(WarnSignal.new())
	
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
	draw_circle(_heal_area_position, _heal_radius, _life_regeneration_color)
	draw_circle(_heal_area_position, _pulsating_radius, _life_regeneration_color)
	

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
