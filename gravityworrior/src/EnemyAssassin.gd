extends KinematicBody2D

const SPEED: int = 10
const ATTACK_SPEED: float = 450.0
const DRAG: float = 0.92
const GO_INTO_PLANET_SPEED = 50

const SQUARED_ATTACK_RANGE: int = 20000
const SQUARED_PLANET_DISTANCE: int = 15000
const ATTACK_CHANNEL_TIME: float = 0.5
const ATTACK_TIME: float = 2.0 / 3.0
const GO_INTO_PLANET_TIME = 0.7
const LURK_ON_PLANET_TARGET_POINT_DIFF: int = 100

enum ASSASSIN_STATE {
	FlyToPlayer,
	ChannelAttack,
	FlyToPlanet,
	GoIntoPlanet,
	LurkOnPlanet,
	Tumble,
	AttackPlayer
}

var state = ASSASSIN_STATE.FlyToPlayer
var last_state = null

var health: float = 10.0
var _target_player: Player = null
var _target_planet: Planet = null
var _velocity: Vector2 = Vector2.ZERO
var _damage: float = 10.0
var _channel_time = 0
var _attack_velocity = Vector2.ZERO

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
		ASSASSIN_STATE.Tumble:
			return 'Tumble'
		ASSASSIN_STATE.AttackPlayer:
			return 'AttackPlayer'
		var value:
			return 'Unknown ' + str(value)

func _ready() -> void:
	_target_player = GameManager.players[randi() % GameManager.players.size()]
	
func hit(damage: float) -> void:
	health -= damage
	if health <= 0.0:
		queue_free()

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

func _start_channel_attack(target_player):
	_target_player = target_player
	state = ASSASSIN_STATE.ChannelAttack
	_channel_time = ATTACK_CHANNEL_TIME

func _start_attack_player():
	state = ASSASSIN_STATE.AttackPlayer
	_attack_velocity = (_target_player.position - position).normalized() * ATTACK_SPEED
	_channel_time = ATTACK_TIME

func _start_fly_to_planet(target_planet):
	state = ASSASSIN_STATE.FlyToPlanet
	_target_planet = target_planet

func _start_go_into_planet():
	state = ASSASSIN_STATE.GoIntoPlanet
	_channel_time = GO_INTO_PLANET_TIME
	set_collision_mask_bit(0, false)

func _start_lurk_on_planet():
	state = ASSASSIN_STATE.LurkOnPlanet
	_velocity = Vector2.ZERO

func _process_fly_to_player():
	look_at(_target_player.position)
	_velocity += (_target_player.position - position).normalized() * SPEED

	var player_in_range = _get_player_in_range()
	if player_in_range:
		_start_channel_attack(player_in_range)

	var planet_in_range = _get_planet_in_range()
	if planet_in_range:
		_start_fly_to_planet(planet_in_range)

func _process_channel_attack(delta: float):
	look_at(_target_player.position)
	_channel_time -= delta
	if _channel_time < 0:
		_start_attack_player()

func _process_fly_to_planet():
	look_at(_target_planet.position)
	_velocity += (_target_planet.position - position).normalized() * SPEED

func _process_go_into_planet(delta):
	if _channel_time > 0:
		_channel_time -= delta
		_velocity = (_target_planet.position - position).normalized() * GO_INTO_PLANET_SPEED
	else:
		var target_point = _target_planet.position + (position - _target_planet.position).normalized() * _target_planet._radius
		if (position - target_point).length_squared() < LURK_ON_PLANET_TARGET_POINT_DIFF:
			_start_lurk_on_planet()
		else:
			_velocity = (target_point - position).normalized() * GO_INTO_PLANET_SPEED
			look_at(target_point)

func _process_lurk_on_planet():
	pass

func _process_tumble():
	pass

func _process_attack_player(delta):
	_velocity = _attack_velocity

	_channel_time -= delta
	if _channel_time < 0:
		state = ASSASSIN_STATE.FlyToPlayer

func _physics_process(delta: float) -> void:
	var do_process_physics = true
	match state:
		ASSASSIN_STATE.FlyToPlayer:
			_process_fly_to_player()

		ASSASSIN_STATE.ChannelAttack:
			_process_channel_attack(delta)
			do_process_physics = false

		ASSASSIN_STATE.FlyToPlanet:
			_process_fly_to_planet()

		ASSASSIN_STATE.GoIntoPlanet:
			_process_go_into_planet(delta)

		ASSASSIN_STATE.LurkOnPlanet:
			_process_lurk_on_planet()
			do_process_physics = false

		ASSASSIN_STATE.Tumble:
			_process_tumble()

		ASSASSIN_STATE.AttackPlayer:
			_process_attack_player(delta)

	_process_movement(delta)

	if last_state != state:
		print('new state: ' + state_to_str(state))
		last_state = state

func _process_movement(delta: float) -> void:
	var collision = move_and_collide(_velocity * delta)
	if collision:
		_process_collision(collision)

	_velocity *= DRAG

func _process_collision(collision):
	var collider = collision.collider
	if collider.is_in_group("Player") and collider.has_method("hit"):
		collider.hit(_damage)
		queue_free()

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

