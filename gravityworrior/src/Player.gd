extends KinematicBody2D

var velocity = Vector2()
var closest_planet: Planet
var is_on_planet: bool = false
const MOVEMENT_SPEED: int = 20
const MAX_SPEED: int = 200

class_name Player

func _physics_process(delta: float) -> void:
	velocity += _calculate_player_movement()
	
	if is_on_planet == true:
		velocity *= 0.9
		var x = closest_planet.position - position
		velocity = move_and_slide_with_snap(velocity, x, -x)
		velocity = velocity.slide(x.normalized())
		velocity = velocity.slide(-x.normalized())
	else:
		velocity *= 0.99
		var collision = move_and_collide(velocity * delta)
		if collision:
			is_on_planet = true
		else:
			velocity += _calculate_gravitational_pull()
	
func _calculate_player_movement() -> Vector2:
	var speed = Vector2()
	if Input.is_action_pressed("ui_left"):
		speed.x -= MOVEMENT_SPEED
	if Input.is_action_pressed("ui_right"):
		speed.x += MOVEMENT_SPEED
	if Input.is_action_pressed("ui_up"):
		speed.y -= MOVEMENT_SPEED
	if Input.is_action_pressed("ui_down"):
		speed.y += MOVEMENT_SPEED
	speed.normalized()
	
	if Input.is_action_pressed("ui_accept"):
		print("jump")
		is_on_planet = false
		speed *= 2
	return speed
		
func _calculate_gravitational_pull() -> Vector2:
	var pull = Vector2()
	var closest_distance: float = INF
	for planet in GameManager.planets:
		var distance: float = position.distance_squared_to(planet.position)
		if distance < closest_distance:
			closest_distance = distance
			closest_planet = planet
		
		var force: float = planet.gravity / distance
		pull += (planet.position - position).normalized() * force
		
	return pull
		
	