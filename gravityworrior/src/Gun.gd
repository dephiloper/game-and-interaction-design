extends Node2D

class_name Gun

const BULLET_SCENE = preload("res://src/Bullet.tscn")
const CROSS_HAIR_DISTANCE: int = 128
const GUN_POINTER_COLOR: Color = Color(1, 0, 0, 0.25)
const MULTI_SHOT_DEVIATION = 0.15

var shoot_dir = Vector2.RIGHT
var can_shoot: bool = true
var _base_damage: float = 10
var _fire_rate: float = 5
var _controls: Controls
var _offset: Vector2 = Vector2(4,2)
var _alternative_aiming_enabled: bool = false
var _alternative_aiming_pressed_time: float = 0
var multi_shot_enabled = false

var _show_laser_pointer: bool = true

func set_controls(controls: Controls) -> void:
	_controls = controls

func send_bullet(shoot_direction, _damage_buff, _bullet_size_multiplier, _bullet_speed_multiplier):
	var b: Bullet = BULLET_SCENE.instance()
	b.init(shoot_direction, _base_damage * _damage_buff, _bullet_size_multiplier, _bullet_speed_multiplier)
	b.position = $GunSprite/BarrelPosition.global_position
	$"/root/Main".add_child(b)

func shoot(_damage_buff, _bullet_size_multiplier, _bullet_speed_multiplier) -> void: 
	if not can_shoot: return
	
	if ($FirerateTimer.get_time_left() == 0):
		AudioPlayer.play_stream(AudioPlayer.player_shot, -18)
		send_bullet(shoot_dir, _damage_buff, _bullet_size_multiplier, _bullet_speed_multiplier)
		if multi_shot_enabled:
			send_bullet(shoot_dir.rotated(MULTI_SHOT_DEVIATION), _damage_buff, _bullet_size_multiplier, _bullet_speed_multiplier)
			send_bullet(shoot_dir.rotated(-MULTI_SHOT_DEVIATION), _damage_buff, _bullet_size_multiplier, _bullet_speed_multiplier)
		$FirerateTimer.start()

func _physics_process(delta: float) -> void:
	if GameManager.current_game_state != GameManager.GameState.Fight:
		return

	if _controls.pressed("toggle_alternative_aiming"):
		_alternative_aiming_pressed_time += delta
		if _alternative_aiming_pressed_time > 1:
			# _alternative_aiming_enabled = !_alternative_aiming_enabled
			_alternative_aiming_pressed_time = 0
	else:
		_alternative_aiming_pressed_time = 0
	
	if _controls.just_pressed("toggle_laser_pointer"):
		_show_laser_pointer = !_show_laser_pointer
		

	shoot_dir = _caculate_cross_hair_direction()
	$CrosshairSprite.visible = false if shoot_dir == Vector2.ZERO else true
	$CrosshairSprite.position = shoot_dir * CROSS_HAIR_DISTANCE
	$GunSprite.rotation = shoot_dir.angle()
	$GunSprite.set_flip_v(shoot_dir.x < 0)
	$GunSprite/BarrelPosition.position.y = 10 if (shoot_dir.x < 0) else -10 
	position = _offset if shoot_dir.x >= 0 else Vector2(-_offset.x, _offset.y)
	update()

func _draw() -> void:
	if _show_laser_pointer:
		draw_line($GunSprite.position, $CrosshairSprite.position, GUN_POINTER_COLOR, 2)

func _caculate_cross_hair_direction() -> Vector2:
	var horizontal: float = 0
	var vertical: float = 0
	
	if not _alternative_aiming_enabled:
		horizontal = _controls.pressed("aim_right") - _controls.pressed("aim_left")
		vertical = _controls.pressed("aim_down") - _controls.pressed("aim_up")
	else:
		horizontal = _controls.pressed("ui_right") - _controls.pressed("ui_left")
		vertical = _controls.pressed("ui_down") - _controls.pressed("ui_up")
	
	var direction: Vector2 = Vector2(horizontal, vertical).normalized()
	if direction == Vector2.ZERO:
		direction = shoot_dir
		
	return direction

func enable_fire_rate():
	$FirerateTimer.wait_time = 1.0 / (_fire_rate * 2)

func disable_fire_rate():
	$FirerateTimer.wait_time = 1.0 / _fire_rate

func enable_multi_shot():
	multi_shot_enabled = true

func disable_multi_shot():
	multi_shot_enabled = false

func _ready():
	$FirerateTimer.wait_time = 1.0 / _fire_rate
	$FirerateTimer.set_one_shot(true)