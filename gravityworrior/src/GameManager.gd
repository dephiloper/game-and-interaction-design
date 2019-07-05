extends Node2D

const PLAYER_SCENE = preload("res://src/Player.tscn")

var current_game_state = GameState.Fight
var planets: Array = []
var players: Array = []
var assassins: Array = []
var exploding_assassins: Array = []
var destroyers: Array = []
var big_destroyers: Array = []
var enemies: Array = []
var satellite: Satellite

var _game_over_timer: Timer
var _max_players: int = 4
var _player_colors: Array = ["#22d6b6", "#9c495f", "#889a4e", "#d4b2ef", "#3ea458", "#a242b2", "#94ccd3", "#7cd474", "#339bd3", "#e1c31b"]
var _is_game_over = false

enum GameState {
	Fight,
	Vote
}

func _init() -> void:
	_game_over_timer = Timer.new()
	_game_over_timer.wait_time = 0.2
	_game_over_timer.one_shot = true
	add_child(_game_over_timer)
	_game_over_timer.connect("timeout", self, "_on_game_over_timer_timeout")

func _ready() -> void:
	var spawn_points = get_node("/root/Main/SpawnPoints")
	var connected_joypads = Input.get_connected_joypads()
	for i in connected_joypads:
		var player = PLAYER_SCENE.instance()
		player.position = spawn_points.get_children()[i].position
		get_node("/root/Main").add_child(player)
		if i == _max_players-1:
			break
	
	if connected_joypads.size() == 0:
		var player = PLAYER_SCENE.instance()
		player.position = spawn_points.get_children()[0].position
		get_node("/root/Main").add_child(player)
	
	for player in players:
		player.connect("active_changed", self, "_player_active_changed")

func add_planet(planet: Planet) -> void:
	planets.append(planet)
	
func register_player(player: Player) -> int:
	players.append(player)
	return len(players) - 1
	
func random_player_color() -> Color:
	var color = _player_colors[randi() % len(_player_colors)]
	_player_colors.erase(color)
	return color
	
func set_satellite(s: Satellite) -> void:
	satellite = s
	satellite.connect("game_over", self, "_on_game_over")

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
	get_tree().change_scene("res://src/LoseScreenWipedOut.tscn")
	Engine.time_scale = 1