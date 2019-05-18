extends Node

var planets: Array = []
var players: Array = []

func add_planet(planet: Planet) -> void:
	planets.append(planet)
	
func add_player(player: Player) -> void:
	players.append(player)