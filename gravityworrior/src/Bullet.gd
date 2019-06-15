extends KinematicBody2D

class_name Bullet

const GRAVITATION_IMPACT_FACTOR: float = 3.0

var DRAG: float = 0.995
var _velocity = Vector2.ZERO
var _bounce_count: int = 0

var _damage: float = 10
var _radius: float = 6
var _speed: float = 1000

var aoe: bool = false

func _draw() -> void:
	draw_circle(Vector2(0,0), _radius, Color.black)
	draw_circle(Vector2(0,0), _radius-2, Color.yellow)
	
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
		
func init(dir: Vector2, damage_buff: float, base_damage: float, bullet_size: float, bullet_size_multiplier: float = 1.0, bullet_speed: float = 10, attack_speed_multiplier: float = 1.0, aoe: bool = false, gravity_affection: float = 10):
	_speed *= attack_speed_multiplier * bullet_speed
	_radius = bullet_size_multiplier * bullet_size
	_velocity = dir * _speed
	_damage = damage_buff  + base_damage
	#DRAG = gravity_affection
	#aoe = false
	($CollisionShape2D.shape as CircleShape2D).radius = _radius
	
func _calculate_gravitational_pull() -> Vector2:
	var pull: Vector2 = Vector2()
	for planet in GameManager.planets:
		var distance: float = position.distance_squared_to(planet.position)
		var force: float = planet.gravity / distance
		pull += (planet.position - position).normalized() * force
		
	return pull