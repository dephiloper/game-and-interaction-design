extends KinematicBody2D

const SPEED: int = 10
const ATTACK_SPEED: float = 450.0
const DRAG: float = 0.92
const GO_INTO_PLANET_SPEED = 50
const MOVE_AWAY_FROM_PLANET_SPEED = 10
const ROUTE_POINT_DISTANCE = 50
const MIN_PLANET_ROUTE_DISTANCE = 55
const DESTROYER_DISTANCE = 40
const ASSASSIN_DISTANCE_FORCE: float = 1.0
const GUARD_DISTANCE = 70
const EPSILON = 0.0001

const SQUARED_ATTACK_RANGE: int = 20000
const SQUARED_SIGNAL_ATTACK_RANGE: int = 40000
const SQUARED_PLANET_DISTANCE: int = 15000
const LURK_ON_PLANET_TARGET_POINT_DIFF: int = 100

const ATTACK_CHANNEL_TIME: float = 0.35
const ATTACK_TIME: float = 0.5
const GO_INTO_PLANET_TIME = 0.7
const LURK_ON_PLANET_TIME = 4.0
const MOVE_AWAY_FROM_PLANET_TIME = 0.8
const DIE_TIME = 0.2
const MOVE_TO_PLANET_COOLDOWN_TIME = 2
const ATTACK_COOLDOWN_TIME = 1.5

signal attack_player

enum ASSASSIN_STATE {
	FlyToPlayer,
	GuardDestroyer,
	ChannelAttack,
	FlyToPlanet,
	GoIntoPlanet,
	LurkOnPlanet,
	MoveAwayFromPlanet,
	Tumble,
	AttackPlayer,
	Dead
}

var state = ASSASSIN_STATE.FlyToPlayer
# var old_state = null

var health: float = 20.0
var _target_player: Player = null
var _target_planet: Planet = null
var _destroyer_to_guard = null
var _guard_position = null
var _velocity: Vector2 = Vector2.ZERO
var _damage: float = 10.0
var _damageSatellite: float = 1.0
var _channel_time = 0
var _attack_velocity = Vector2.ZERO
var _lurk_target_point = null
var _lurk_direction = null
var _move_to_planet_cooldown = 0
var _attack_cooldown = 0
var _has_to_be_removed = false

func state_to_str(s):
	match s:
		ASSASSIN_STATE.FlyToPlayer:
			return 'FlyToPlayer'
		ASSASSIN_STATE.ChannelAttack:
			return 'ChannelAttack'
		ASSASSIN_STATE.FlyToPlanet:
			return 'FlyToPlanet'
		ASSASSIN_STATE.GoIntoPlanet:
			return 'GoIntoPlanet'
		ASSASSIN_STATE.LurkOnPlanet:
			return 'LurkOnPlanet'
		ASSASSIN_STATE.MoveAwayFromPlanet:
			return 'MoveAwayFromPlanet'
		ASSASSIN_STATE.Tumble:
			return 'Tumble'
		ASSASSIN_STATE.AttackPlayer:
			return 'AttackPlayer'
		ASSASSIN_STATE.GuardDestroyer:
			return "GuardDestroyer"
		ASSASSIN_STATE.Dead:
			return 'Dead'

func _ready() -> void:
	_start_guard_destroyer()

func hit(damage: float) -> void:
	health -= damage
	if health <= 0.0:
		die()

func die():
	state = ASSASSIN_STATE.Dead
	_channel_time = DIE_TIME
	collision_mask = 0
	collision_layer = 0

func is_dead():
	return state == ASSASSIN_STATE.Dead

func has_to_be_removed():
	return _has_to_be_removed

func attack_player_by_signal(player):
	if state == ASSASSIN_STATE.FlyToPlayer or state == ASSASSIN_STATE.LurkOnPlanet:
		var dist = player.position.distance_squared_to(position)
		if dist < SQUARED_SIGNAL_ATTACK_RANGE:
			_start_channel_attack(player, false)

