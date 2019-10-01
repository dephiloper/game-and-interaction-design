extends Area2D

func _ready() -> void:
	self.connect("body_entered", self, "_on_body_entered")

func _on_body_entered(body):
	if body.is_in_group("Player"):
		body.apply_item(get_parent().get_item_kind())
		get_parent().queue_free()