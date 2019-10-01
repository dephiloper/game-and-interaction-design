extends KinematicBody2D

enum State {
	IDLE,
	DASH,
	LASER,
	DEATH_FIELDS
}

const SHOOT_DAMAGE = 15
const SHOOT_CHANNEL_TIME: float = 250.0
const SHOOT_RANGE = 1800
const SHOOT_DURATION: float = 10.0
const MAX_SHOOT_COUNTER: float = SHOOT_CHANNEL_TIME + SHOOT_DURATION
const SHOOT_SOUND_START = 120

var _state = State.IDLE
var _elapsed_time: float = 0
var _state_change_counter: float = 2.0
var _target: Vector2
var _velocity: Vector2
var _shoot_counter: int = -1

var shock_wave_instance = preload("res://src/ShockWave.tscn")
var death_field_instance = preload("res://src/DeathField.tscn")

func _init():
	add_to_group("Boss")

func _physics_process(delta):
	_elapsed_time += delta
	_state_change_counter -= delta
	
	if _state == State.IDLE:
		self.position = Vector2(position.x, position.y + sin(_elapsed_time * 5)*0.2)
		if _state_change_counter <= 0:
			var index = randi() % 3
			if index == 0:
				_set_random_position(true)
				_state = State.DASH
				_state_change_counter = 2.0
			elif index == 1:
				_start_laser()
			elif index == 2:
				_set_random_position(false)
				_state = State.DEATH_FIELDS
				_state_change_counter = 2.0

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
		_process_laser()
	
	if _state == State.DEATH_FIELDS:
		for player in GameManager.players:
			var death_field = death_field_instance.instance()
			death_field.position = player.position + player.get_velocity() / 2.5
			get_node("/root/Main").add_child(death_field)
		
		_state = State.IDLE
		_state_change_counter = 2.0


func _start_laser():
	_state = State.LASER
	_shoot_counter = 0
	_state_change_counter = 4.5


func _process_laser():
	if _state_change_counter < 0:
		_state = State.IDLE
		_state_change_counter = 2.0
	elif _shoot_counter >= 0:
		_shoot_counter += 1
		if _shoot_counter == SHOOT_SOUND_START:
			AudioPlayer.play_stream(AudioPlayer.destroyer_laser_fade, -22)
		if _shoot_counter == SHOOT_CHANNEL_TIME:
			_do_shoot()
		if _shoot_counter >= MAX_SHOOT_COUNTER:
			_shoot_counter = -1
		update()


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

func _set_random_position(near_player: bool):
	var areas = GameManager.get_empty_boss_spawn_areas()

	if near_player: # position near the player
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
	
	else: # random new position
		self.position = areas[randi() % len(areas)].position
	
	_appear()


func _do_shoot():
	GameManager.trigger_camera_shake()
	for player in GameManager.players:
		var direction = (player.position - position).normalized()
		_shoot(direction)

func _shoot(direction):
	$ShootCast.cast_to = direction * SHOOT_RANGE
	$ShootCast.force_raycast_update()
	if $ShootCast.is_colliding():
		var collider = $ShootCast.get_collider()
		if collider.is_in_group("Player"):
			collider.hit(SHOOT_DAMAGE, direction.normalized() * 2)
		if collider.is_in_group("Satellite"):
			collider.damage(SHOOT_DAMAGE*4)

func shoot_color():
	var color = Color.red
	if _shoot_counter > SHOOT_CHANNEL_TIME:
		if (int(_shoot_counter / 3)) % 2 == 0:
			color = Color.orange
		color.a = 0.45
	color.a = pow(_shoot_counter / SHOOT_CHANNEL_TIME, 5) * 0.2
	return color

func _draw_shoot(direction):
	var shoot_to = direction * SHOOT_RANGE

	$ShootCast.cast_to = direction * SHOOT_RANGE
	$ShootCast.force_raycast_update()
	if $ShootCast.is_colliding():
		shoot_to = get_global_transform().xform_inv($ShootCast.get_collision_point())

	var width_add = 0
	if _shoot_counter > SHOOT_CHANNEL_TIME:
		width_add = 1

	var color = shoot_color()
	color.a = color.a
	draw_line(Vector2.ZERO, shoot_to, color, 3+width_add, true)

	color = shoot_color()
	color.a = min(color.a * 2.0, 1.0)
	draw_line(Vector2.ZERO, shoot_to, color, 1+width_add, true)

func _draw():
	if _shoot_counter > 0:
		for player in GameManager.players:
			var direction = (player.position - position).normalized()
			_draw_shoot(direction)