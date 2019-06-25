extends Control

var _player_selections: Array
var _players_confirmed: Array
var _buffs: Array
var _selection_allowed = false

func reset() -> void:
	_setup()
	_fade_in()

#warning-ignore:return_value_discarded
func _ready() -> void:
	_setup()
	_fade_in()
	$StartTween.connect("tween_completed", self, "_on_selection_allowed")
	$FinishTween.connect("tween_completed", self, "_on_selection_done")

func _process(_delta: float) -> void:
	if not _selection_allowed:
		return
	if GameManager.current_game_state == GameManager.GameState.Vote:
		if not _players_confirmed.has(false):
			_fade_out()
			_selection_allowed = false
		
		var i: int = 0
		for player in GameManager.players:
			if not _players_confirmed[i]:
				var controls: Controls = (player as Player).controls
				var horizontal = controls.pressed("ui_right") - controls.pressed("ui_left")
				if horizontal > 0.5:
					if controls.last_axis_direction != Vector2.RIGHT:
						_switch_to_right_buff(i)
					controls.last_axis_direction = Vector2.RIGHT
				elif horizontal < -0.5:
					if controls.last_axis_direction != Vector2.LEFT:
						_switch_to_left_buff(i)
					controls.last_axis_direction = Vector2.LEFT
				else:
					controls.last_axis_direction = Vector2.ZERO
				
				if controls.just_pressed("jump"):
					_players_confirmed[i] = true
					var buff: Buff = _buffs[_player_selections[i]] as Buff
					buff.highlight(i)
					player.apply_buff(buff.type)
			i+=1

func _setup() -> void:
	randomize()
	_player_selections = []
	_players_confirmed = []
	_buffs = []
	_selection_allowed = false
	
	for player in GameManager.players:
		_player_selections.append(1)
		_players_confirmed.append(false)
		
	var available_types = Buff.Types.keys()
	
	# collect all buffs in array
	for child in get_children():
		var buff: Buff = child as Buff
		if buff:
			var rand_index = randi() % len(available_types)
			buff.set_type(available_types[rand_index])
			available_types.remove(rand_index)
			_buffs.append(buff)
	
	# select the second buff as default
	for i in range(len(_player_selections)):
		_select_buff(_player_selections[i], i)

func _switch_to_left_buff(player: int) -> void:
	var index: int = _player_selections[player]
	_player_selections[player] = index - 1 if index > 0 else index
	_select_buff(_player_selections[player], player)
	
func _switch_to_right_buff(player: int) -> void:
	var index: int = _player_selections[player]
	_player_selections[player] = index + 1 if index < len(_buffs) - 1 else index
	_select_buff(_player_selections[player], player)

func _select_buff(index: int, player: int) -> void:
	assert index < len(_buffs)
	
	# deselect player on other buffs
	for child in _buffs:
		(child as Buff).deselect(player)
	
	(_buffs[index] as Buff).select(player)
	
func _on_selection_allowed(_object: Object, _key: NodePath) -> void:
	_selection_allowed = true

func _on_selection_done(_object: Object, _key: NodePath) -> void:
	GameManager.current_game_state = GameManager.GameState.Fight
	for buff in _buffs:
		buff.reset()
	
func _fade_in():
	$StartTween.interpolate_property(self, "rect_scale",
		Vector2(0, 0), Vector2(1, 1), 1,
		Tween.TRANS_LINEAR, Tween.EASE_IN)
		
	$StartTween.start()

func _fade_out():
	$FinishTween.interpolate_property(self, "rect_scale",
		Vector2(1, 1), Vector2(0, 0), 0.5,
		Tween.TRANS_CIRC, Tween.EASE_IN)
	$FinishTween.start()