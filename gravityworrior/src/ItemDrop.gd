extends Node2D

const TIME_TO_FREE = 200

var _free_counter
var _item_drop_kind

enum ItemDropKind {
	FireRate,
	HealthRestore,
	MultiShot,
	Shield
}


func _random_kind():
	var index = randi() % 4
	if index == 0:
		return ItemDropKind.FireRate
	elif index == 1:
		return ItemDropKind.HealthRestore
	elif index == 2:
		return ItemDropKind.MultiShot
	elif index == 3:
		return ItemDropKind.Shield
	assert false


func get_item_kind():
	return self._item_drop_kind


func _set_sprite():
	match self._item_drop_kind:
		ItemDropKind.FireRate:
			$AnimatedSprite.play("FireRate")
		ItemDropKind.HealthRestore:
			$AnimatedSprite.play("HealthRestore")
		ItemDropKind.MultiShot:
			$AnimatedSprite.play("MultiShot")
		ItemDropKind.Shield:
			$AnimatedSprite.play("Shield")


func init(position: Vector2):
	add_to_group("ItemDrop")
	$ItemDropCollisionArea.add_to_group("ItemDrop")
	self.position = position
	self._item_drop_kind = _random_kind()
	self._set_sprite()
	self._free_counter = TIME_TO_FREE


func _physics_process(_delta: float) -> void:
	self._free_counter -= 1
	if self._free_counter <= 0: 
		queue_free()
		return