extends KinematicBody2D

var HealthBarScene = preload("res://src/HealthBar.tscn")
var ArrowScene = preload("res://src/EnemyArrow.tscn")

const SPEED_SCALE = 0.9
const SPEED = 1.4 * SPEED_SCALE
const FOLLOW_SPEED = 2.0 * SPEED_SCALE
const ATTACK_SPEED = 20.0 *  SPEED_SCALE
const DRAG = 0.95
const MAX_ROTATION_ANGLE = 0.02
const ROUTE_POINT_DISTANCE = 50
const MIN_PLANET_ROUTE_DISTANCE = 55
const CIRCLE_DISTANCE = 120

const MAX_HEALTH = 160
const FOLLOW_PROBABILITY: float = 0.33
const SQUARED_ATTACK_RANGE = 8000
const DAMAGE = 150
const HEAD_DAMAGE_RATIO: float = 0.4

const FOLLOW_PLAYER_TIME = 7
const ATTACK_CHANNEL_TIME = 0.7
const ATTACK_DURATION = 0.8
const CIRCLE_DURATION = 30
const DIE_TIME = 2.0

enum DestroyerState {
	FlyToSender,
	ChannelAttack,
	Attack,
	FollowPlayer,
	CircleSender,
	Dead
}

signal destroyer_got_attacked(player)

var health
var state
var num_guards: int = 0
var _velocity: Vector2 = Vector2.ZERO
var _has_to_be_removed = false
var _target_point: Vector2
var _satellite_planet = null
var _target_player = null
var _channel_time = 0
var _direction = null

var _health_bar = null
var _arrow

func _get_damage_scale():
	return 1.0

func get_max_health():
	return MAX_HEALTH

func _get_healthbar_scale():
	return 1.0

func _get_healthbar_offset():
	return Vector2(-15, 0)

func _connect_timer():
	pass

func _get_squared_attack_range():
	return SQUARED_ATTACK_RANGE

func _get_speed():
	return SPEED

func _with_probability(probability):
	return randf() < probability

func _item_drop():
	GameManager.possible_item_drop(self.position, 0.2)

func hit(damage, collision):
	# uncomment to make destroyer head invulnerable
	"""
	if collision.collider_shape == $HeadCollisionShape:
		return false
	"""

	"""
	if collision.collider_shape == $HeadCollisionShape:
		damage *= HEAD_DAMAGE_RATIO
	"""

	health -= damage
	if health <= 0:
		health = 0
		AudioPlayer.play_enemy_sound(-8)
		_item_drop()
		_die()

	if state == DestroyerState.FlyToSender or state == DestroyerState.ChannelAttack or state == DestroyerState.CircleSender:
		# uncomment to make destroyer follow player
		"""
		if _with_probability(FOLLOW_PROBABILITY):
			_start_follow_player()
		"""

		emit_signal("destroyer_got_attacked", _get_nearest_player())

	$HitTween.interpolate_property($Sprite, "modulate", 
	Color(1, 1, 1, 1), Color(1, 0, 0, 1), 0.1, Tween.TRANS_LINEAR, Tween.EASE_IN)

	$HitTween.interpolate_property($Sprite, "modulate", Color(1, 0, 0, 1), 
	Color(1, 1, 1, 1), 0.1, Tween.TRANS_LINEAR, Tween.EASE_IN, 0.1)
	
	$HitTween.start()

	return true

func _ready():
	health = get_max_health()
	_target_point = GameManager.satellite.position
	_satellite_planet = _get_nearest_planet(_target_point)
	_start_fly_to_sender()
	add_to_group("Destroyer")

	_health_bar = HealthBarScene.instance()
	_health_bar.transform = _health_bar.transform.scaled(Vector2(_get_healthbar_scale(), _get_healthbar_scale()))
	_health_bar.init(self, _get_healthbar_offset())
	get_parent().add_child(_health_bar)

	_arrow = ArrowScene.instance()
	_arrow.position = position
	_arrow.play("destroyer")
	get_parent().add_child(_arrow)
	_connect_timer()
	do_init()

func do_init():
	pass

func _get_nearest_player():
	var nearest_player = null
	var nearest_player_distance = null
	for player in GameManager.players:
		var player_distance = player.position.distance_squared_to(position)
		if nearest_player == null or (player_distance < nearest_player_distance):
			nearest_player = player
			nearest_player_distance = player_distance

	return nearest_player

func _get_nearest_planet(pos):
	var nearest_planet = null
	var nearest_planet_distance = null
	for planet in GameManager.planets:
		var planet_distance = planet.position.distance_squared_to(pos)
		if nearest_planet == null or (planet_distance < nearest_planet_distance):
			nearest_planet = planet
			nearest_planet_distance = planet_distance

	return nearest_planet

func _sender_in_range():
	return _target_point.distance_squared_to(position) < _get_squared_attack_range()

func is_dead():
	return state == DestroyerState.Dead

func _start_fly_to_sender():
	state = DestroyerState.FlyToSender
	if _direction == null:
		_direction = (_target_point - position).normalized()

