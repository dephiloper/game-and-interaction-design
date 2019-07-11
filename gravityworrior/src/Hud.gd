extends Control

class_name Hud
var _health_color: Color

func set_health_color(color: Color):
	_health_color = color
	$Bars/HealthPercentage.modulate = Color(color.r, color.g, color.b, 0.9)

func set_health_value(value: float, max_value: float):
	$Bars/HealthPercentage.rect_rotation = 180 + (value * 180) / max_value
	if value / max_value < 0.25:
		$Bars/HealthOutline.modulate = Color(0.5, 0, 0, 0.9)
	else:
		$Bars/HealthOutline.modulate = Color(0, 0, 0, 0.9)
	
func set_boost_value(value: float, max_value: float):
	$Bars/BoostPercentage.rect_rotation = 180 + (value * 180) / max_value