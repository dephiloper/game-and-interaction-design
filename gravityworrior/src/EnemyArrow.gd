extends Node2D

var _left_border_line
var _right_border_line
var _top_border_line
var _bottom_border_line
var _viewport_rect

func _ready():
	_viewport_rect = get_viewport().get_visible_rect()
	var left = _viewport_rect.position.x
	var top = _viewport_rect.position.y
	var right = _viewport_rect.end.x
	var bottom = _viewport_rect.end.y
	var width = _viewport_rect.size.x
	var height = _viewport_rect.size.y

	_left_border_line = [Vector2(left, top), Vector2(0, height)] # left
	_right_border_line = [Vector2(right, top), Vector2(0, height)] # right
	_top_border_line = [Vector2(left, top), Vector2(width, 0)] # top
	_bottom_border_line = [Vector2(left, bottom), Vector2(width, 0)] # bottom

func play(anim):
	$Sprite.play(anim)

func update_position(enemy_pos, enemy_rotation):
	rotation = enemy_rotation + PI/2
	var center = GameManager.satellite.position
	var center_to_enemy: Vector2 = enemy_pos - center

	var diagonal_normal_top_right = _viewport_rect.size.rotated(PI/2)
	var diagonal_normal_top_left = Vector2(-diagonal_normal_top_right.x, diagonal_normal_top_right.y)

	var border_position = null
	if center_to_enemy.dot(diagonal_normal_top_left) > 0: # bottom right
		if center_to_enemy.dot(diagonal_normal_top_right) > 0: # bottom
			border_position = get_intersection_point(
				_bottom_border_line[0],
				_bottom_border_line[1],
				center,
				center_to_enemy
			)
		else: # right
			border_position = get_intersection_point(
				_right_border_line[0],
				_right_border_line[1],
				center,
				center_to_enemy
			)
	else: # top left
		if center_to_enemy.dot(diagonal_normal_top_right) > 0: # left
			border_position = get_intersection_point(
				_left_border_line[0],
				_left_border_line[1],
				center,
				center_to_enemy
			)
		else: # top
			border_position = get_intersection_point(
				_top_border_line[0],
				_top_border_line[1],
				center,
				center_to_enemy
			)

	position = border_position - center_to_enemy.normalized() * 10

	var a = pow(1.01, -border_position.distance_to(enemy_pos))
	#print(a)
	modulate.a = a

	return enemy_pos.distance_squared_to(center) < border_position.distance_squared_to(center)

func get_intersection_point(p, r, q, s):
	"""
	Returns the intersection point of the two lines p + t*r and q + u*s
	"""
	var sub = r.cross(s)
	if sub == 0.0:
		return null
	var t = (q - p).cross(s) / sub

	return p + t*r