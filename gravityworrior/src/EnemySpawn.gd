extends Node2D

var _assassin_scene = preload("res://src/Assassin.tscn")
var _exploding_assassin_scene = preload("res://src/ExplodingAssassin.tscn")
var _destroyer_scene = preload("res://src/Destroyer.tscn")
var _big_destroyer_scene = preload("res://src/BigDestroyer.tscn")

var _enemy_wave_class = preload("res://src/EnemyWave.gd")

var current_level_index: int
var current_wave

class WaveSetting:
	var spawn_amount
	var spawn_rates
	var global_spawn_rate_gain

	func _init(sa, sr, gsrg):
		spawn_amount = sa
		spawn_rates = sr
		global_spawn_rate_gain = gsrg

var wave_settings = [
	WaveSetting.new(2.5, [0.0, 0.0, 3.7, 0.0], 0.05),
	WaveSetting.new(2.7, [0.8, 0.0, 0.7, 0.0], 0.07),
	WaveSetting.new(8.0, [1.2, 0.0, 1.0, 0.0], 0.12),
	WaveSetting.new(11.0, [1.4, 0.7, 1.2, 0.0], 0.12),
	WaveSetting.new(15.0, [1.2, 0.8, 0.8, 0.7], 0.14)
]

func _on_attack_player(player):
	for assassin in GameManager.assassins:
		assassin.attack_player_by_signal(player)
	for assassin in GameManager.exploding_assassins:
		assassin.attack_player_by_signal(player)

func _on_destroyer_got_attacked(player):
	for assassin in GameManager.assassins:
		assassin.attack_player_because_guard(player)
	for assassin in GameManager.exploding_assassins:
		assassin.attack_player_because_guard(player)

func _on_assassin_got_attacked(player):
	for assassin in GameManager.assassins:
		assassin.attack_player_because_guard(player)
	for assassin in GameManager.exploding_assassins:
		assassin.attack_player_because_guard(player)

#warning-ignore:return_value_discarded
func _ready() -> void:
	current_level_index = 0
	set_level(current_level_index)

func _filter_has_to_be_removes(enemies, free):
	var index = 0
	while index < enemies.size():
		var enemy = enemies[index]
		if enemy.has_to_be_removed():
			enemies.remove(index)
			if free:
				enemy.queue_free()
		else:
			index += 1

func _create_assassin():
	var assassin = _create_enemy_by_scene(_assassin_scene)
	GameManager.assassins.append(assassin)
	assassin.connect("attack_player", self, "_on_attack_player")
	assassin.connect("assassin_got_attacked", self, "_on_assassin_got_attacked")

func _create_exploding_assassin():
	var assassin = _create_enemy_by_scene(_exploding_assassin_scene)
	GameManager.exploding_assassins.append(assassin)
	assassin.connect("attack_player", self, "_on_attack_player")
	assassin.connect("assassin_got_attacked", self, "_on_assassin_got_attacked")

func _create_destroyer():
	var destroyer = _create_enemy_by_scene(_destroyer_scene)
	GameManager.destroyers.append(destroyer)
	destroyer.connect("destroyer_got_attacked", self, "_on_destroyer_got_attacked")

func _create_big_destroyer():
	var destroyer = _create_enemy_by_scene(_big_destroyer_scene)
	GameManager.big_destroyers.append(destroyer)
	destroyer.connect("destroyer_got_attacked", self, "_on_destroyer_got_attacked")

func _create_enemy_by_scene(scene):
	$SpawnPath/SpawnPathLocation.set_offset(randi())
	var enemy = scene.instance()
	add_child(enemy)
	GameManager.enemies.append(enemy)

	enemy.position = $SpawnPath/SpawnPathLocation.position
	
	return enemy

func _physics_process(delta: float) -> void:
	_filter_has_to_be_removes(GameManager.assassins, false)
	_filter_has_to_be_removes(GameManager.exploding_assassins, false)
	_filter_has_to_be_removes(GameManager.destroyers, false)
	_filter_has_to_be_removes(GameManager.big_destroyers, false)
	_filter_has_to_be_removes(GameManager.enemies, true)

	if GameManager.current_game_state == GameManager.GameState.Fight:
		_spawn_enemies(delta)

func _spawn_enemies(delta):
	var new_enemies = current_wave.process_new_enemies(delta)
	for new_enemy in new_enemies:
		match new_enemy:
			0: _create_assassin()
			1: _create_exploding_assassin()
			2: _create_destroyer()
			3: _create_big_destroyer()

	if current_wave.finished():
		GameManager.current_game_state = GameManager.GameState.Vote
		get_node("/root/Main/UILayer").reinstantiate_buff_selection()
		current_level_index += 1
		set_level(current_level_index)

func set_level(level: int):
	if level >= len(wave_settings):
		get_tree().change_scene("res://src/WinScreen.tscn")
	else:
		var wave_setting = wave_settings[level]
		var num_player_multiplier = sqrt(len(GameManager.players))

		var spawn_rates = wave_setting.spawn_rates
		for i in range(len(spawn_rates)):
			spawn_rates[i] = spawn_rates[i] * num_player_multiplier

		current_wave = _enemy_wave_class.new(
			wave_setting.spawn_amount,
			wave_setting.spawn_rates,
			wave_setting.global_spawn_rate_gain * num_player_multiplier
		)