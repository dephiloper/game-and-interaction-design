extends Control

func rotate_bars():
	$Bars.rotation_degrees = 180

func set_health_value(value: float, max_value: float):
	$Bars/HealthPercentage.rect_rotation = 180 - (value * 180) / max_value
	
func set_boost_value(value: float, max_value: float):
	$Bars/BoostPercentage.rect_rotation = 180 - (value * 180) / max_value
	
func set_ammo_value(_value: float, _max_value: float):
	pass