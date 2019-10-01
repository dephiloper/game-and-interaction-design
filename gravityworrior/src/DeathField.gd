extends Node2D

const DURATION_TIL_DEATH: float = 1.5
const DURATION_DEATH_SHOWN: float = 1.0
const RADIUS: float = 50.0

var _color = Color(0.6, 0.6, 0.6, 0.4)
var _elapsed_time: float = 0.0
var _death_enabled: bool = false


func _ready():
	pass
	
func _draw():
	draw_circle(Vector2.ZERO, RADIUS, _color)
	
func _process(delta):
	_elapsed_time += delta
	
	if not _death_enabled:
		var p = _elapsed_time / DURATION_TIL_DEATH
		_color.a = round((sin(_elapsed_time * p * 20) + 1) / 2)
		update()
		
		if _elapsed_time > DURATION_TIL_DEATH:
			_color = Color(0.9, 0.0, 0.05, 0.8)
			_death_enabled = true
			_elapsed_time = 0
	else:
		self.scale *= 1.005
		if _elapsed_time > DURATION_DEATH_SHOWN:
			queue_free()