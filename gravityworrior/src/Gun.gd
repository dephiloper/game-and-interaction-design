extends Node2D

class_name Gun

enum TYPE {
	MACHINE, GATLING, RIFLE, LAUNCHER
}

const BULLET_SCENE = preload("res://src/Bullet.tscn")

var base_damage: float
var reload_time: float
var fire_rate: float
var current_ammo: int 
var ammo_capacity: int
var bullet_speed: float
var bullet_size: float
var aoe: bool
var gravity_affection: float
var is_reloading: bool = false

func _reload() -> void:
	if (current_ammo == 0 && !is_reloading):
		$ReloadTimer.start()
		is_reloading = true
		
	if ($ReloadTimer.get_time_left() == 0):
		_reset_magazine()
		is_reloading = false;

func _reset_magazine() -> void:
	current_ammo = ammo_capacity

func shoot(dir: Vector2, _damage_buff, _bullet_size_multiplier, _bullet_speed_multiplier) -> void: 
	if (current_ammo == 0):
		_reload()
	if (current_ammo > 0):
		#shoot mechanism
		if ($FirerateTimer.get_time_left() == 0):
			var b: Bullet = BULLET_SCENE.instance()
			b.init(dir, _damage_buff, base_damage, bullet_size, _bullet_size_multiplier, bullet_speed, _bullet_speed_multiplier, aoe, gravity_affection)
			b.position = global_position
			$"/root/Main".add_child(b)
			current_ammo -= 1
			$FirerateTimer.start()

func _ready():
	$ReloadTimer.wait_time = reload_time
	$ReloadTimer.set_one_shot(true)
	$FirerateTimer.wait_time = 1/fire_rate
	$FirerateTimer.set_one_shot(true)

func _apply_gun_visuals(offset, texture_path) -> void:
	var gun_offset = Vector2(offset, 0)
	$GunSprite.set_offset(gun_offset)
	$GunSprite.texture = load(texture_path)

func gear_up(type) -> void:
	match type:
		TYPE.MACHINE:
			base_damage = 10
			fire_rate = 8
			ammo_capacity = 20
			current_ammo = ammo_capacity
			bullet_speed = 1.2
			bullet_size = 5
			aoe = false
			gravity_affection = 0.995
			reload_time = 1.5
			_apply_gun_visuals(50, "res://img/gun01.png")
			#define Bullet texture
		
		TYPE.GATLING:
			base_damage = 2
			fire_rate = 50;
			ammo_capacity = 50
			current_ammo = ammo_capacity
			bullet_speed = 7
			bullet_size = 3
			aoe = false
			gravity_affection = 5
			reload_time = 5
			_apply_gun_visuals(50, "res://img/gun01.png")
			#define Bullet texture
		
		TYPE.RIFLE:
			base_damage = 30
			fire_rate = 2;
			ammo_capacity = 3
			bullet_speed = 10
			current_ammo = ammo_capacity
			bullet_size = 5
			aoe = false
			gravity_affection = 0
			reload_time = 3
			_apply_gun_visuals(50, "res://img/gun01.png")
			#define Bullet texture
		
		TYPE.LAUNCHER:
			base_damage = 10
			fire_rate = 1;
			ammo_capacity = 30
			current_ammo = ammo_capacity
			bullet_speed = 2
			bullet_size = 10
			aoe = true
			gravity_affection = 5
			reload_time = 4
			_apply_gun_visuals(50, "res://img/gun01.png")
			#define Bullet texture