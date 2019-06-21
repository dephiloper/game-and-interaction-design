extends Node2D

class_name Planet

const GRAVITY_EXPONENT: float = 2.95

var gravity: float = 0.0
var radius: float = 0.0


var _planet_points: PoolVector2Array
var _num_points: int = 0.0
var _offset: float = 0.0
var _rotation: float = 0.0
var _initialized: bool = false

func _init() -> void:
	randomize()
	add_to_group("Planet")
	generate(self.position)
	GameManager.add_planet(self)

func _ready() -> void:
	_create_collision_shape()

func _draw() -> void:
	if self._initialized:
		_draw_planet(self._planet_points)

func generate(center: Vector2, r: float = rand_range(32, 64), 
	num_points: int = int(rand_range(12,20)), 
	offset: float = rand_range(2,4)) -> void:
	self.position = center
	self.radius = r
	self._num_points = num_points
	self._offset = offset
	self._planet_points = _calculate_planet_points()
	self._rotation = rand_range(-1,1)

	self._initialized = true
	update()
	
func _calculate_planet_points() -> PoolVector2Array:
	var angle: float = 2 * PI / self._num_points
	var points: PoolVector2Array = []
	for i in self._num_points:
		var r = rand_range(self.radius-self._offset, self.radius+self._offset)
		self.gravity += r
		var x: float = r * cos(i * angle)
		var y: float = r * sin(i * angle)
		points.append(self.position + Vector2(x,y))
	points.append(points[0])
	
	self.gravity /= self._num_points
	self.gravity = pow(self.gravity, GRAVITY_EXPONENT)
	return points
	
func _create_collision_shape():
	$CollisionPolygon.polygon = self._planet_points
	
func _draw_planet(points: Array) -> void:
	draw_polygon(points, PoolColorArray([Color.burlywood]))
	draw_polyline(points, Color.black, 2, true)
	

