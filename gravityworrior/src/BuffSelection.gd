extends Control

var _player_selections: Array = []
var _players_confirmed: Array = []
var _buffs: Array = []
var _selection_allowed = false

#warning-ignore:return_value_discarded
func _ready() -> void:
	randomize()
	
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
		_select_buff( _player_selections[i], i)
		
	$StartTween.connect("tween_completed", self, "_on_selection_allowed")
	$FinishTween.connect("tween_completed", self, "_on_selection_done")
	
	$StartTween.interpolate_property(self, "rect_scale",
		Vector2(0, 0), Vector2(1, 1), 1,
		Tween.TRANS_LINEAR, Tween.EASE_IN)
	
	$FinishTween.interpolate_property(self, "rect_scale",
		Vector2(1, 1), Vector2(0, 0), 0.5,
		Tween.TRANS_LINEAR, Tween.EASE_OUT)
		
	$StartTween.start()

func _process(_delta: float) -> void:
	if GameManager.current_game_state == GameManager.GameState.Vote:
		if not _players_confirmed.has(false):
			$FinishTween.start()
		
		if not _selection_allowed:
			return
		
		var i: int = 0
		for player in GameManager.players:
			if not _players_confirmed[i]:
				var controls: Controls = (player as Player).controls
				if controls.just_pressed("ui_left"):
					_switch_to_left_buff(i)
				if controls.just_pressed("ui_right"):
					_switch_to_right_buff(i)
				if controls.just_pressed("jump"):
					_players_confirmed[i] = true
					var buff: Buff = _buffs[_player_selections[i]] as Buff
					buff.highlight(i)
					player.apply_buff(buff.type)
			i+=1

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
	queue_free()