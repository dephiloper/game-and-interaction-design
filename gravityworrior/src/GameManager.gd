extends Node2D

var current_game_state = GameState.Vote
var planets: Array = []
var players: Array = []
var satellite: Satellite

enum GameState {
	Fight,
	Vote
}

func _on_game_over():
	print("Game Over")

func add_planet(planet: Planet) -> void:
	planets.append(planet)
	
func register_player(player: Player) -> int:
	players.append(player)
	return len(players) - 1
	
func set_satellite(s: Satellite):
	satellite = s
	satellite.connect("game_over", self, "_on_game_over")