func _get_player_in_range():
	for player in GameManager.players:
		var squared_distance = player.position.distance_squared_to(position)
		if squared_distance < SQUARED_ATTACK_RANGE:
			return player
	return null

func _get_planet_in_range():
	for planet in GameManager.planets:
		var squared_distance = planet.position.distance_squared_to(position)
		if squared_distance < SQUARED_PLANET_DISTANCE:
			return planet
	return null

func _get_nearest_planet(pos):
	var nearest_planet = null
	var nearest_planet_distance = null
	for planet in GameManager.planets:
		var planet_distance = planet.position.distance_squared_to(pos)
		if nearest_planet == null or (planet_distance < nearest_planet_distance):
			nearest_planet = planet
			nearest_planet_distance = planet_distance

	return nearest_planet

func _get_nearest_destroyer(pos):
	var nearest_destroyer = null
	var nearest_destroyer_distance = null
	for destroyer in GameManager.destroyers:
		var destroyer_distance = destroyer.position.distance_squared_to(pos)
		if nearest_destroyer == null or (destroyer_distance < nearest_destroyer_distance):
			nearest_destroyer = destroyer
			nearest_destroyer_distance = destroyer_distance

	return nearest_destroyer

func _get_nearest_assassin(pos):
	var nearest_assassin = null
	var nearest_assassin_distance = null
	for assassin in GameManager.assassins:
		if assassin == self:
			continue
		var assassin_distance = assassin.position.distance_squared_to(pos)
		if nearest_assassin == null or (assassin_distance < nearest_assassin_distance):
			nearest_assassin = assassin
			nearest_assassin_distance = assassin_distance

	return nearest_assassin

func _move_away_from(point_to_move, target, distance):
	var target_to_point: Vector2 = point_to_move - target
	if target_to_point.length() < distance:
		point_to_move = target + target_to_point.normalized() * distance
	return point_to_move

func _move_away_from_elastic(point_to_move, target, force):
	var target_to_point: Vector2 = point_to_move - target
	var f = force / (target_to_point.length() + EPSILON) # for numeric stability
	return point_to_move + (f * target_to_point)

func _get_next_route_point(target_point):
	var route_point: Vector2 = target_point
	var index = 0
	while route_point.distance_to(position) > ROUTE_POINT_DISTANCE and (index < 25):
		var route_point_to_position = (position - route_point).normalized() * ROUTE_POINT_DISTANCE
		route_point += route_point_to_position

		# press away from planet
		var nearest_planet: Planet = _get_nearest_planet(route_point)
		var planet_route_distance = (nearest_planet.radius + MIN_PLANET_ROUTE_DISTANCE)
		route_point = _move_away_from(route_point, nearest_planet.position, planet_route_distance)

		# press away from nearest destroyer
		var nearest_destroyer = _get_nearest_destroyer(route_point)
		if nearest_destroyer:
			var destroyer_route_distance = (DESTROYER_DISTANCE + MIN_PLANET_ROUTE_DISTANCE)
			route_point = _move_away_from(route_point, nearest_destroyer.position, destroyer_route_distance)

		index += 1

	return route_point

func _choose_random(list: Array):
	if list.empty():
		return null
	return list[randi() % list.size()]

func _start_fly_to_player():
	_target_player = _choose_random(GameManager.get_living_players())
	state = ASSASSIN_STATE.FlyToPlayer

func _choose_destroyer_to_guard():
	var choosen_destroyer = null
	for destroyer in GameManager.destroyers:
		if destroyer.is_dead():
			continue
		if choosen_destroyer == null or choosen_destroyer.num_guards > destroyer.num_guards:
			choosen_destroyer = destroyer
	return choosen_destroyer

func _start_guard_destroyer():
	_destroyer_to_guard = _choose_destroyer_to_guard()
	if _destroyer_to_guard:
		_destroyer_to_guard.num_guards += 1
	_guard_position = Vector2(randf(), randf()).normalized() * GUARD_DISTANCE
	state = ASSASSIN_STATE.GuardDestroyer

