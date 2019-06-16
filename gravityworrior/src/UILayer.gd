extends Node2D

var huds: Array = []

func _ready() -> void:
	huds.append($HudP0)
	huds.append($HudP1)
	huds.append($HudP2)
	huds.append($HudP3)
	
	var i = 0
	for hud in huds:
		if len(GameManager.players) <= i:
			hud.visible = false
			
		i+=1
	
	$HudP1.rotate_bars()
	$HudP3.rotate_bars()
	$BuffSelection.position = get_viewport().size / 2

func _process(delta: float) -> void:
	if GameManager.current_game_state == GameManager.GameState.Vote:
		$BuffSelection.visible = true
	else:
		$BuffSelection.visible = false
	
	var i = 0
	for player in GameManager.players:
		if is_instance_valid(player):
			huds[i].set_health_value(player.health, player.max_health)
			huds[i].set_boost_value(player.boost, player.max_boost)
			i+=1
			
	#$SatteliteBar.set_health_value(GameManager.satellite.health)


