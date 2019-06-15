extends Node2D

class_name Buff

var type

const Types: Dictionary = {
	MovementSpeed = "Movement Speed",
	BoostSpeed = "Boost Speed",
	BoostTime = "Boost Time",
	Health = "More Health",
	Damage = "More Damage",
	Ammo = "More Ammo",
	BiggerBullets = "Bigger Bullets",
	AttackSpeed = "Faster Bullets",
}

func select(player: int) -> void:
	$BuffSprite.get_children()[player].visible = true

func deselect(player: int) -> void:
	$BuffSprite.get_children()[player].visible = false
	
func highlight(player: int) -> void:
	$BuffSprite.get_children()[player].scale *= 1.5  # todo tween?
	
func set_type(new_type: String) -> void:
	type = new_type
	$Label.text = Types[new_type]
	#$InnerBuffSprite.texture = load("res://img/buffs/" + type.to_lower() + ".png")

func _ready() -> void:
	var players: Array = GameManager.players
	for i in range(len(players)):
		$BuffSprite.get_child(i).texture = players[i].texture