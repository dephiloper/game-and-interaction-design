extends Control

class_name Hud

func set_health_value(value: float, max_value: float):
	$Bars/HealthPercentage.rect_rotation = 180 + (value * 180) / max_value
	
func set_boost_value(value: float, max_value: float):
	$Bars/BoostPercentage.rect_rotation = 180 + (value * 180) / max_value