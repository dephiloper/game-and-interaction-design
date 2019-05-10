extends KinematicBody2D

var speed = 250
var velocity = Vector2()
var planet: Planet = null
var jumping = false

export (int) var run_speed = 100
export (int) var jump_speed = -400
export (int) var gravity = 1200


func _ready() -> void:
	planet = get_node("/root/Main/Planet")

func get_input():
	velocity.x = 0
	var right = Input.is_action_pressed('ui_right')
	var left = Input.is_action_pressed('ui_left')
	var jump = Input.is_action_just_pressed('ui_select')

	if jump and is_on_floor():
		jumping = true
		velocity.y = jump_speed
	if right:
		velocity.x += run_speed
	if left:
		velocity.x -= run_speed

func _physics_process(delta):
	get_input()
	var vec = planet.position - self.position
	#look_at(planet.position)
	#velocity.y += gravity * delta
	velocity += vec
	if jumping and is_on_floor():
		jumping = false
	velocity = move_and_slide(velocity, Vector2(0, -1))