extends Node2D

var _assassin_scene = preload("res://src/EnemyAssassin.tscn")
var assassin_list = []
var has_spawned = false

func _on_attack_player(player):
	for assassin in assassin_list:
		assassin.attack_player_by_signal(player)

#warning-ignore:return_value_discarded
func _ready() -> void:
	$SpawnTimer.connect("timeout", self, "on_SpawnTimer_timeout")

func _physics_process(_delta: float) -> void:
	var index = 0
	while index < assassin_list.size():
		if assassin_list[index].is_dead():
			assassin_list.remove(index)
		else:
			index += 1
	

func on_SpawnTimer_timeout() -> void:
	if has_spawned:
		#return
		pass

	if GameManager.current_game_state == GameManager.GameState.Fight:
		for _i in range (5):
			$SpawnPath/SpawnPathLocation.set_offset(randi())
			var assassin = _assassin_scene.instance()
			assassin.connect("attack_player", self, "_on_attack_player")
			add_child(assassin)
			assassin_list.append(assassin)
			
			assassin.position = $SpawnPath/SpawnPathLocation.position
		has_spawned = true