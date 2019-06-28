extends Node2D

const BAR_WIDTH: int = 32
const BAR_HEIGHT: int = 6
const BAR_BORDER_SIZE: int = 1
const BAR_OFFSET = Vector2(0, -30)
const DELAYED_HEALTH_SPEED = 0.01
const FADE_TIME = 1.0

var _entity
var _channel_time: float = -1.0
var _is_dead = false
var _max_health
var _delayed_health: float
var _offset: Vector2

func init(entity, offset):
	_entity = entity
	_max_health = _entity._get_max_health()
	_delayed_health = _entity.health
	_offset = offset

func _physics_process(delta):
	if (not _is_dead) and _entity.is_dead():
		_channel_time = FADE_TIME
		_is_dead = true

	if _is_dead:
		_channel_time -= delta
		if _channel_time <= 0:
			queue_free()
	else:
		position = _entity.position + _offset

	var health = 0
	if not _is_dead:
		health = _entity.health

	if _delayed_health > health:
		_delayed_health -= _max_health * DELAYED_HEALTH_SPEED
		update()
	else:
		if _is_dead:
			update()

func _draw() -> void:
	var health = 0
	var alpha = 0.7
	if _is_dead:
		alpha = _channel_time / FADE_TIME
	else:
		health = _entity.health

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