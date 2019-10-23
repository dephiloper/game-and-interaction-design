extends Node2D

const DURATION_TIL_DEATH: float = 1.0
const DURATION_DEATH_SHOWN: float = 0.35
const RADIUS: float = 85.0

var _color = Color(0.6, 0.6, 0.6, 0.4)
var _elapsed_time: float = 0.0
var _death_enabled: bool = false
var _damaged_bodies: Array = []
var _field_triggered = false

func _ready():
	$Area2D.connect("body_entered", self, "_on_Area2D_body_entered")
	$Area2D.connect("body_exited", self, "_on_Area2D_body_exited")
	
func _draw():
	draw_circle(Vector2.ZERO, RADIUS, _color)
	
func _process(delta):
	_elapsed_time += delta
	
	if not _death_enabled:
		var p = _elapsed_time / DURATION_TIL_DEATH
		_color.a = round((sin(_elapsed_time * p * 40) + 1) / 2)
		update()
		
		if _elapsed_time > DURATION_TIL_DEATH:
			_color = Color(0.9, 0.0, 0.05, 0.8)
			_death_enabled = true
			_elapsed_time = 0
	else:
		if not _field_triggered:
			_field_triggered = true
			AudioPlayer.play_stream(AudioPlayer.explosion, -10)
			GameManager.trigger_camera_shake()
		self.scale *= 1.01
		for body in _damaged_bodies:
			body.hit(20 * (1 + GameManager.difficulty / 3), Vector2.ZERO)
			_damaged_bodies.erase(body)
		if _elapsed_time > DURATION_DEATH_SHOWN:
			queue_free()
			
func _on_Area2D_body_entered(body: PhysicsBody2D):
	if body.is_in_group("Player"):
		_damaged_bodies.append(body)
	
func _on_Area2D_body_exited(body: PhysicsBody2D):
	if body.is_in_group("Player"):
		_damaged_bodies.erase(body)