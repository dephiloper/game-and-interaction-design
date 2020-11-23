extends Node2D
var _press_to_start_time: float = 0.0
var _max_press_time: float = 1.0

func _ready() -> void:
	$DifficultySlider.min_value = 0
	$DifficultySlider.value = GameManager.difficulty
	$DifficultySlider.max_value = GameManager.max_difficulty

func _process(delta: float) -> void:
	if Input.is_action_pressed("jump"):
		_press_to_start_time += delta
		if _press_to_start_time > _max_press_time:
			GameManager.difficulty = $DifficultySlider.value
			get_tree().change_scene("res://src/Main.tscn")
	else:
		if Input.is_action_just_pressed("ui_left"):
			$DifficultySlider.value = max($DifficultySlider.value - 1, $DifficultySlider.min_value)
		if Input.is_action_just_pressed("ui_right"):
			$DifficultySlider.value = min($DifficultySlider.value + 1, $DifficultySlider.max_value)
		_press_to_start_time = 0
	
	$DifficultySprite.frame = $DifficultySlider.value
	
	update()
	

func _draw() -> void:
	var angle_to = _press_to_start_time * 360 / _max_press_time
	draw_circle_arc_poly($StartButton.position, 48, 0, angle_to, Color("#D9631E"))

# duplicate
func draw_circle_arc_poly(center: Vector2, radius: float, angle_from: float, angle_to: float, color: Color):
	var nb_points = 32
	var points_arc = PoolVector2Array()
	points_arc.push_back(center)
	var colors = PoolColorArray([color])

	for i in range(nb_points + 1):
		var angle_point = deg2rad(angle_from + i * (angle_to - angle_from) / nb_points - 90)
		points_arc.push_back(center + Vector2(cos(angle_point), sin(angle_point)) * (radius - 4))
	draw_polygon(points_arc, colors)
