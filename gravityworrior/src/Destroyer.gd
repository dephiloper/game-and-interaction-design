extends Node2D

const SPEED = 2.0
const FOLLOW_SPEED = 3.0
const ATTACK_SPEED = 15.0
const DRAG = 0.95
const MAX_ROTATION_ANGLE = 0.02

const MAX_HEALTH = 50
const FOLLOW_PROBABILITY: float = 0.33
const SQUARED_ATTACK_RANGE = 20000

const FOLLOW_PLAYER_TIME = 5
const ATTACK_CHANNEL_TIME = 0.7
const ATTACK_DURATION = 1
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
	_start_fly_to_sender()

func _get_nearest_player():
	var nearest_player = null
	var nearest_player_distance = null
	for player in GameManager.players:
		var player_distance = player.position.distance_squared_to(position)
		if nearest_player == null or (player_distance < nearest_player_distance):
			nearest_player = player
			nearest_player_distance = player_distance

	return nearest_player

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

func _die():
	state = DestroyerState.Dead
	$Head.collision_layer = 0
	$Head.collision_mask = 0
	$Body.collision_layer = 0
	$Body.collision_mask = 0
	_channel_time = DIE_TIME

func _process_fly_to_sender():
	_velocity += (_target_point - position).normalized() * SPEED
	_velocity *= DRAG

	if _sender_in_range():
		_start_channel_attack()

func _process_follow_player(delta):
	_velocity += (_target_player.position - position).normalized() * FOLLOW_SPEED
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
		_start_follow_player()

	_velocity += (_target_point - position).normalized() * ATTACK_SPEED
	_velocity *= DRAG

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
			pass
		DestroyerState.Dead:
			_process_dead(delta)

	_update_velocity_by_direction()

	position += _velocity * delta
	if _velocity.length_squared() > 0.01:
		look_at(position + _direction)

func has_to_be_removed():
	return _has_to_be_removed