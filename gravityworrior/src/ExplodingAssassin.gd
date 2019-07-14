extends "res://src/Assassin.gd"

const EXPLODING_SPEED_SCALE = 0.9
const EXPLOSION_RADIUS = 80.0
const EXPLODING_SQUARED_ATTACK_RANGE = 3000
const EXPLODING_ATTACK_CHANNEL_TIME = 0.1
const SQUARED_DAMAGE_RANGE = 6400
const EXPLOSION_DAMAGE = 35
const EXPLODING_MAX_HEALTH = 45

func _get_speed_scale():
	return EXPLODING_SPEED_SCALE

func _do_explosion():
	for player in _get_players_in_damage_range():
		player.hit(EXPLOSION_DAMAGE)
	for assassin in _get_assassins_in_damage_range():
		assassin.hit(EXPLOSION_DAMAGE, null)
	AudioPlayer.play_stream(AudioPlayer.explosion, 0)
	GameManager.trigger_camera_shake(2)

func _create_arrow():
	_arrow = ArrowScene.instance()
	_arrow.play("exploder")
	get_parent().add_child(_arrow)

func _get_max_health():
	return EXPLODING_MAX_HEALTH

func _start_attack_player():
	_do_explosion()
	_die()

func _should_collide_damage_player():
	return false

func _start_die():
	collision_mask = 0
	collision_layer = 0
	_start_channel_attack(null, false)

func _start_channel_attack(target_player, do_emit):
	state = ASSASSIN_STATE.ChannelAttack
	_channel_time = _get_attack_channel_time()

func _get_squared_attack_range():
	return EXPLODING_SQUARED_ATTACK_RANGE

func _get_attack_channel_time():
	return EXPLODING_ATTACK_CHANNEL_TIME

func attack_player_by_signal(player):
	pass

func _get_entities_in_range(entities):
	var entities_in_range = []
	for entity in entities:
		var distance_squared = position.distance_squared_to(entity.position)
		if distance_squared < SQUARED_DAMAGE_RANGE:
			entities_in_range.append(entity)
	return entities_in_range

func _get_players_in_damage_range():
	return _get_entities_in_range(GameManager.players)

func _get_assassins_in_damage_range():
	var assassins = []
	for assassin in GameManager.assassins:
		assassins.append(assassin)
	for assassin in GameManager.exploding_assassins:
		assassins.append(assassin)

	return _get_entities_in_range(assassins)

func _process_channel_attack(delta):
	_channel_time -= delta
	if _channel_time < 0:
		_start_attack_player()

func _process_dead(delta):
	_channel_time -= delta
	if _channel_time < 0:
		_has_to_be_removed = true
	else:
		var alpha = _channel_time / DIE_TIME
		$Sprite.modulate = Color(1, 1, 1, alpha)
		$Sprite/Head.position += Vector2(3, -3) * delta * 64 * alpha
		$Sprite/Head.rotation += delta * alpha
		$Sprite/Tail.position += Vector2(3, 3) * delta * 64 * alpha
		$Sprite/Tail.rotation += delta * alpha

		update()

func _draw():
	if is_dead():
		var color = Color.red
		color.a = _channel_time / DIE_TIME
		draw_circle(Vector2.ZERO, EXPLOSION_RADIUS, color)