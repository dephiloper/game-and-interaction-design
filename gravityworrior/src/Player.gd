extends KinematicBody2D

class_name Player

const MOVEMENT_SPEED: int = 10
const JUMP_SPEED_MULTIPLIER: float = 2.5

const ON_PLANET_DRAG: float = 0.9
const ON_PLANET_SPEED_MULTIPLIER: float = 3.0
const OFF_PLANET_DRAG: float = 0.98
const OFF_PLANET_MAX__velocity: int = 300

var health: int = 100

var _bullet_scene = preload("res://src/Bullet.tscn")

var _velocity = Vector2()
var _closest_planet = null
var _is_on_planet: bool = false
var _is_boosting: bool = false
var _last_shoot_dir = Vector2.RIGHT

func hit() -> void:
	health -= 10

func _init() -> void:
	add_to_group("Player")
	GameManager.add_player(self)

func _physics_process(delta: float) -> void:
	if _is_on_planet == true:
		_velocity += _calculate_player_movement()
		_velocity *= ON_PLANET_DRAG
		var diff: Vector2 = _closest_planet.position - position
		_velocity = move_and_slide_with_snap(_velocity, diff, -diff)
		# _velocity = _velocity.slide(diff.normalized())
		# _velocity = _velocity.slide(-diff.normalized())
	else:
		_velocity += _calculate_player_movement()
		_velocity *= OFF_PLANET_DRAG
		var collision = move_and_collide(_velocity * delta)
		if collision:
			if collision.collider.is_in_group("Planet"):
				_is_on_planet = true
		else:
			_velocity += _calculate_gravitational_pull()
			
		var max__velocity: float = OFF_PLANET_MAX__velocity
		if _is_boosting:
			max__velocity *= JUMP_SPEED_MULTIPLIER
		_velocity = _velocity.clamped(max__velocity)

func _calculate_gravitational_pull() -> Vector2:
	var pull: Vector2 = Vector2()
	var closest_distance: float = INF
	for planet in GameManager.planets:
		var distance: float = position.distance_squared_to(planet.position)
		if distance < closest_distance:
			closest_distance = distance
			_closest_planet = planet
		
		var force: float = planet.gravity / distance
		pull += (planet.position - position).normalized() * force
		
	return pull
	
func _calculate_player_movement() -> Vector2:
	var horizontal: float = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	var vertical: float = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	_is_boosting = false
	
	var movement_speed: float = MOVEMENT_SPEED
	if _is_on_planet:
		movement_speed *= ON_PLANET_SPEED_MULTIPLIER
		
	var movement_dir: Vector2 = Vector2(horizontal, vertical).normalized() * movement_speed
		
	var shoot_dir: Vector2 = _caculate_cross_hair_direction()
		
	if Input.is_action_just_pressed("shoot"):
		if shoot_dir == Vector2.ZERO:
			shoot_dir = movement_dir
		if shoot_dir == Vector2.ZERO:
			shoot_dir = _last_shoot_dir
			
		shoot(shoot_dir.normalized())
		_last_shoot_dir = shoot_dir
		
	
	if Input.is_action_pressed("jump"):
		_is_on_planet = false
		_is_boosting = true
		movement_dir *= JUMP_SPEED_MULTIPLIER
		
	return movement_dir
	
func _caculate_cross_hair_direction() -> Vector2:
	var horizontal: float = Input.get_action_strength("aim_right") - Input.get_action_strength("aim_left")
	var vertical: float = Input.get_action_strength("aim_down") - Input.get_action_strength("aim_up")
	var direction: Vector2 = Vector2(horizontal, vertical).normalized()
	$CrossHairSprite.visible = false if direction == Vector2.ZERO else true
	$CrossHairSprite.position = direction * 128
	
	return direction
	
func shoot(dir: Vector2) -> void:
	var b: Bullet = _bullet_scene.instance()
	b.init(dir)
	b.position = global_position
	$"/root/Main".add_child(b)