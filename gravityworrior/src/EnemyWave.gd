extends Node

class_name EnemyWave

const NUM_ENEMY_TYPES: int = 4
const NUM_ENEMIES_EPSILON: float = 0.1

enum EnemyType {
	ASSASSIN,
	EXPLODING_ASSASSIN,
	DESTROYER,
	BIG_DESTROYER
}

# the number of destroyers that will still come in this wave
var _num_destroyers_to_spawn: int
# an array that maps enemy types to the taken space of this enemy type
var _taken_space_values: Array

var _spawn_rates: Array
var _spawn_values: Array
var _global_spawn_rate: float
var _global_spawn_rate_gain: float

func _reset_spawn_values():
	_spawn_values = []
	for i in range(NUM_ENEMY_TYPES):
		_spawn_values.append(0.0)

func _get_default_taken_space_values():
	return [0.07, 0.3, 0.6, 1.0]

func _init(num_destroyers_to_spawn: int, spawn_rates: Array):
	_num_destroyers_to_spawn = num_destroyers_to_spawn
	_spawn_rates = spawn_rates
	_reset_spawn_values()
	_taken_space_values = _get_default_taken_space_values()
	_global_spawn_rate = 1.0
	_global_spawn_rate_gain = 0.05

func _get_num_enemies_of_type(enemy_type):
	match enemy_type:
		EnemyType.ASSASSIN:
			return len(GameManager.assassins)
		EnemyType.EXPLODING_ASSASSIN:
			return len(GameManager.exploding_assassins)
		EnemyType.DESTROYER:
			return len(GameManager.destroyers)
		EnemyType.BIG_DESTROYER:
			return len(GameManager.big_destroyers)
	return 0

func _get_spawn_value_gain(enemy_type):
	"""
	Returns a value, that is used to increase the spawn value.
	The spawn value gain depends on the following properties:
		- the number of enemies of this type, currently playing in the game
		- the taken space value of this type
		- the spawn_rate of this type
		- the global_spawn_rate
	"""
	var place_already_taken = (_get_num_enemies_of_type(enemy_type) + NUM_ENEMIES_EPSILON) * _taken_space_values[enemy_type]
	return (_spawn_rates[enemy_type] * _global_spawn_rate) / place_already_taken

func _is_destroyer(enemy_type):
	return enemy_type == EnemyType.DESTROYER or enemy_type == EnemyType.BIG_DESTROYER

func process_new_enemies(delta) -> Array:
	"""
	Returns a list of EnemyTypes, which should spawn.
	"""
	var new_enemies = []

	if not _destroyer_finished():
		for enemy_type in range(NUM_ENEMY_TYPES):
			_spawn_values[enemy_type] += _get_spawn_value_gain(enemy_type) * delta
			if _spawn_values[enemy_type] > 100.0:
				new_enemies.append(enemy_type)
				_spawn_values[enemy_type] = 0.0
				if _is_destroyer(enemy_type):
					_num_destroyers_to_spawn -= 1

		_global_spawn_rate += _global_spawn_rate_gain * delta

	return new_enemies

func _no_enemies_left():
	return GameManager.enemies.empty()

func _destroyer_finished():
	return _num_destroyers_to_spawn <= 0

func finished():
	return _destroyer_finished() and _no_enemies_left()