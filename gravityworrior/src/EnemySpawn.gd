extends Node2D

var _enemy_scene = preload("res://src/Enemy.tscn")

func _ready() -> void:
	$SpawnTimer.connect("timeout", self, "on_SpawnTimer_timeout")
	
func on_SpawnTimer_timeout() -> void:
	for i in range (5):
		$SpawnPath/SpawnPathLocation.set_offset(randi())
		var enemy = _enemy_scene.instance()
		add_child(enemy)
		enemy.position = $SpawnPath/SpawnPathLocation.position