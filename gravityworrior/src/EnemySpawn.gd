extends Node2D

var _enemy_scene = preload("res://src/EnemyAssassin.tscn")
var has_spawned = false

func _ready() -> void:
	$SpawnTimer.connect("timeout", self, "on_SpawnTimer_timeout")
	
func on_SpawnTimer_timeout() -> void:
	if has_spawned:
		return

	if GameManager.current_game_state == GameManager.GameState.Fight:
		for i in range (1):
			$SpawnPath/SpawnPathLocation.set_offset(randi())
			var enemy = _enemy_scene.instance()
			add_child(enemy)
			enemy.position = $SpawnPath/SpawnPathLocation.position
		has_spawned = true