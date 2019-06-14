extends KinematicBody2D

const SPEED: int = 10
const ATTACK_SPEED: float = 3.0
const DRAG: float = 0.92
const SQUARED_ATTACK_RANGE: int = 20000
const ATTACK_CHANNEL_TIME: float = 0.5
const ATTACK_TIME: float = 2.0 / ATTACK_SPEED

enum ASSASSIN_STATE {
	FlyToPlayer,
	ChannelAttack,
	FlyToPlanet,
	LurkOnPlanet,
	Tumble,
	AttackPlayer
}

var state = ASSASSIN_STATE.FlyToPlayer

var health: float = 10.0
var _target_player: Player = null
var _velocity: Vector2 = Vector2.ZERO
var _damage: float = 10.0
var _channel_time = 0
var _attack_velocity = Vector2.ZERO

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

func _start_channel_attack(target_player):
	_target_player = target_player
	state = ASSASSIN_STATE.ChannelAttack
	_channel_time = ATTACK_CHANNEL_TIME

func _start_attack_player():
	state = ASSASSIN_STATE.AttackPlayer
	_attack_velocity = (_target_player.position - position) * ATTACK_SPEED
	_channel_time = ATTACK_TIME

func _process_fly_to_player():
	look_at(_target_player.position)
	_velocity += (_target_player.position - position).normalized() * SPEED

	var player_in_range = _get_player_in_range()
	if player_in_range != null:
		_start_channel_attack(player_in_range)

func _process_channel_attack(delta: float):
	look_at(_target_player.position)
	_channel_time -= delta
	if _channel_time < 0:
		_start_attack_player()

func _process_fly_to_planet():
	pass

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

		ASSASSIN_STATE.LurkOnPlanet:
			_process_lurk_on_planet()
			do_process_physics = false

		ASSASSIN_STATE.Tumble:
			_process_tumble()

		ASSASSIN_STATE.AttackPlayer:
			_process_attack_player(delta)

	if do_process_physics:
		_process_physics(delta)

func _process_physics(delta: float) -> void:
	var collision = move_and_collide(_velocity * delta)
	if collision:
		var collider = collision.collider
		_velocity = _velocity.bounce(collision.normal)
		if collider.is_in_group("Player") and collider.has_method("hit"):
			collider.hit(_damage)
			queue_free()
	_velocity *= DRAG