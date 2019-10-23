extends KinematicBody2D

class_name Boss

const HealthBarScene = preload("res://src/HealthBar.tscn")

enum State {
	IDLE,
	DASH,
	LASER,
	DEATH_FIELDS
}

const MAX_HEALTH: float = 10000.0
const SHOOT_DAMAGE = 15
const SHOOT_CHANNEL_TIME: float = 160.0
const SHOOT_RANGE = 1800
const SHOOT_DURATION: float = 10.0
const MAX_SHOOT_COUNTER: float = SHOOT_CHANNEL_TIME + SHOOT_DURATION
const SHOOT_SOUND_START = 100
const DASH_TIME = 0.4
const DASH_SPEED = 600

var _state = State.IDLE
var _elapsed_time: float = 0
var _state_change_counter: float = 2.0
var _target: Player
var _velocity: Vector2
var _shoot_counter: int = -1
var health: float = MAX_HEALTH
var _health_bar
var difficulty_multiplier

# three phases -> first phase one attack & slow
# second phase two attacks and faster
# thrid phase three attacks and ultra fast
var _patterns: Array = [[0], [0, 1], [2, 1, 0, 2]]
var _phase: int = 0
var _current_attack: int = 0
var _attack_speed: float = 1.0

var shock_wave_instance = preload("res://src/ShockWave.tscn")
var death_field_instance = preload("res://src/DeathField.tscn")

func hit(damage: float, collision) -> bool:
	$HitTween.interpolate_property($Sprite, "modulate", 
		Color(1, 1, 1, 1), Color(0.7, 0.7, 0.7, 1), 0.1, Tween.TRANS_LINEAR, Tween.EASE_IN)

	$HitTween.interpolate_property($Sprite, "modulate", Color(0.7, 0.7, 0.7, 1), 
		Color(1, 1, 1, 1), 0.1, Tween.TRANS_LINEAR, Tween.EASE_IN, 0.1)
	
	$HitTween.start()
	
	if is_dead():
		AudioPlayer.play_enemy_sound(-8)
		collision_layer = 0
		collision_mask = 0
		queue_free()
		return false
		
	health -= damage
	
	if _phase == 0 and health <= MAX_HEALTH * 0.8:
		_phase = 1
		_current_attack = 0
		_attack_speed = 1.2
	elif _phase == 1 and health <= MAX_HEALTH * 0.4:
		_phase = 2
		_attack_speed = 1.4
		_current_attack = 0
	
	return true

func has_to_be_removed():
	return health <= 0
	
func get_max_health() -> float:
	return MAX_HEALTH
	
func is_dead() -> bool:
	return health <= 0

func _init():
	add_to_group("Boss")

func _ready():
	_health_bar = HealthBarScene.instance()
	_health_bar.transform = _health_bar.transform.scaled(Vector2(2, 2))
	_health_bar.init(self,  Vector2(-30, 0))
	get_parent().call_deferred("add_child", _health_bar)
	difficulty_multiplier = (1 + GameManager.difficulty / 3)

func _physics_process(delta):
	_elapsed_time += delta
	_state_change_counter -= delta
	_do_hover()

	if _state == State.IDLE:
		if _state_change_counter <= 0:
			var index = _patterns[_phase][_current_attack]
			_current_attack = (_current_attack + 1) % len(_patterns[_phase])
			if index == 0:
				_set_random_position(true)
				_state = State.DASH
				_state_change_counter = 1.0
			elif index == 1:
				_start_laser()
			elif index == 2:
				_set_random_position(false)
				_state = State.DEATH_FIELDS

	if _state == State.DASH:
		if _target.global_position.distance_to(self.global_position) < 10 or _state_change_counter <= -DASH_TIME:
			_state = State.IDLE
			_state_change_counter = 2.0
		elif _state_change_counter <= 0:
			_velocity = (_target.global_position - self.global_position).normalized() * DASH_SPEED * _attack_speed
			var collision = self.move_and_collide(_velocity * delta)
			if collision:
				var collider = collision.collider
				if collider.is_in_group("Bullet"):
					return
					
				_state = State.IDLE
				_state_change_counter = 2.0
				if collider.is_in_group("Planet"):
					GameManager.possible_item_drop(self.position, 0.5)
					var shock_wave = shock_wave_instance.instance()
					shock_wave.position = self.position
					shock_wave.set_direction(_velocity.normalized())
					get_node("/root/Main").add_child(shock_wave)
					GameManager.trigger_camera_shake()
					AudioPlayer.play_stream(AudioPlayer.boss_collide, 0)
				if collider.is_in_group("Player"):
					collider.hit(15 * difficulty_multiplier, _velocity * 0.5)

	if _state == State.LASER:
		_process_laser()
	
	if _state == State.DEATH_FIELDS:
		for player in GameManager.players:
			var death_field = death_field_instance.instance()
			death_field.position = player.position + player.get_velocity() / 2.5
			get_node("/root/Main").add_child(death_field)
		
		_state = State.IDLE
		_state_change_counter = 3.0

func _do_hover():
	self.position = Vector2(position.x, position.y + sin(_elapsed_time * 5)*0.2)

func _start_laser():
	_set_random_position(false)
	_state = State.LASER
	_shoot_counter = 0
	_state_change_counter = 3.0

func _process_laser():
	if _state_change_counter < 0:
		_state = State.IDLE
		_state_change_counter = 1.0
	elif _shoot_counter >= 0:
		_shoot_counter += 1
		if _shoot_counter == SHOOT_SOUND_START:
			AudioPlayer.play_stream(AudioPlayer.boss_laser_fade, -10)
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
		_target = players[randi() % len(players)] # choose random player
		for area in areas:
			var distance = area.global_position.distance_to(_target.global_position)
			if  distance < shortest_distance:
				closest_area = area
				shortest_distance = distance
		self.position = closest_area.position
	
	else: # random new position
		self.position = areas[randi() % len(areas)].position
	
	_appear()
	AudioPlayer.play_stream(AudioPlayer.boss_warp, -8)

func _do_shoot():
	AudioPlayer.play_stream(AudioPlayer.destroyer_laser_attack, -5)
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
			collider.hit(SHOOT_DAMAGE * difficulty_multiplier, direction.normalized())
		elif collider.is_in_group("Satellite"):
			collider.damage(SHOOT_DAMAGE * 4 * difficulty_multiplier)
		elif collider.is_in_group("Planet"):
			var to_boss = (self.position - $ShootCast.get_collision_point()).normalized() * 15
			GameManager.possible_item_drop($ShootCast.get_collision_point() + to_boss, 0.5)

func shoot_color():
	var color = Color.red
	if _shoot_counter > SHOOT_CHANNEL_TIME:
		if (int(_shoot_counter / 3)) % 2 == 0:
			color = Color.orange
		color.a = 0.45
	color.a = pow(_shoot_counter / SHOOT_CHANNEL_TIME, 3) * 0.2 + 0.05
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