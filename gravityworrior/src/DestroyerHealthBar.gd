extends Node2D

const BAR_WIDTH: int = 32
const BAR_HEIGHT: int = 6
const BAR_BORDER_SIZE: int = 1
const BAR_OFFSET = Vector2(0, -30)
const DELAYED_HEALTH_SPEED = 0.04

var _destroyer
var _channel_time: float = -1.0
var _is_dead = false
var _die_time = 0
var _max_health
var _delayed_health: float
var _offset: Vector2

func init(destroyer, offset):
	_destroyer = destroyer
	_die_time = _destroyer.DIE_TIME
	_max_health = _destroyer._get_max_health()
	_delayed_health = _destroyer.health
	_offset = offset

func _physics_process(delta):
	if (not _is_dead) and _destroyer.is_dead():
		_channel_time = _destroyer.DIE_TIME
		_is_dead = true

	if _is_dead:
		_channel_time -= delta
		if _channel_time <= 0:
			queue_free()
	else:
		position = _destroyer.position + _offset
		if _delayed_health > _destroyer.health:
			_delayed_health -= _max_health * DELAYED_HEALTH_SPEED
			update()

func _draw() -> void:
	var health = 0
	var alpha = 1
	if _is_dead:
		alpha = _channel_time / _die_time
	else:
		health = _destroyer.health

	var background_color = Color.black
	background_color.a = alpha
	var foreground_color = Color.red
	foreground_color.a = alpha

	draw_rect(Rect2(BAR_OFFSET.x, BAR_OFFSET.y, BAR_WIDTH, BAR_HEIGHT), background_color)
	var width: float = ((BAR_WIDTH - 2*BAR_BORDER_SIZE) * health) / _max_health
	draw_rect(
		Rect2(
			BAR_BORDER_SIZE + BAR_OFFSET.x,
			BAR_BORDER_SIZE + BAR_OFFSET.y,
			width,
			BAR_HEIGHT - 2*BAR_BORDER_SIZE),
		foreground_color
	)

	if _delayed_health > health:
		var delayed_color = Color.white
		delayed_color.a = alpha
		var delayed_width: float = ((BAR_WIDTH - 2*BAR_BORDER_SIZE) * _delayed_health) / _max_health
		delayed_width -= width
		draw_rect(
			Rect2(
				width,
				BAR_BORDER_SIZE + BAR_OFFSET.y,
				delayed_width,
				BAR_HEIGHT - 2*BAR_BORDER_SIZE),
			delayed_color
		)