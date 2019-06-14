extends Node2D

const SPEED = 20.0
const MAX_HEALTH = 50
const FOLLOW_PLAYER_TIME = 5
const FOLLOW_PROBABILITY: float = 0.33

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
var _velocity = Vector2.ZERO
var _has_to_be_removed = false
var _target_point = Vector2(400, 400)
var _target_player = null
var _channel_time = 0

func _with_probability(probability):
	return randf() < probability

func _on_hit(damage):
	health -= damage
	if health <= 0:
		_has_to_be_removed = true

	if _with_probability(FOLLOW_PROBABILITY):
		_start_follow_player()

#warning-ignore:return_value_discarded
func _ready():
	$Body.connect("got_hit", self, "_on_hit")
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

func _start_fly_to_sender():
	state = DestroyerState.FlyToSender

func _start_follow_player():
	_target_player = _get_nearest_player()
	state = DestroyerState.FollowPlayer
	
	_channel_time = FOLLOW_PLAYER_TIME

func _process_fly_to_sender():
	_velocity = (_target_point - position).normalized() * SPEED
	look_at(_target_point)

func _process_follow_player(delta):
	_velocity = (_target_player.position - position).normalized() * SPEED
	look_at(_target_player.position)

	_channel_time -= delta
	if _channel_time <= 0:
		_start_fly_to_sender()

func _physics_process(delta: float) -> void:
	match state:
		DestroyerState.FlyToSender:
			_process_fly_to_sender()
		DestroyerState.ChannelAttack:
			pass
		DestroyerState.Attack:
			pass
		DestroyerState.FollowPlayer:
			_process_follow_player(delta)
		DestroyerState.CircleSender:
			pass
		DestroyerState.Dead:
			pass

	position += _velocity * delta

func has_to_be_removed():
	return _has_to_be_removed