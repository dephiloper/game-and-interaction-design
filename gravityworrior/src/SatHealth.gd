extends Control

signal health_changed(health)

func _ready():
	var health_node = null
	for node in get_tree().get_nodes_in_group("sender"):
		if node.name == "godot_satellite-2":	
			health_node = node.get_node("Health")
			break
	$LifeBar.initialize(health_node.max_health)
	$LifeBar._on_SatHealth_health_changed(20) # Hier bitte den Health Value übergeben, wenn Alien Heath Sender
	

func _on_Health_health_changed(health):
	emit_signal("health_changed", health)
	
	
	

