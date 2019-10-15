extends Node2D

const TIME_TO_FREE = 10.0
const BLINK_DURATION = 1.02
const DRAG = 0.5

var _free_counter
var _item_drop_kind
var _start_position
var _state
var _target_point
var _velocity
var _locked = false
var _acceleration

enum ItemDropKind {
	FireRate,
	HealthRestore,
	MultiShot,
	Shield
}

enum ItemDropState {
	Levitated,
	Collected,
	Dead
}


func _random_kind():
	var index = randi() % 4
	if index == 0:
		return ItemDropKind.FireRate
	elif index == 1:
		return ItemDropKind.HealthRestore
	elif index == 2:
		return ItemDropKind.MultiShot
	elif index == 3:
		return ItemDropKind.Shield
	assert false


func get_item_kind():
	return _item_drop_kind


func _set_sprite():
	match _item_drop_kind:
		ItemDropKind.FireRate:
			$AnimatedSprite.play("FireRate")
		ItemDropKind.HealthRestore:
			$AnimatedSprite.play("HealthRestore")
		ItemDropKind.MultiShot:
			$AnimatedSprite.play("MultiShot")
		ItemDropKind.Shield:
			$AnimatedSprite.play("Shield")


func _set_position():
	position = _start_position + Vector2(sin(_free_counter*1.3), cos(_free_counter + 0.1))*2


func _get_duration():
	if _item_drop_kind == ItemDropKind.FireRate:
		return 5.5
	elif _item_drop_kind == ItemDropKind.HealthRestore:
		return 1.2
	elif _item_drop_kind == ItemDropKind.MultiShot:
		return 5.0
	elif _item_drop_kind == ItemDropKind.Shield:
		return 7.5
	return 0.0


func init(position: Vector2):
	_velocity = Vector2.ZERO
	_state = ItemDropState.Levitated
	_free_counter = TIME_TO_FREE
	add_to_group("ItemDrop")
	$ItemDropCollisionArea.add_to_group("ItemDrop")
	_start_position = position
	_set_position()
	_item_drop_kind = _random_kind()
	_set_sprite()
	_acceleration = 0.02


func is_dead():
	return _state == ItemDropState.Dead


func is_collected():
	return _state == ItemDropState.Collected


func is_levitated():
	return _state == ItemDropState.Levitated


func collected(target_point):
	_state = ItemDropState.Collected
	_target_point = target_point
	_free_counter = _get_duration()


func set_target_point(target_point):
	_target_point = target_point


func _move_to_target_point():
	if (_target_point - position).length_squared() < 16.0:
		_locked = true

	if _locked:
		position = _target_point
	else:
		var impact = (_target_point - position)*_acceleration
		_velocity += impact
		_velocity *= DRAG
		position += _velocity
		_acceleration += 0.007


func _physics_process(delta: float) -> void:
	if GameManager.current_game_state == GameManager.GameState.Fight:
		_free_counter -= delta
		if _state == ItemDropState.Levitated:
			if _free_counter <= 0:
				_state = ItemDropState.Dead
				queue_free()
			_set_position()

		if _state == ItemDropState.Collected:
			_move_to_target_point()
			if _free_counter < BLINK_DURATION:
				modulate.a = (sin(_free_counter*20)+1)/2.0
			if _free_counter <= 0:
				_state = ItemDropState.Dead