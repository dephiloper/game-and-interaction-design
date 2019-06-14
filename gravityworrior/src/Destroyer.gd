extends Node2D

const SPEED = 20.0
const MAX_HEALTH = 50

enum DestroyerState {
	FlyToSender,
	ChannelAttack,
	Attack,
	FollowPlayer,
	CircleSender
}

var health = MAX_HEALTH
var state = DestroyerState.FlyToSender
var _has_to_be_removed = false
var _target_point = Vector2(400, 400)
var _target_player = null

func _on_hit(damage):
	health -= damage
	if health <= 0:
		_has_to_be_removed = true

func _ready():
	$Body.connect("got_hit", self, "_on_hit")

func _physics_process(delta: float) -> void:
	var velocity = (_target_point - position).normalized() * SPEED
	position += velocity * delta
	look_at(_target_point)

func has_to_be_removed():
	return _has_to_be_removed