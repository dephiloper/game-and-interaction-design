extends Node2D

const DAMAGE: float = 20.0
const SPEED: float = 500.0

var _damaged_players: Array = []
var _velocity: Vector2
var _color = Color(0.74, 0.3, 0.32, 0.6)

func _ready():
	$ShockArea2D.connect("body_entered", self, "_on_ShockArea2D_body_entered")

func _draw():
    var radius = 80
    var angle_from = -30
    var angle_to = 30
    draw_circle_arc(Vector2(0,60), radius, angle_from, angle_to, _color)
	

func set_direction(direction: Vector2):
	self.rotation = Vector2.UP.angle_to(direction) 
	_velocity = direction * SPEED
	
func draw_circle_arc(center, radius, angle_from, angle_to, color):
    var nb_points = 8
    var points_arc = PoolVector2Array()

    for i in range(nb_points + 1):
        var angle_point = deg2rad(angle_from + i * (angle_to-angle_from) / nb_points - 90)
        points_arc.push_back(center + Vector2(cos(angle_point), sin(angle_point)) * radius)

    for index_point in range(nb_points):
        draw_line(points_arc[index_point], points_arc[index_point + 1], color, 40)
		
func _process(delta):
	self.position += _velocity * delta
	_color = Color(_color.r, _color.g, _color.b, $Timer.time_left / $Timer.wait_time)
	update()
	if $Timer.is_stopped():
		self.queue_free()
	
func _on_ShockArea2D_body_entered(body: PhysicsBody2D):
	if body.is_in_group("Player"):
		if not _damaged_players.has(body):
			body.hit(DAMAGE, _velocity)
			_damaged_players.append(body)