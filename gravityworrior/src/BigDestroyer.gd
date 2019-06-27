extends "res://src/Destroyer.gd"

const SHOOT_DAMAGE = 5
const SHOOT_DEVIATION = 0.2
const NUM_SHOOTS = 2
const SHOOT_SPEED = 0.25

var _destroyer_bullet_scene = preload("res://src/DestroyerBullet.tscn")

func _get_damage_scale():
	return 2.0

func _get_max_health():
	return MAX_HEALTH * 3.5

func _get_healthbar_scale():
	return 1.5

func _connect_timer():
	$ShootTimer.connect("timeout", self, "_shoot_attack")

func _get_healthbar_offset():
	return Vector2(-20, 0)

func _get_squared_attack_range():
	return SQUARED_ATTACK_RANGE * 0.8

func _shoot(direction):
	var bullet: Bullet = _destroyer_bullet_scene.instance()
	bullet.init(direction, SHOOT_DAMAGE, 1.0, SHOOT_SPEED)
	bullet.position = position
	$"/root/Main".add_child(bullet)

func _shoot_attack():
	var direction = _velocity.normalized()
	_shoot(direction)

	var moving_direction = direction
	for i in range(NUM_SHOOTS):
		moving_direction = moving_direction.rotated(SHOOT_DEVIATION)
		_shoot(moving_direction)

	moving_direction = direction
	for i in range(NUM_SHOOTS):
		moving_direction = moving_direction.rotated(-SHOOT_DEVIATION)
		_shoot(moving_direction)