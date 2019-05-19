extends KinematicBody2D

const SPEED: int = 10
const DRAG: float = 0.95
var _target: Player = null
var _velocity: Vector2 = Vector2.ZERO

func _ready() -> void:
	_target = GameManager.players[randi() % GameManager.players.size()]
	
func hit() -> void:
	queue_free()
	
func _physics_process(delta: float) -> void:
	look_at(_target.position)
	_velocity += (_target.position - position).normalized() * SPEED
	var collision = move_and_collide(_velocity * delta)
	if collision:
		_velocity = _velocity.bounce(collision.normal)
		if collision.collider.is_in_group("Player"):
			collision.collider.hit()
			queue_free()
	_velocity *= DRAG