func _start_channel_attack(target_player, do_emit):
	if _attack_cooldown > 0:
		return
	_target_player = target_player
	state = ASSASSIN_STATE.ChannelAttack
	_channel_time = ATTACK_CHANNEL_TIME
	if do_emit:
		emit_signal("attack_player", _target_player)

func _start_attack_player():
	state = ASSASSIN_STATE.AttackPlayer
	_attack_velocity = (_target_player.position - position).normalized() * ATTACK_SPEED
	look_at(_target_player.position)
	_channel_time = ATTACK_TIME
	_attack_cooldown = ATTACK_COOLDOWN_TIME

func _start_fly_to_planet(target_planet):
	state = ASSASSIN_STATE.FlyToPlanet
	_target_planet = target_planet
	set_collision_mask_bit(0, true)

func _start_go_into_planet():
	state = ASSASSIN_STATE.GoIntoPlanet
	_channel_time = GO_INTO_PLANET_TIME
	set_collision_mask_bit(0, false)

func _start_lurk_on_planet():
	state = ASSASSIN_STATE.LurkOnPlanet
	_velocity = Vector2.ZERO
	_channel_time = LURK_ON_PLANET_TIME + randf()*(LURK_ON_PLANET_TIME / 2)
	_lurk_target_point = null
	_target_planet = null

func _start_move_away_from_planet():
	state = ASSASSIN_STATE.MoveAwayFromPlanet
	_channel_time = MOVE_AWAY_FROM_PLANET_TIME
	_move_to_planet_cooldown = MOVE_TO_PLANET_COOLDOWN_TIME

func _process_fly_to_player():
	if _target_player == null:
		_target_player = _choose_random(GameManager.get_living_players())
		if _target_player == null:
			return

	var route_point = _get_next_route_point(_target_player.position)
	_velocity += (route_point - position).normalized() * SPEED

	var player_in_range = _get_player_in_range()
	if player_in_range:
		_start_channel_attack(player_in_range, true)

	look_at(position + _velocity)

	# uncomment this to make assassins go to planets
	"""
	if _move_to_planet_cooldown <= 0:
		var planet_in_range = _get_planet_in_range()
		if planet_in_range:
			_start_fly_to_planet(planet_in_range)
	else:
		_move_to_planet_cooldown -= delta
	"""

func _process_channel_attack(delta: float):
	look_at(_target_player.position)
	_channel_time -= delta
	if _channel_time < 0:
		_start_attack_player()

func _process_fly_to_planet():
	look_at(_target_planet.position)
	_velocity += (_target_planet.position - position).normalized() * SPEED

	var player_in_range = _get_player_in_range()
	if player_in_range:
		_start_channel_attack(player_in_range, true)

func _modify_guard_position():
	var abs_guard_position = _destroyer_to_guard.position + _guard_position

	# move away from planet
	var nearest_planet = _get_nearest_planet(abs_guard_position)
	var planet_distance = nearest_planet.radius + MIN_PLANET_ROUTE_DISTANCE
	abs_guard_position = _move_away_from(abs_guard_position, nearest_planet.position, planet_distance)

	# move away from destroyer
	var nearest_destroyer = _get_nearest_destroyer(abs_guard_position)
	abs_guard_position = _move_away_from(abs_guard_position, nearest_destroyer.position, DESTROYER_DISTANCE)

	# move away from assassin
	var nearest_assassin = _get_nearest_assassin(abs_guard_position)
	if nearest_assassin:
		abs_guard_position = _move_away_from_elastic(abs_guard_position, nearest_assassin.position, ASSASSIN_DISTANCE_FORCE)

	_guard_position = (abs_guard_position - _destroyer_to_guard.position).normalized() * GUARD_DISTANCE

func _process_guard_destroyer():
	if (_destroyer_to_guard != null) and (_destroyer_to_guard.is_dead()):
		_destroyer_to_guard = null

	if _destroyer_to_guard == null:
		_destroyer_to_guard = _choose_destroyer_to_guard()
		if _destroyer_to_guard:
			_destroyer_to_guard.num_guards += 1

	if _destroyer_to_guard == null:
		_process_fly_to_player()
	else:
		_modify_guard_position()

		var guard_point = _destroyer_to_guard.position + _guard_position
		var route_point = _get_next_route_point(guard_point)

		# _guard_position = _guard_position.rotated(0.01)

		_velocity += (route_point - position).normalized() * SPEED
		var player_in_range = _get_player_in_range()
		if player_in_range:
			_destroyer_to_guard.num_guards -= 1
			_start_channel_attack(player_in_range, true)

