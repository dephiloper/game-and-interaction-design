extends Node2D

var huds: Array = []

const BUFF_SELECTION_SCENE = preload("res://src/BuffSelection.tscn")

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

func _process(_delta: float) -> void:
	var i = 0
	for player in GameManager.players:
		if is_instance_valid(player):
			huds[i].set_health_value(player.health, player.max_health)
			huds[i].set_boost_value(player.boost, player.max_boost)
			huds[i].set_ammo_value(player.gun.current_ammo, player.gun.ammo_capacity)
			i+=1
			
			
			
func reinstantiate_buff_selection():
	var buff_scene = BUFF_SELECTION_SCENE.instance()
	add_child(buff_scene)
	buff_scene.name = "BuffSelection"
	buff_scene.position = get_viewport().size / 2
	
	#$SatteliteBar.set_health_value(GameManager.satellite.health)


