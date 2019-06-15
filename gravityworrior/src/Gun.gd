extends Sprite

class_name Gun

enum type {
	MACHINE, GATLING, RIFLE, LAUNCHER
}

const BULLET_SCENE = preload("res://src/Bullet.tscn")

var base_damage
var reload_time
var fire_rate
var ammo_capacity
var bullet_speed
var bullet_size
var aoe: bool
var gravity_affection

func reload():
	$ReloadTimer.start()

func shoot(dir: Vector2, _damage_buff, _bullet_size_multiplier, _bullet_speed_multiplier):
	var b: Bullet = BULLET_SCENE.instance()
	b.init(dir, _damage_buff, _bullet_size_multiplier, _bullet_speed_multiplier)
	b.position = global_position
	$"/root/Main".add_child(b)

func _ready():
	$ReloadTimer.wait_time = reload_time
	$FirerateTimer.wait_time = 1/fire_rate

func _init(type):
	match type:
		Gun.type.MACHINE:
			base_damage = 5
			fire_rate = 10
			ammo_capacity = 30
			bullet_speed = 5
			bullet_size = 5
			aoe = false
			gravity_affection = 5
			reload_time = 
			
		
		Gun.type.GATLING:
			base_damage = 2
			fire_rate = 50;
			ammo_capacity = 200
			bullet_speed = 7
			bullet_size = 3
			aoe = false
			gravity_affection = 5
		
		Gun.type.RIFLE:
			base_damage = 30
			fire_rate = 2;
			ammo_capacity = 3
			bullet_speed = 10
			bullet_size = 5
			aoe = false
			gravity_affection = 0
		
		Gun.type.LAUNCHER:
			base_damage = 10
			fire_rate = 1;
			ammo_capacity = 30
			bullet_speed = 2
			bullet_size = 10
			aoe = true
			gravity_affection = 5