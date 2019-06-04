extends Node

class_name Controls

var input_device_id setget set_device_id
var input_map = Dictionary()

func set_device_id(device_id: int) -> void:
	input_device_id = device_id

func _init() -> void:
	input_device_id = -1
	input_map["ui_right"] = 0.0
	input_map["ui_left"] = 0.0
	input_map["ui_down"] = 0.0
	input_map["ui_up"] = 0.0
	input_map["aim_right"] = 0.0
	input_map["aim_left"] = 0.0
	input_map["aim_down"] = 0.0
	input_map["aim_up"] = 0.0
	input_map["jump"] = 0.0
	input_map["shoot"] = 0.0

# implementation of "own" input event system
func _input(event: InputEvent) -> void:
		# only recognize input entered on specified controller
		if event.device == input_device_id:
			for action in input_map.keys():
				if event.is_action(action):
					input_map[action] = event.get_action_strength(action)