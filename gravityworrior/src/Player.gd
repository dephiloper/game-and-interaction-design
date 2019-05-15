extends KinematicBody2D

signal hit

var closest_planet: Planet = null
var previous_planet: Planet = null
var speed: Vector2 = Vector2()
var velocity: Vector2 = Vector2()
const MAX_SPEED = 10000
const JUMP_FORCE = 6000

class_name Player



func _ready() -> void:
	closest_planet = get_node("/root/Main/Planet")

func _physics_process(delta: float) -> void:
	speed.x = 0
	if Input.is_action_pressed("ui_left"):
		speed.x = -MAX_SPEED
	elif Input.is_action_pressed("ui_right"):
		speed.x = +MAX_SPEED
	
	if Input.is_action_pressed("ui_up") and is_on_wall():
		speed.y = -JUMP_FORCE
	
	if not is_on_wall():
		speed.y += closest_planet.gravity
	
	var player_rotation = _get_player_rotation()
	
	velocity = Vector2(speed.x, speed.y) * delta
	velocity = velocity.rotated(player_rotation)
	
	velocity = move_and_slide(velocity)
	set_rotation(player_rotation)
	
func _get_player_rotation():
	var down_vector = Vector2.DOWN
	if closest_planet:
		return down_vector.angle_to(_get_gravity_vector(closest_planet))
	else:
		return get_rotation()
	
func _get_gravity_vector(planet: Planet):
	return (planet.position - self.position).normalized()

	
func start(pos):
    position = pos
    show()
    $CollisionShape2D.disabled = false

	