func _start_follow_player():
	_target_player = _get_nearest_player()
	state = DestroyerState.FollowPlayer

	_channel_time = FOLLOW_PLAYER_TIME

func _start_channel_attack():
	state = DestroyerState.ChannelAttack
	_channel_time = ATTACK_CHANNEL_TIME

func _start_attack():
	state = DestroyerState.Attack
	_channel_time = ATTACK_DURATION

func _start_circle():
	state = DestroyerState.CircleSender
	_channel_time = CIRCLE_DURATION

func _die():
	state = DestroyerState.Dead
	collision_layer = 0
	collision_mask = 0
	_channel_time = DIE_TIME

	if _arrow:
		_arrow.queue_free()
		_arrow = null

func _get_next_route_point(target_point):
	var route_point: Vector2 = target_point
	var index = 0
	while route_point.distance_to(position) > ROUTE_POINT_DISTANCE and (index < 25):
		var route_point_to_position = (position - route_point).normalized() * ROUTE_POINT_DISTANCE
		route_point += route_point_to_position

		# press away from planet
		var nearest_planet: Planet = _get_nearest_planet(route_point)
		var planet_to_route_point: Vector2 = (route_point - nearest_planet.position)
		var planet_route_distance = (nearest_planet.radius + MIN_PLANET_ROUTE_DISTANCE)
		if planet_to_route_point.length() < planet_route_distance:
			route_point = nearest_planet.position + planet_to_route_point.normalized() * planet_route_distance

		index += 1

	return route_point

func _process_fly_to_sender():
	var route_point = _get_next_route_point(_target_point)
	_velocity += (route_point - position).normalized() * _get_speed()
	_velocity *= DRAG

	if _sender_in_range():
		_start_channel_attack()

func _process_follow_player(delta):
	var route_point = _get_next_route_point(_target_player.position)
	_velocity += (route_point - position).normalized() * FOLLOW_SPEED
	_velocity *= DRAG

	_channel_time -= delta
	if _channel_time <= 0:
		_start_fly_to_sender()

func _process_channel_attack(delta):
	_channel_time -= delta
	if _channel_time < 0:
		_start_attack()

	_velocity *= DRAG

func _process_attack():
	_velocity += (_target_point - position).normalized() * ATTACK_SPEED
	_velocity *= DRAG

func _process_circle_sender(delta):
	var planet_to_position = (position - _satellite_planet.position).normalized() * CIRCLE_DISTANCE
	var movement_vec = planet_to_position.rotated(-PI/2).normalized() * 10
	var target_point = _satellite_planet.position + planet_to_position + movement_vec

	_velocity += (target_point - position).normalized() * _get_speed()
	_velocity *= DRAG

	_channel_time -= delta
	if _channel_time <= 0:
		_start_fly_to_sender()

func _process_dead(delta):
	_velocity *= DRAG
	_channel_time -= delta
	if _channel_time < 0:
		_has_to_be_removed = true
	else:
		var alpha = _channel_time / DIE_TIME
		$Sprite.modulate = Color(1, 1, 1, alpha)
		$Sprite/Head.position += Vector2(0, -1) * delta * 64 * alpha
		$Sprite/Head.rotation += delta * 0.25 * alpha
		$Sprite/LeftPaddle.position += Vector2(-1, 0) * delta * 32 * alpha
		$Sprite/LeftPaddle.rotation += delta * 0.25 * alpha		
		$Sprite/CenterPaddle.position += Vector2(0, 1) * delta * 64 * alpha
		$Sprite/RightPaddle.position += Vector2(1, 0) * delta * 32 * alpha
		$Sprite/RightPaddle.rotation -= delta * 0.25 * alpha
		

func _update_velocity_by_direction():
	if _velocity.length_squared() > 0.01:
		var angle = _direction.angle_to(_velocity.normalized())
		if abs(angle) > MAX_ROTATION_ANGLE:
			angle = sign(angle) * MAX_ROTATION_ANGLE
		_direction = _direction.rotated(angle).normalized()
		_velocity = _velocity.project(_direction)

func _physics_process(delta: float) -> void:
	match state:
		DestroyerState.FlyToSender:
			_process_fly_to_sender()
		DestroyerState.ChannelAttack:
			_process_channel_attack(delta)
		DestroyerState.Attack:
			_process_attack()
		DestroyerState.FollowPlayer:
			_process_follow_player(delta)
		DestroyerState.CircleSender:
			_process_circle_sender(delta)
		DestroyerState.Dead:
			_process_dead(delta)

	_update_velocity_by_direction()

	var collision = move_and_collide(_velocity * delta)
	if collision:
		_velocity = _velocity.bounce(collision.normal)
		_velocity *= 0.1
		if collision.collider.is_in_group("Satellite"):
			GameManager.satellite.damage(DAMAGE * _get_damage_scale())
			AudioPlayer.play_stream(AudioPlayer.satellite_hit, -2)
			_die()

	if _velocity.length_squared() > 0.01:
		if not is_dead():
			look_at(position + _direction)

	if _arrow != null:
		if _arrow.update_position(position, rotation):
			_arrow.queue_free()
			_arrow = null

func has_to_be_removed():
	return _has_to_be_removed