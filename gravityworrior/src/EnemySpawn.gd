extends Node2D

export (PackedScene) var Enemies
var score

func _on_EnemyTimer_timeout():
    # Choose a random location on Path2D.
    $EnemyPath/EnemySpawnLocation.set_offset(randi())
    # Create a Mob instance and add it to the scene.
    var enemy = Enemies.instance()
    add_child(enemy)
    # Set the mob's direction perpendicular to the path direction.
    var direction = $EnemyPath/EnemySpawnLocation.rotation + PI / 2
    # Set the mob's position to a random location.
    enemy.position = $EnemyPath/EnemySpawnLocation.position
    # Add some randomness to the direction.
    direction += rand_range(-PI / 4, PI / 4)
    enemy.rotation = direction
    # Set the velocity (speed & direction).
    enemy.linear_velocity = Vector2(rand_range(enemy.min_speed, enemy.max_speed), 0)
    enemy.linear_velocity = enemy.linear_velocity.rotated(direction)

var planets: Array = []

func _ready() -> void:
	randomize()
	$EnemyTimer.start()
	for child in get_children():
		var planet = child as Planet
		if planet:
			planets.append(planet)