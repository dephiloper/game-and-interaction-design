extends Node2D

var current_game_state = GameState.Vote
var planets: Array = []
var players: Array = []
var assassins: Array = []
var destroyers: Array = []
var enemies: Array = []
var satellite: Satellite
var dead_players: int = 0

enum GameState {
	Fight,
	Vote
}

func _on_game_over():
	get_tree().change_scene("res://src/LoseScreenObjDestroyed.tscn")
	print("Game Over")

func add_planet(planet: Planet) -> void:
	planets.append(planet)
	
func register_player(player: Player) -> int:
	players.append(player)
	return len(players) - 1
	
func set_satellite(s: Satellite):
	satellite = s
	satellite.connect("game_over", self, "_on_game_over")

func get_living_destroyers():
	var living_destroyers = []
	for destroyer in destroyers:
		if not destroyer.has_to_be_removed():
			living_destroyers.append(destroyer)
	return living_destroyers

func get_living_players():
	var living_players = []
	for player in players:
		if not player.is_inactive:
			living_players.append(player)
	return living_players
