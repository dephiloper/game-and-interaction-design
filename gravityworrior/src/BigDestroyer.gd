extends "res://src/Destroyer.gd"

const SHOOT_DAMAGE = 15
const SHOOT_DEVIATION = 0.3
const NUM_SHOOTS = 1
const SHOOT_SPEED = 0.25
const BIG_MAX_HEALTH = 280
const SHOOT_RANGE = 1800
const SHOOT_CHANNEL_TIME: float = 250.0
const SHOOT_DURATION: float = 10.0
const MAX_SHOOT_COUNTER: float = SHOOT_CHANNEL_TIME + SHOOT_DURATION
const SHOOT_SOUND_START = 120

var _destroyer_bullet_scene = preload("res://src/DestroyerBullet.tscn")

var _shoot_counter = -1
var shoot_directions = []

func do_init():
	var direction = Vector2(1, 0)
	shoot_directions.append(direction)

	for i in range(NUM_SHOOTS):
		direction = direction.rotated(SHOOT_DEVIATION)
		shoot_directions.append(direction)

	direction = Vector2(1, 0)
	for i in range(NUM_SHOOTS):
		direction = direction.rotated(-SHOOT_DEVIATION)
		shoot_directions.append(direction)

func _get_damage_scale():
	return 2.0

func _get_max_health():
	return BIG_MAX_HEALTH

func _get_healthbar_scale():
	return 1.5

func _get_speed():
	return 0.7

func _connect_timer():
	$ShootTimer.connect("timeout", self, "_shoot_attack")

func _get_healthbar_offset():
	return Vector2(-20, 0)

func _get_squared_attack_range():
	return SQUARED_ATTACK_RANGE * 0.8

func _do_shoot():
	AudioPlayer.play_stream(AudioPlayer.destroyer_laser_attack, -7)
	for direction in shoot_directions:
		_shoot(direction)

func _shoot(direction):
	$ShootCast.cast_to = direction * SHOOT_RANGE
	$ShootCast.force_raycast_update()
	if $ShootCast.is_colliding():
		var collider = $ShootCast.get_collider()
		if collider.is_in_group("Player"):
			collider.hit(SHOOT_DAMAGE)
		if collider.is_in_group("Satellite"):
			collider.damage(SHOOT_DAMAGE)

func _shoot_attack():
	_shoot_counter = 0

func _physics_process(delta: float) -> void:
	._physics_process(delta)

	if _shoot_counter >= 0:
		_shoot_counter += 1
		if _shoot_counter == SHOOT_SOUND_START:
			AudioPlayer.play_stream(AudioPlayer.destroyer_laser_fade, -22)
		if _shoot_counter == SHOOT_CHANNEL_TIME:
			_do_shoot()
		if _shoot_counter >= MAX_SHOOT_COUNTER:
			_shoot_counter = -1
		update()

func shoot_color():
	var color = Color.red
	if _shoot_counter > SHOOT_CHANNEL_TIME:
		if (int(_shoot_counter) / 3) % 2 == 0:
			color = Color.orange
		color.a = 0.45
	color.a = pow(_shoot_counter / SHOOT_CHANNEL_TIME, 5) * 0.2
	return color

func _draw_shoot(direction):
	var shoot_to = direction * SHOOT_RANGE

	$ShootCast.cast_to = direction * SHOOT_RANGE
	$ShootCast.force_raycast_update()
	if $ShootCast.is_colliding():
		shoot_to = get_global_transform().xform_inv($ShootCast.get_collision_point())

	var width_add = 0
	if _shoot_counter > SHOOT_CHANNEL_TIME:
		width_add = 1

	var color = shoot_color()
	color.a = color.a
	draw_line(Vector2.ZERO, shoot_to, color, 3+width_add, true)

	color = shoot_color()
	color.a = min(color.a * 2.0, 1.0)
	draw_line(Vector2.ZERO, shoot_to, color, 1+width_add, true)

func _draw():
	if is_dead():
		return
	if _shoot_counter > 0:
		for direction in shoot_directions:
			_draw_shoot(direction)