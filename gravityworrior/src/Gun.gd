extends Node2D

class_name Gun

enum TYPE {
	MACHINE, GATLING, RIFLE, LAUNCHER
}

const BULLET_SCENE = preload("res://src/Bullet.tscn")

var base_damage: float = 10
var fire_rate: float = 5

func shoot(dir: Vector2, _damage_buff, _bullet_size_multiplier, _bullet_speed_multiplier) -> void: 
	#shoot mechanism
	if ($FirerateTimer.get_time_left() == 0):
		var b: Bullet = BULLET_SCENE.instance()
		b.init(dir, base_damage * _damage_buff, _bullet_size_multiplier, _bullet_speed_multiplier)
		b.position = global_position
		$"/root/Main".add_child(b)
		$FirerateTimer.start()

func _ready():
	$FirerateTimer.wait_time = 1/fire_rate
	$FirerateTimer.set_one_shot(true)
	_apply_gun_visuals(50, "res://img/gun01.png")

func _apply_gun_visuals(offset, texture_path) -> void:
	var gun_offset = Vector2(offset, 0)
	$GunSprite.set_offset(gun_offset)
	$GunSprite.texture = load(texture_path)