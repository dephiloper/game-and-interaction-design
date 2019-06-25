extends Node2D

const PLAYER_SCENE = preload("res://src/Player.tscn")
var current_game_state = GameState.Vote
var planets: Array = []
var players: Array = []
var assassins: Array = []
var exploding_assassins: Array = []
var destroyers: Array = []
var big_destroyers: Array = []
var enemies: Array = []
var satellite: Satellite

var _max_players: int = 4

enum GameState {
	Fight,
	Vote
}

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

func _on_game_over():
	get_tree().change_scene("res://src/LoseScreenObjDestroyed.tscn")

func add_planet(planet: Planet) -> void:
	planets.append(planet)
	
func register_player(player: Player) -> int:
	players.append(player)
	return len(players) - 1
	
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
	if len(get_living_players()) == 0:
		_on_game_over()