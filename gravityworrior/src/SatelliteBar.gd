extends Control

const WIDTH: int = 42
const HEIGHT: int = 8
const BORDER_SIZE: int = 2
const Y_OFFSET: int = 48
const X_OFFSET: int = 6

var progress: float = 100
var max_progress: float = 100

func adjust_position(pos: Vector2) -> void:
	rect_position = Vector2(pos.x - WIDTH/2 + X_OFFSET, pos.y - Y_OFFSET)
	
func set_health_value(value: float, max_value: float = 100) -> void:
	progress = value
	max_progress = max_value
	update()

func _draw() -> void:
	draw_rect(Rect2(0, 0, WIDTH, HEIGHT), Color.black)
	var width: float = ((WIDTH - 2*BORDER_SIZE) * progress) / max_progress
	draw_rect(Rect2(BORDER_SIZE, BORDER_SIZE, width, HEIGHT - 2*BORDER_SIZE), Color.red)