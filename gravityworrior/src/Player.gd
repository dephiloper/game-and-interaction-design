extends KinematicBody2D

const MOVEMENT_SPEED: int = 10
const JUMP_SPEED_MULTIPLIER: float = 3.0

const ON_PLANET_DRAG: float = 0.9
const ON_PLANET_SPEED_MULTIPLIER: float = 2.0
const OFF_PLANET_DRAG: float = 0.98
const OFF_PLANET_MAX_VELOCITY: int = 300

var velocity = Vector2()
var closest_planet: Planet
var is_on_planet: bool = false
var is_boosting: bool = false

class_name Player

func _physics_process(delta: float) -> void:
	if is_on_planet == true:
		velocity += _calculate_player_movement()
		velocity *= ON_PLANET_DRAG
		var diff: Vector2 = closest_planet.position - position
		velocity = move_and_slide_with_snap(velocity, diff, -diff)
		# velocity = velocity.slide(diff.normalized())
		# velocity = velocity.slide(-diff.normalized())
	else:
		velocity += _calculate_player_movement()
		velocity *= OFF_PLANET_DRAG
		var collision = move_and_collide(velocity * delta)
		if collision:
			is_on_planet = true
		else:
			velocity += _calculate_gravitational_pull()
			
		var max_velocity: float = OFF_PLANET_MAX_VELOCITY
		if is_boosting:
			max_velocity *= JUMP_SPEED_MULTIPLIER
		velocity = velocity.clamped(max_velocity)
	
func _calculate_player_movement() -> Vector2:
	var horizontal: float = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	var vertical: float = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	is_boosting = false
	
	var movement_speed: float = MOVEMENT_SPEED
	if is_on_planet:
		movement_speed *= ON_PLANET_SPEED_MULTIPLIER
		
	var speed: Vector2 = Vector2(horizontal, vertical).normalized() * movement_speed
	
	if Input.is_action_pressed("ui_accept"):
		is_on_planet = false
		is_boosting = true
		speed *= JUMP_SPEED_MULTIPLIER
	return speed
		
func _calculate_gravitational_pull() -> Vector2:
	var pull: Vector2 = Vector2()
	var closest_distance: float = INF
	for planet in GameManager.planets:
		var distance: float = position.distance_squared_to(planet.position)
		if distance < closest_distance:
			closest_distance = distance
			closest_planet = planet
		
		var force: float = planet.gravity / distance
		pull += (planet.position - position).normalized() * force
		
	return pull
		
	