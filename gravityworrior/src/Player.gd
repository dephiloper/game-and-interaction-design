extends KinematicBody2D

class_name Player

# preloaded scenes
const BULLET_SCENE = preload("res://src/Bullet.tscn")
const INACTIVE_TEXTURE = preload("res://img/player_inactive.png")

const MOVEMENT_SPEED: int = 10
const JUMP_SPEED_MULTIPLIER: float = 2.5

const ON_PLANET_DRAG: float = 0.9
const ON_PLANET_SPEED_MULTIPLIER: float = 3.0
const OFF_PLANET_DRAG: float = 0.99
const OFF_PLANET_MAX_VELOCITY: int = 300

const INITIAL_HEALTH: int = 100
const INITIAL_BOOST_VALUE: float = 0.5
const BOOST_REDUCTION_VALUE: float = 1.0
const BOOST_RECHARGE_VALUE: float = 0.2

const CROSS_HAIR_DISTANCE: int = 128

export(Texture) var texture

# properties
var health: int = 100
var is_inactive: bool = false

# fields
var _input_map: Dictionary = {}  # provides pressed actions of the player

var _velocity = Vector2()
var _closest_planet: Planet = null
var _is_on_planet: bool = false
var _is_boosting: bool = false
var _is_cooldown: bool = false
var _boost: float = INITIAL_BOOST_VALUE
var _last_shoot_dir = Vector2.RIGHT

# public methods
func hit(damage: float) -> void:
	if health > 0:
		health -= damage
	else:
		is_inactive = true
		$PlayerSprite.texture = INACTIVE_TEXTURE
	# Input.start_joy_vibration(device_id, 1, 0, 0.5)

func _init() -> void:
	add_to_group("Player")
	var device_id = GameManager.register_player(self)
	var controls = Controls.new()
	add_child(controls)
	controls.set_device_id(device_id)
	_input_map = controls.input_map

func _ready() -> void:
	$PlayerSprite.texture = texture
	$Trail.texture = texture
	$CooldownTimer.connect("timeout", self, "_on_CooldownTimer_timeout")
	$ReviveArea.connect("body_entered", self, "_on_ReviveArea_body_entered")

func _process(delta: float) -> void:
	if not is_inactive and _is_cooldown:
		$PlayerSprite.self_modulate.a = (sin($CooldownTimer.time_left * 8) + 1) / 2

func _physics_process(delta: float) -> void:
	$Trail.emitting = false
	
	# we are on planet
	if _is_on_planet == true:
		_velocity += _calculate_player_movement()
		_velocity *= ON_PLANET_DRAG
		var diff: Vector2 = _closest_planet.position - position
		_velocity = move_and_slide_with_snap(_velocity, diff, -diff)
		_velocity = _velocity.slide(diff.normalized())
		_velocity = _velocity.slide(-diff.normalized())
	
	# not on planet
	else:
		_velocity += _calculate_player_movement()
		_velocity *= OFF_PLANET_DRAG
		var pull: Vector2 = _calculate_gravitational_pull()
		var collision = move_and_collide(_velocity * delta)
		if collision:
			if collision.collider.is_in_group("Planet"):
				_is_on_planet = true
		# applying pull only when player is not boosting!
		elif not _is_boosting or _is_cooldown: 
			_velocity += pull
			
		var max_velocity: float = OFF_PLANET_MAX_VELOCITY
		
		if _is_boosting:  # we press boost key
			if _boost > 0.0:  # there is boost left
				$Trail.emitting = true
				max_velocity *= JUMP_SPEED_MULTIPLIER
				_boost = max(_boost - BOOST_REDUCTION_VALUE * delta, 0.0)
				if _boost == 0.0:  # we boosted and now there is no boost left 
					_is_cooldown = true
					$CooldownTimer.start()
		_velocity = _velocity.clamped(max_velocity)
		
	# we are not boosting and the cooldown timer is not started
	if not _is_boosting and $CooldownTimer.is_stopped():
			# recharge boost
			_boost = min(_boost + BOOST_RECHARGE_VALUE * delta, 1.0)

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
	if is_inactive:
		return Vector2.ZERO
	
	var horizontal: float = _input_map["ui_right"] - _input_map["ui_left"]
	var vertical: float = _input_map["ui_down"] - _input_map["ui_up"]
	_is_boosting = false
	
	var movement_speed: float = MOVEMENT_SPEED
	if _is_on_planet:
		movement_speed *= ON_PLANET_SPEED_MULTIPLIER
		
	var movement_dir: Vector2 = Vector2(horizontal, vertical).normalized() * movement_speed
	var shoot_dir: Vector2 = _caculate_cross_hair_direction()
		
	if _input_map["shoot"] > 0:
		_input_map["shoot"] = 0.0
		if shoot_dir == Vector2.ZERO:
			shoot_dir = movement_dir
		if shoot_dir == Vector2.ZERO:
			shoot_dir = _last_shoot_dir
			
		_shoot(shoot_dir.normalized())
		_last_shoot_dir = shoot_dir
		
	
	if _input_map["jump"] > 0 and not _is_cooldown:
		_is_on_planet = false
		_is_boosting = true
		movement_dir *= JUMP_SPEED_MULTIPLIER
		
	return movement_dir

func _caculate_cross_hair_direction() -> Vector2:
	var horizontal: float = _input_map["aim_right"] - _input_map["aim_left"]
	var vertical: float = _input_map["aim_down"] - _input_map["aim_up"]
	var direction: Vector2 = Vector2(horizontal, vertical).normalized()
	$CrossHairSprite.visible = false if direction == Vector2.ZERO else true
	$CrossHairSprite.position = direction * CROSS_HAIR_DISTANCE
	
	return direction

func _shoot(dir: Vector2) -> void:
	var b: Bullet = BULLET_SCENE.instance()
	b.init(dir)
	b.position = global_position
	$"/root/Main".add_child(b)

func _on_CooldownTimer_timeout() -> void:
	_boost = INITIAL_BOOST_VALUE
	_is_cooldown = false
	$PlayerSprite.self_modulate.a = 1.0
	
func _on_ReviveArea_body_entered(body: PhysicsBody2D) -> void:
	if is_inactive and body.is_in_group("Player"):
		if not (body as Player).is_inactive:
			is_inactive = false
			health = INITIAL_HEALTH
			$PlayerSprite.texture = texture