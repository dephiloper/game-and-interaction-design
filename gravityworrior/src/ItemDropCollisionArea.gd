extends Area2D

func _ready() -> void:
	self.connect("body_entered", self, "_on_body_entered")

func _on_body_entered(player):
	if player.is_in_group("Player"):
		get_parent().collected(player.position)
		player.item_drop_collected(get_parent())