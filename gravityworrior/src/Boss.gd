extends KinematicBody2D

enum State {
	IDLE,
	DASH,
	LASER,
	DEATH_FIELDS
}

var _state = State.IDLE
var _elapsed_time: float = 0
var _state_change_counter: float = 2.0
var _target: Vector2
var _velocity: Vector2

var shock_wave_instance = preload("res://src/ShockWave.tscn")

func _init():
	add_to_group("Boss")

func _physics_process(delta):
	_elapsed_time += delta
	_state_change_counter -= delta
	
	if _state == State.IDLE:
		self.position = Vector2(position.x, position.y + sin(_elapsed_time * 5)*0.2)
		if _state_change_counter <= 0:
			_set_random_position()
			_state = State.DASH
			_state_change_counter = 0.8
	
	
	if _state == State.DASH:
		if _target.distance_to(self.global_position) < 10: # target reached
			_state = State.IDLE
			_state_change_counter = 2.0
		elif _state_change_counter <= 0:
			_velocity = (_target - self.global_position).normalized() * 600
			var collision = self.move_and_collide(_velocity * delta)
			if collision:
				_state = State.IDLE
				_state_change_counter = 2.0
				if collision.collider.is_in_group("Planet"):
					var shock_wave = shock_wave_instance.instance()
					shock_wave.position = self.position
					shock_wave.set_direction(_velocity.normalized())
					get_node("/root/Main").add_child(shock_wave)
				if collision.collider.is_in_group("Player"):
					collision.collider.hit(20, _velocity * 0.5)

	if _state == State.LASER:
		_state = State.IDLE
		_state_change_counter = 2.0
	
	if _state == State.DEATH_FIELDS:
		_state = State.IDLE
		_state_change_counter = 2.0
		

func _appear():
	$AppearanceTween.interpolate_property(self, "scale",
		Vector2(0, 0), Vector2(1, 1), 0.4,
		Tween.TRANS_BOUNCE, Tween.EASE_IN)
		
	$AppearanceTween.start()
	
func _dissapear():
	$AppearanceTween.interpolate_property(self, "scale",
		Vector2(1, 1), Vector2(0, 0), 0.4,
		Tween.TRANS_BOUNCE, Tween.EASE_OUT)
		
	$AppearanceTween.start()

func _set_random_position():
	var areas = GameManager.get_empty_boss_spawn_areas()
	var closest_area: Area2D = areas[0]
	var shortest_distance: float = INF
	var players: Array = GameManager.players
	_target = players[randi() % len(players)].global_position
	for area in areas:
		var distance = area.global_position.distance_to(_target)
		if  distance < shortest_distance:
			closest_area = area
			shortest_distance = distance
	
	self.position = closest_area.position
	_appear()