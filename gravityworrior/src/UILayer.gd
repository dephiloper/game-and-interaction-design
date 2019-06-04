extends CanvasLayer

var labels: Array = []

func _ready() -> void:
	labels.append($Label)
	labels.append($Label2)
	labels.append($Label3)
	labels.append($Label4)

func _process(delta: float) -> void:
	var i = 0
	for player in GameManager.players:
		if is_instance_valid(player):
			labels[i].text = str(player.health)
			labels[i+1].text = str(int(player.boost * 100) / 100.0)
			i += 2