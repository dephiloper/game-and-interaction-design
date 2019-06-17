extends Node2D

const SPEED = 2.0
const FOLLOW_SPEED = 4.0
const ATTACK_SPEED = 20.0
const DRAG = 0.95
const MAX_ROTATION_ANGLE = 0.02
const ROUTE_POINT_DISTANCE = 50
const MIN_PLANET_ROUTE_DISTANCE = 55
const CIRCLE_DISTANCE = 120

const MAX_HEALTH = 50
const FOLLOW_PROBABILITY: float = 0.33
const SQUARED_ATTACK_RANGE = 20000
const DAMAGE = 20

const FOLLOW_PLAYER_TIME = 7
const ATTACK_CHANNEL_TIME = 0.7
const ATTACK_DURATION = 0.8
const CIRCLE_DURATION = 15
const DIE_TIME = 1.0

enum DestroyerState {
	FlyToSender,
	ChannelAttack,
	Attack,
	FollowPlayer,
	CircleSender,
	Dead
}

var health = MAX_HEALTH
var state
var _velocity: Vector2 = Vector2.ZERO
var _has_to_be_removed = false
var _target_point: Vector2
var _satellite_planet = null
var _target_player = null
var _channel_time = 0
var _direction = null

func _with_probability(probability):
	return randf() < probability

func _on_hit(damage):
	health -= damage
	if health <= 0:
		_die()

	if state == DestroyerState.FlyToSender or state == DestroyerState.ChannelAttack or state == DestroyerState.CircleSender:
		if _with_probability(FOLLOW_PROBABILITY):
			_start_follow_player()

#warning-ignore:return_value_discarded
func _ready():
	$Body.connect("got_hit", self, "_on_hit")
	_target_point = GameManager.satellite.position
	_satellite_planet = _get_nearest_planet(_target_point)
	_start_fly_to_sender()
	$Head.add_to_group("Destroyer")
	$Body.add_to_group("Destroyer")

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
		var planet_distance = planet.position.distance_squared_to(position)
		if nearest_planet == null or (planet_distance < nearest_planet_distance):
			nearest_planet = planet
			nearest_planet_distance = planet_distance

	return nearest_planet

func _sender_in_range():
	return _target_point.distance_squared_to(position) < SQUARED_ATTACK_RANGE

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
	$Head.collision_layer = 0
	$Head.collision_mask = 0
	$Body.collision_layer = 0
	$Body.collision_mask = 0
	_channel_time = DIE_TIME
	var kill_counter = $"/root/Main/EnemySpawn".kill_count
	if kill_counter > 0:
		$"/root/Main/EnemySpawn".kill_count = kill_counter - 1
	print(kill_counter)

func _get_next_route_point(target_point):
	var route_point: Vector2 = target_point
	var index = 0
	var route_points = []
	while route_point.distance_to(position) > ROUTE_POINT_DISTANCE:
		var route_point_to_position = (position - route_point).normalized() * ROUTE_POINT_DISTANCE
		route_point += route_point_to_position

		# press away from planet
		var nearest_planet: Planet = _get_nearest_planet(route_point)
		var planet_to_route_point: Vector2 = (route_point - nearest_planet.position)
		var planet_route_distance = (nearest_planet.radius + MIN_PLANET_ROUTE_DISTANCE)
		if planet_to_route_point.length() < planet_route_distance:
			route_point = nearest_planet.position + planet_to_route_point.normalized() * planet_route_distance
		route_points.append(route_point)

		index += 1
		if index > 25:
			break

	return route_point

func _process_fly_to_sender():
	var route_point = _get_next_route_point(_target_point)
	_velocity += (route_point - position).normalized() * SPEED
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

func _process_attack(delta):
	_channel_time -= delta
	if _channel_time < 0:
		GameManager.satellite.hit(DAMAGE)
		_start_circle()

	_velocity += (_target_point - position).normalized() * ATTACK_SPEED
	_velocity *= DRAG

func _process_circle_sender(delta):
	var planet_to_position = (position - _satellite_planet.position).normalized() * CIRCLE_DISTANCE
	var movement_vec = planet_to_position.rotated(-PI/2).normalized() * 10
	var target_point = _satellite_planet.position + planet_to_position + movement_vec

	_velocity += (target_point - position).normalized() * SPEED
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
		get_node("Head/Sprite").modulate = Color(1, 1, 1, alpha)
		get_node("Body/Sprite").modulate = Color(1, 1, 1, alpha*alpha)

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
			_process_attack(delta)
		DestroyerState.FollowPlayer:
			_process_follow_player(delta)
		DestroyerState.CircleSender:
			_process_circle_sender(delta)
		DestroyerState.Dead:
			_process_dead(delta)

	_update_velocity_by_direction()

	position += _velocity * delta
	if _velocity.length_squared() > 0.01:
		look_at(position + _direction)

func has_to_be_removed():
	return _has_to_be_removed