extends Node2D

func _init() -> void:
	GameManager.setup()
	
func _ready() -> void:
	GameManager.create_players()