extends Node

var current_game_state = GameState.Fight
var planets: Array = []
var players: Array = []

func add_planet(planet: Planet) -> void:
	planets.append(planet)
	
func register_player(player: Player) -> int:
	players.append(player)
	return len(players) - 1
	
enum GameState {
	Fight,
	Vote
}