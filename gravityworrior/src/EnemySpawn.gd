extends Node2D

var _assassin_scene = preload("res://src/Assassin.tscn")
var _destroyer_scene = preload("res://src/Destroyer.tscn")

var has_spawned = false
var wave_over = false
var kill_count: int
var current_level: int = 1
const level1: int = 1
const level2: int = 2
const level3: int = 3

const DESTROYER_PER_WAVE: int = 1
const ASSASSINS_PER_WAVE: int = 5

func _on_attack_player(player):
	for assassin in GameManager.assassins:
		assassin.attack_player_by_signal(player)

func _on_destroyer_got_attacked(player):
	for assassin in GameManager.assassins:
		assassin.attack_player_because_guard(player)

#warning-ignore:return_value_discarded
func _ready() -> void:
	$SpawnTimer.connect("timeout", self, "on_SpawnTimer_timeout")
	$WaveStateTimer.connect("timeout", self, "on_WaveStateTimer_timeout")
	set_level(current_level)

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

func _physics_process(_delta: float) -> void:
	_filter_has_to_be_removes(GameManager.assassins, false)
	_filter_has_to_be_removes(GameManager.destroyers, false)
	_filter_has_to_be_removes(GameManager.enemies, true)

func _create_assassin():
	var assassin = _create_enemy_by_scene(_assassin_scene)
	GameManager.assassins.append(assassin)
	assassin.connect("attack_player", self, "_on_attack_player")

func _create_destroyer():
	var destroyer = _create_enemy_by_scene(_destroyer_scene)
	GameManager.destroyers.append(destroyer)
	destroyer.connect("got_attacked", self, "_on_destroyer_got_attacked")

func _create_enemy_by_scene(scene):
	$SpawnPath/SpawnPathLocation.set_offset(randi())
	var enemy = scene.instance()
	add_child(enemy)
	GameManager.enemies.append(enemy)

	enemy.position = $SpawnPath/SpawnPathLocation.position
	
	return enemy

func on_WaveStateTimer_timeout() -> void:
	if has_spawned:
		if kill_count == 0:
			wave_over = true
			if (GameManager.enemies.size() == 0):
				GameManager.current_game_state = GameManager.GameState.Vote
				get_node("/root/Main/UILayer").reinstantiate_buff_selection()
				current_level +=1
				set_level(current_level)
				wave_over = false
				has_spawned = false

func on_SpawnTimer_timeout() -> void:
	if (GameManager.current_game_state == GameManager.GameState.Fight && !wave_over):
		for _i in range (DESTROYER_PER_WAVE):
			_create_destroyer()
		for _i in range(ASSASSINS_PER_WAVE):
			if GameManager.enemies.size() >= 10:
					break
			_create_assassin()
		has_spawned = true

func set_level(level: int):
	match level:
		1:
			kill_count = level1
		2:
			kill_count = level2
		3:
			kill_count = level3
		4:
			get_tree().change_scene("res://src/WinScreen.tscn")