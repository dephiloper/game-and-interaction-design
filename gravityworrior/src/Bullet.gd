extends KinematicBody2D

class_name Bullet

const GRAVITATIONAL_IMPACT_FACTOR: float = 7.5 # TODO tweak the gravity here! default: 3.0

var DRAG: float = 0.999 # TODO initial value 0.995 imo to low!
var _velocity = Vector2.ZERO
var _bounce_count: int = 0

var _damage: float
var _speed: float = 1200

func _get_drag():
	return DRAG

func _apply_hit(collision):
	if collision.collider.has_method("hit"):
		AudioPlayer.play_stream(AudioPlayer.enemy_hit, -8)
		if collision.collider.hit(_damage * GameManager.get_difficulty_damage_multiplier(), collision):
			queue_free()

func _physics_process(delta: float) -> void:
	_velocity += _calculate_gravitational_pull() * GRAVITATIONAL_IMPACT_FACTOR
	var collision = move_and_collide(_velocity * delta)
	if collision:
		_apply_hit(collision)
		if _bounce_count == 1:
			queue_free()
		_velocity = _velocity.bounce(collision.normal)
		_bounce_count += 1
	_velocity *= _get_drag()
	look_at(position + _velocity)
	
	
	if not $VisibilityNotifier2D.is_on_screen():
		queue_free()
		
func init(dir: Vector2, damage: float, bullet_size_multiplier: float = 1.0, attack_speed_multiplier: float = 1.0):
	add_to_group("Bullet")
	_speed *= attack_speed_multiplier
	_damage = damage
	_velocity = dir * _speed
	scale *= bullet_size_multiplier
	
func _calculate_gravitational_pull() -> Vector2:
	var pull: Vector2 = Vector2()
	for planet in GameManager.planets:
		var distance: float = position.distance_squared_to(planet.position)
		var force: float = planet.gravity / distance
		pull += (planet.position - position).normalized() * force
		
	return pull