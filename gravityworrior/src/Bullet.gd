extends KinematicBody2D

class_name Bullet

const RADIUS: int = 6
const SPEED: int = 1000

var _velocity = Vector2.ZERO
var _bounce_count: int = 0

func _draw() -> void:
	draw_circle(Vector2(0,0), RADIUS, Color.black)
	draw_circle(Vector2(0,0), RADIUS-2, Color.yellow)
	
func _physics_process(delta: float) -> void:
	var collision = move_and_collide(_velocity * delta)
	if collision:
		if collision.collider.has_method("hit"):
			collision.collider.hit()
			queue_free()
		if _bounce_count == 3:
			queue_free()
		_velocity = _velocity.bounce(collision.normal)
		_bounce_count += 1
		
	if not $VisibilityNotifier2D.is_on_screen():
		queue_free()
		
func init(dir: Vector2):
	_velocity = dir * SPEED
	($CollisionShape2D.shape as CircleShape2D).radius = RADIUS