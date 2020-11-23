extends Node

class_name Controls

var input_device_id setget set_device_id
var last_axis_direction: Vector2 = Vector2.ZERO
var _input_map = Dictionary()

func set_device_id(device_id: int) -> void:
	input_device_id = device_id

func _init() -> void:
	input_device_id = -1
	_input_map["ui_right"] = 0.0
	_input_map["ui_left"] = 0.0
	_input_map["ui_down"] = 0.0
	_input_map["ui_up"] = 0.0
	_input_map["aim_right"] = 0.0
	_input_map["aim_left"] = 0.0
	_input_map["aim_down"] = 0.0
	_input_map["aim_up"] = 0.0
	_input_map["jump"] = 0.0
	_input_map["shoot"] = 0.0
	_input_map["toggle_alternative_aiming"] = 0.0
	_input_map["toggle_laser_pointer"] = 0.0

# implementation of "own" input event system
func _input(event: InputEvent) -> void:
		# only recognize input entered on specified controller
		if event.device == input_device_id:
			for action in _input_map.keys():
				if event.is_action(action):
					_input_map[action] = event.get_action_strength(action)
					
func pressed(action: String) -> float:
	assert(_input_map.has(action))
	return _input_map[action]
	
func just_pressed(action: String) -> float:
	var input = pressed(action)
	if input:
		_input_map[action] = 0
	return input 
