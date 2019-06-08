extends KinematicBody2D

class_name Bullet

const RADIUS: int = 6
const SPEED: int = 1000
const GRAVITATION_IMPACT_FACTOR: float = 3.0
const DRAG: float = 0.995

var _velocity = Vector2.ZERO
var _bounce_count: int = 0
var _damage: float = 10.0

func _draw() -> void:
	draw_circle(Vector2(0,0), RADIUS, Color.black)
	draw_circle(Vector2(0,0), RADIUS-2, Color.yellow)
	
func _physics_process(delta: float) -> void:
	_velocity += _calculate_gravitational_pull() * GRAVITATION_IMPACT_FACTOR
	var collision = move_and_collide(_velocity * delta)
	if collision:
		if collision.collider.has_method("hit"):
			collision.collider.hit(_damage)
			queue_free()
		if _bounce_count == 1:
			queue_free()
		_velocity = _velocity.bounce(collision.normal)
		_bounce_count += 1
	_velocity *= DRAG
		
	if not $VisibilityNotifier2D.is_on_screen():
		queue_free()
		
func init(dir: Vector2, damage: float):
	_velocity = dir * SPEED
	_damage = damage
	($CollisionShape2D.shape as CircleShape2D).radius = RADIUS
	
func _calculate_gravitational_pull() -> Vector2:
	var pull: Vector2 = Vector2()
	for planet in GameManager.planets:
		var distance: float = position.distance_squared_to(planet.position)
		var force: float = planet.gravity / distance
		pull += (planet.position - position).normalized() * force
		
	return pull