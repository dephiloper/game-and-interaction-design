extends Node2D

var _timer: Timer
var _timer_started: bool = false

class_name WarnSignal

func _init() -> void:
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.wait_time = 1
	_timer.connect("timeout", self, "_timer_timeout")
	add_child(_timer)

func _ready() -> void:
	_timer.start(1)
	_timer_started = true

	
func _process(delta: float) -> void:
	if _timer_started:
		update()
	
	
func _draw() -> void:
	if _timer_started:
		draw_circle_ring(Vector2(0,0), (_timer.wait_time - _timer.time_left) * 200, Color.red)
	
func draw_circle_ring(center, radius, color):
    var nb_points = 32
    var points_arc = PoolVector2Array()

    for i in range(nb_points + 1):
        var angle_point = deg2rad(i * 360 / nb_points - 90)
        points_arc.push_back(center + Vector2(cos(angle_point), sin(angle_point)) * radius)

    for index_point in range(nb_points):
        draw_line(points_arc[index_point], points_arc[index_point + 1], color, 2.0)

func _timer_timeout() -> void:
	_timer_started = false
	queue_free()