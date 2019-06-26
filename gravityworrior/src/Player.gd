extends KinematicBody2D

class_name Player

signal active_changed

# preloaded scenes
const INACTIVE_TEXTURE = preload("res://img/player_inactive.png")
const PLAYER_TEXTURE = preload("res://img/player.png")

const ON_PLANET_SPEED_MULTIPLIER: float = 3.0
const ON_PLANET_DRAG: float = 0.9
const OFF_PLANET_DRAG: float = 0.99
const OFF_PLANET_MAX_VELOCITY: int = 200
const BOOST_REDUCTION_VALUE: float = 1.0
const BOOST_RECHARGE_VALUE: float = 0.2
const CROSS_HAIR_DISTANCE: int = 128
const BORDER_BOUNDRY: int = 24
const BORDER_BOUNDRY_PULL: int = 24

export(Texture) var texture

# properties
var max_boost: float = 0.5
var max_health: float = 100.0

var controls: Controls # provides pressed actions of the player
var health: float = 100
var boost: float = max_boost
var is_inactive: bool = false
var color: Color

# fields
var _velocity = Vector2()
var _closest_planet: Planet = null
var _is_on_planet: bool = false
var _is_boosting: bool = false
var _is_cooldown: bool = false
var _shoot_dir = Vector2.RIGHT

var _movement_speed: float = 6.0
var _boost_speed_multiplier: float = 2.5
var _damage: float = 1.0
var _bullet_size_multiplier: float = 1.0
var _attack_speed_multiplier: float = 1.0

# public methods
func hit(damage: float) -> void:
	health = max(health - damage, 0)
	Input.start_joy_vibration(controls.input_device_id, 1, 0, 0.5)

func apply_buff(buff_type: String) -> void:
	match Buff.Types[buff_type]:
		Buff.Types.MovementSpeed:
			_movement_speed *= 1.2
		Buff.Types.BoostSpeed:
			_boost_speed_multiplier *= 1.1
		Buff.Types.BoostTime:
			max_boost *= 1.2
			boost = max_boost
		Buff.Types.Health:
			max_health *= 1.1
		Buff.Types.Damage:
			_damage *= 1.2
		Buff.Types.BiggerBullets:
			_bullet_size_multiplier *= 1.2
		Buff.Types.AttackSpeed:
			_attack_speed_multiplier *= 1.2

func _init() -> void:
	add_to_group("Player")
	var device_id = GameManager.register_player(self)
	controls = Controls.new()
	add_child(controls)
	controls.set_device_id(device_id)
	color = Color(randf(), randf(), randf())

func _ready() -> void:
	$PlayerSprite.texture = texture
	$PlayerSprite.modulate = color
	$Trail.texture = texture
	$CooldownTimer.connect("timeout", self, "_on_CooldownTimer_timeout")
	$ReviveArea.connect("body_entered", self, "_on_ReviveArea_body_entered")

func _process(_delta: float) -> void:
	$Hud.set_health_value(health, max_health)
	$Hud.set_boost_value(boost, max_boost)
	if health <= 0.0:
		is_inactive = true
		emit_signal("active_changed", not is_inactive)
		$PlayerSprite.texture = INACTIVE_TEXTURE
	if not is_inactive and _is_cooldown:
		$PlayerSprite.self_modulate.a = (sin($CooldownTimer.time_left * 16) + 1) / 2

func _physics_process(delta: float) -> void:
	if GameManager.current_game_state != GameManager.GameState.Fight:
		return
	
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
			elif collision.collider.is_in_group("Destroyer"):
				_velocity = _velocity.bounce(collision.normal)
				position += _velocity * 0.02
				_velocity *= 0.7

		# applying pull only when player is not boosting!
		elif not _is_boosting or _is_cooldown: 
			_velocity += pull
			
		_velocity += _calculate_boundary_pull()
			
		var max_velocity: float = OFF_PLANET_MAX_VELOCITY
		
		if _is_boosting:  # we press boost key
			if boost > 0.0:  # there is boost left
				$Trail.emitting = true
				max_velocity *= _boost_speed_multiplier
				boost = max(boost - BOOST_REDUCTION_VALUE * delta, 0.0)
				if boost == 0.0:  # we boosted and now there is no boost left 
					_is_cooldown = true
					$CooldownTimer.start()
		_velocity = _velocity.clamped(max_velocity)
		
	# we are not boosting and the cooldown timer is not started
	if not _is_boosting and $CooldownTimer.is_stopped():
			# recharge boost
			boost = min(boost + BOOST_RECHARGE_VALUE * delta, max_boost)

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
	
	var horizontal: float = controls.pressed("ui_right") - controls.pressed("ui_left")
	var vertical: float = controls.pressed("ui_down") - controls.pressed("ui_up")
	_is_boosting = false
	
	var movement_speed: float = _movement_speed
	if _is_on_planet:
		movement_speed *= ON_PLANET_SPEED_MULTIPLIER
		
	var movement_dir: Vector2 = Vector2(horizontal, vertical).normalized() * movement_speed
	_shoot_dir = _caculate_cross_hair_direction()
		
	if controls.pressed("shoot") > 0:
		_shoot(_shoot_dir.normalized())
		
	if controls.pressed("jump") > 0 and not _is_cooldown:
		_is_on_planet = false
		_is_boosting = true
		movement_dir *= _boost_speed_multiplier
		
	return movement_dir

func _calculate_boundary_pull() -> Vector2:
	var pull = Vector2(0,0)
	if position.x < BORDER_BOUNDRY:
		pull += Vector2(BORDER_BOUNDRY_PULL, 0)
	if position.y < BORDER_BOUNDRY:
		pull += Vector2(0, BORDER_BOUNDRY_PULL)
	if position.x > ProjectSettings.get_setting("display/window/size/width") - BORDER_BOUNDRY:
		pull += Vector2(-BORDER_BOUNDRY_PULL, 0)
	if position.y > ProjectSettings.get_setting("display/window/size/height") - BORDER_BOUNDRY:
		pull += Vector2(0, -BORDER_BOUNDRY_PULL)
	
	return pull

func _caculate_cross_hair_direction() -> Vector2:
	var horizontal: float = controls.pressed("aim_right") - controls.pressed("aim_left")
	var vertical: float = controls.pressed("aim_down") - controls.pressed("aim_up")
	var direction: Vector2 = Vector2(horizontal, vertical).normalized()
	if direction == Vector2.ZERO:
		direction = _shoot_dir
	$Gun/CrosshairSprite.visible = false if direction == Vector2.ZERO else true
	$Gun/CrosshairSprite.position = direction * CROSS_HAIR_DISTANCE 
	$Gun/GunSprite.rotation = direction.angle()
	$Gun/GunSprite.set_flip_v(direction.x < 0)
		
	return direction

func _shoot(dir: Vector2) -> void:
	$Gun.shoot(dir, _damage, _bullet_size_multiplier, _attack_speed_multiplier)

func _on_CooldownTimer_timeout() -> void:
	boost = max_boost
	_is_cooldown = false
	$PlayerSprite.self_modulate.a = 1.0
	
func _on_ReviveArea_body_entered(body: PhysicsBody2D) -> void:
	if is_inactive and body.is_in_group("Player"):
		if not (body as Player).is_inactive:
			is_inactive = false
			emit_signal("active_changed", not is_inactive)
			health = max_health
			$PlayerSprite.texture = texture