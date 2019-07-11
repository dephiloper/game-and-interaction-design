extends Node2D

class_name Buff

var type
var _initial_scale: Vector2 = Vector2.ZERO
const Types: Dictionary = {
	MovementSpeed = ["Movement Speed", preload("res://img/buff_movement_speed.png")],
	BoostSpeed = ["Boost Speed", preload("res://img/buff_boost_speed.png")],
	Boost = ["More Boost", preload("res://img/buff_boost_time.png")],
	Health = ["More Health", preload("res://img/buff_more_health.png")],
	Damage = ["More Damage", preload("res://img/buff_more_dmg.png")],
	BiggerBullets = ["Bigger Bullets", preload("res://img/buff_bigger_bullets.png")],
	AttackSpeed = ["Faster Bullets", preload("res://img/buff_bullet_speed.png")]
}

func reset() -> void:
	for player_selection_sprite in $BuffSprite.get_children():
		(player_selection_sprite as Sprite).scale = _initial_scale

func select(player: int) -> void:
	$BuffSprite.get_children()[player].visible = true

func deselect(player: int) -> void:
	$BuffSprite.get_children()[player].visible = false
	
func highlight(player: int) -> void:
	$BuffSprite.get_children()[player].scale *= 1.5  # todo tween?
	
func set_type(new_type: String) -> void:
	type = new_type
	$Label.text = Types[new_type][0]
	$InnerBuffSprite.texture = Types[new_type][1]

func _ready() -> void:
	_initial_scale = $BuffSprite/Player0Selection.scale
	var players: Array = GameManager.players
	for i in range(len(players)):
		#$BuffSprite.get_child(i).texture = players[i].texture
		$BuffSprite.get_child(i).modulate = players[i].color