extends Node2D

class_name Planet

var gravity: float = 9.81
var radius: float = 0

var _planet_points: PoolVector2Array
var _num_points: int = 0
var _offset: float = 0
var _initialized: bool = false

func _init() -> void:
	generate(self.position)

func _ready() -> void:
	_create_collision_shape()

func _draw() -> void:
	if self._initialized:
		_draw_planet(self._planet_points)

func generate(center: Vector2, radius: float = rand_range(32, 64), num_points: int = int(rand_range(12,20)), offset: float = rand_range(2,4)) -> void:
	self.position = center
	self.radius = radius
	self._num_points = num_points
	self._offset = offset
	self._planet_points = _calculate_planet_points()
	self._initialized = true
	update()

#func _process(delta: float) -> void:
#	if Input.is_action_just_pressed("ui_accept"):
#		generate(self.position, self.radius, self._num_points, self._offset)
#		update()

func _calculate_planet_points() -> PoolVector2Array:
	var angle: float = 2 * PI / self._num_points
	var points: PoolVector2Array = []
	for i in self._num_points:
		var r = rand_range(self.radius-self._offset, self.radius+self._offset)
		var x: float = r * cos(i * angle)
		var y: float = r * sin(i * angle)
		points.append(self.position + Vector2(x,y))
	points.append(points[0])
	
	return points
	
func _create_collision_shape():
	$CollisionBody/CollisionPolygon.polygon = self._planet_points
	
	# var shape = ConvexPolygonShape2D.new()
	#shape.resource_name = "ConvexPolygonShape2D"
	#shape.set_point_cloud(self._planet_points)
	#var collision: CollisionShape2D = CollisionShape2D.new()
	#collision.shape = shape
	#print(collision.shape)
	#collision.name = "CollisionShape2D"
	#add_child(collision)
	
func _draw_planet(points: Array) -> void:
	draw_polygon(points, PoolColorArray([Color.burlywood]))
	draw_polyline(points, Color.black, 2)
	
	