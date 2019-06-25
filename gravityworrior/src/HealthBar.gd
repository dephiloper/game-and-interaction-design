extends Node2D

const WIDTH: int = 32
const HEIGHT: int = 6
const BORDER_SIZE: int = 1

var _progress: float = 100
var _max_progress: float = 100

class_name HealthBar

func _ready() -> void:
	position = Vector2(position.x - WIDTH/2.0, position.y)
	
func set_health_value(value: float, max_value: float = 100) -> void:
	_progress = value
	_max_progress = max_value
	update()

func _draw() -> void:
	draw_rect(Rect2(0, 0, WIDTH, HEIGHT), Color(0, 0, 0, 0.5))
	var width: float = ((WIDTH - 2*BORDER_SIZE) * _progress) / _max_progress
	draw_rect(Rect2(BORDER_SIZE, BORDER_SIZE, width, HEIGHT - 2*BORDER_SIZE), Color(1, 0, 0, 0.5))