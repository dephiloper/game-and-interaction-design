extends Node2D

const PLAYER_SCENE = preload("res://src/Player.tscn")
const ITEM_DROP_SCENE = preload("res://src/ItemDrop.tscn")
const ITEM_DROP_PROBABILITY = 1.0

var current_game_state = GameState.Fight
var planets: Array = []
var players: Array = []
var assassins: Array = []
var exploding_assassins: Array = []
var destroyers: Array = []
var big_destroyers: Array = []
var enemies: Array = []
var satellite: Satellite

# 6 difficulty level
var max_difficulty = 5
var difficulty = 1

var _game_over_timer: Timer
var _max_players: int = 4
var _player_colors: Array = ["#FDD400","#B8FB3C","#FF2079","#03DDDC"]
var _is_game_over = false
var _camera: Camera2D

enum GameState {
	Fight,
	Vote
}

func setup() -> void:
	_game_over_timer = Timer.new()
	_game_over_timer.wait_time = 0.3
	_game_over_timer.one_shot = true
	add_child(_game_over_timer)
	_game_over_timer.connect("timeout", self, "_on_game_over_timer_timeout")
	
	var connected_joypads = Input.get_connected_joypads()
	for i in connected_joypads:
		var player = PLAYER_SCENE.instance()
		if i == _max_players-1:
			break
	
	if connected_joypads.size() == 0:
		var player = PLAYER_SCENE.instance()
	
	for player in players:
		player.connect("active_changed", self, "_player_active_changed")


func possible_item_drop(position: Vector2) -> void:
	if randf() < ITEM_DROP_PROBABILITY:
		var item_drop_instance = ITEM_DROP_SCENE.instance()
		item_drop_instance.init(position)
		get_node("/root/Main").add_child(item_drop_instance)


func add_planet(planet: Planet) -> void:
	planets.append(planet)

func register_player(player: Player) -> int:
	players.append(player)
	return len(players) - 1

func create_players() -> void:
	var spawn_points = get_node("/root/Main/SpawnPoints") 
	for player in players:
		get_node("/root/Main").add_child(player)
		player.position = spawn_points.get_child(player.controls.input_device_id).position
	
func get_player_color() -> Color:
	return _player_colors.pop_front()
	
func set_satellite(s: Satellite) -> void:
	satellite = s
	satellite.connect("game_over", self, "_on_game_over")

func get_difficulty_damage_multiplier():
	return 3.0 / (difficulty*2/5+1)

func get_difficulty_wave_multiplier():
	return (1.0/6.0) * difficulty + 1.0/3.0

func get_living_destroyers() -> Array:
	var living_destroyers: Array = []
	for destroyer in destroyers:
		if not destroyer.is_dead():
			living_destroyers.append(destroyer)

	for destroyer in big_destroyers:
		if not destroyer.is_dead():
			living_destroyers.append(destroyer)

	return living_destroyers

func get_living_players() -> Array:
	var living_players: Array = []
	for player in players:
		if not player.is_inactive:
			living_players.append(player)
	return living_players
	
func _player_active_changed(is_active: bool) -> void:
	if len(get_living_players()) == 0 and not _is_game_over:
		_on_game_over()
		
func _on_game_over():
	Engine.time_scale = 0.1
	_is_game_over = true
	_game_over_timer.start()
		
func _on_game_over_timer_timeout() -> void:
	if len(get_living_players()) == 0:
		get_tree().change_scene("res://src/LoseScreenWipedOut.tscn")
	else:
		get_tree().change_scene("res://src/LoseScreenObjDestroyed.tscn")
	Engine.time_scale = 1
	
func trigger_camera_shake(intensity: float = 1) -> void:
	get_node("/root/Main/MainCamera/").trigger_shake(intensity)