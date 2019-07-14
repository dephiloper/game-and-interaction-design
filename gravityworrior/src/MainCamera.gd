extends Camera2D

var _timer_active: bool = false
var _initial_position: Vector2
var _intensity: float

func _ready() -> void:
	_initial_position = position
	$ShakeTimer.connect("timeout", self, "_on_ShakeTimer_timeout")

func trigger_shake(intensity: float) -> void:
	_intensity = intensity
	$ShakeTimer.start()
	_timer_active = true
	
func _process(delta: float) -> void:
	if _timer_active:
		var elapsed_time = $ShakeTimer.wait_time - $ShakeTimer.time_left
		position = Vector2(sin($ShakeTimer.time_left * 64) * _intensity, 0)

func _on_ShakeTimer_timeout() -> void:
	_timer_active = false
	position = Vector2(0,0)