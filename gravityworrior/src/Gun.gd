extends Sprite

onready var audio_player : AudioStreamPlayer = $AudioStreamPlayer

class_name Gun

const BULLET_SCENE = preload("res://src/Bullet.tscn")

var _damage = 5
var fire_rate = 10
var ammo_capacity = 30

func reload():
	pass

func shoot(dir: Vector2):
	var b: Bullet = BULLET_SCENE.instance()
	b.init(dir, _damage)
	b.position = global_position
	$"/root/Main".add_child(b)
	
	get_node("../AudioStreamPlayer").play()

func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
