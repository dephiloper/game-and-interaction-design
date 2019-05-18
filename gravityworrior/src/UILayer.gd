extends CanvasLayer

func _process(delta: float) -> void:
	if is_instance_valid(GameManager.players[0]):
		$Label.text = str(GameManager.players[0].health)