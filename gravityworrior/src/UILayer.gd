extends CanvasLayer

var labels: Array = []

func _ready() -> void:
	labels.append($Label)
	labels.append($Label2)
	labels.append($Label3)
	labels.append($Label4)
	$BuffSelection.position = get_viewport().size / 2

func _process(delta: float) -> void:
	if GameManager.current_game_state == GameManager.GameState.Vote:
		$BuffSelection.visible = true
	else:
		$BuffSelection.visible = false
	
	var i = 0
	for player in GameManager.players:
		if is_instance_valid(player):
			labels[i].text = str(player.health) + "/" + str(player.max_health)
			labels[i+1].text = str(int(player.boost * 100) / 100.0)
			i += 2