func _process_go_into_planet(delta):
	_channel_time -= delta
	if _channel_time > 0:
		_velocity = (_target_planet.position - position).normalized() * GO_INTO_PLANET_SPEED
	else:
		if _lurk_target_point == null:
			_lurk_direction = (position - _target_planet.position).normalized()
			_lurk_target_point = _target_planet.position + _lurk_direction * _target_planet.radius

		if (position - _lurk_target_point).length_squared() < LURK_ON_PLANET_TARGET_POINT_DIFF:
			_start_lurk_on_planet()
		else:
			_velocity = (_lurk_target_point - position).normalized() * GO_INTO_PLANET_SPEED
			look_at(position + _lurk_direction)

func _process_lurk_on_planet(delta):
	var player_in_range = _get_player_in_range()
	if player_in_range:
		_start_channel_attack(player_in_range, true)

	_channel_time -= delta
	if _channel_time < 0:
		_start_move_away_from_planet()

func _process_move_away_from_planet(delta):
	_velocity += _lurk_direction * MOVE_AWAY_FROM_PLANET_SPEED
	_channel_time -= delta
	if _channel_time < 0:
		_start_fly_to_player()

	var player_in_range = _get_player_in_range()
	if player_in_range:
		_start_channel_attack(player_in_range, true)

func _process_tumble():
	pass

func _process_attack_player(delta):
	_velocity = _attack_velocity

	_channel_time -= delta
	if _channel_time < 0:
		_start_guard_destroyer()

func _process_dead(delta):
	_channel_time -= delta
	if _channel_time < 0:
		_has_to_be_removed = true
	else:
		var alpha = _channel_time / DIE_TIME
		$Sprite.modulate = Color(1, 1, 1, alpha)

func _physics_process(delta: float) -> void:
	_attack_cooldown -= delta

	match state:
		ASSASSIN_STATE.FlyToPlayer:
			_process_fly_to_player()
		ASSASSIN_STATE.GuardDestroyer:
			_process_guard_destroyer()
		ASSASSIN_STATE.ChannelAttack:
			_process_channel_attack(delta)
		ASSASSIN_STATE.FlyToPlanet:
			_process_fly_to_planet()
		ASSASSIN_STATE.GoIntoPlanet:
			_process_go_into_planet(delta)
		ASSASSIN_STATE.LurkOnPlanet:
			_process_lurk_on_planet(delta)
		ASSASSIN_STATE.MoveAwayFromPlanet:
			_process_move_away_from_planet(delta)
		ASSASSIN_STATE.Tumble:
			_process_tumble()
		ASSASSIN_STATE.AttackPlayer:
			_process_attack_player(delta)
		ASSASSIN_STATE.Dead:
			_process_dead(delta)
			return

	_process_movement(delta)

	#if state != old_state:
	#	print('state: ', state_to_str(state))
	#	old_state = state

func _process_movement(delta: float) -> void:
	var collision = move_and_collide(_velocity * delta)
	if collision:
		_process_collision(collision)

	_velocity *= DRAG

func _process_collision(collision):
	var collider = collision.collider
	if collider.has_method("hit") and not collider.is_in_group("Destroyer"):
		collider.hit(_damage)
		die()
	if collider.has_method("hitSatellite"):
		collider.hitSatellite(_damageSatellite)
		die()

	var do_bounce = true

	match state:
		ASSASSIN_STATE.FlyToPlanet:
			if collider == _target_planet:
				_start_go_into_planet()
		ASSASSIN_STATE.GoIntoPlanet:
			do_bounce = false

	do_bounce = false
	if do_bounce:
		_velocity = _velocity.bounce(collision.normal)

