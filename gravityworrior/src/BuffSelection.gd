extends Node2D

var _player_selections: Array = []
var _players_confirmed: Array = []
var _buffs: Array = []

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
		
	$Tween.connect("tween_completed", self, "_on_selection_done")

	$Tween.interpolate_property(self, "scale",
                Vector2(1, 1), Vector2(0, 0), 0.5,
                Tween.TRANS_LINEAR, Tween.EASE_OUT)

func _process(_delta: float) -> void:
	if GameManager.current_game_state == GameManager.GameState.Vote:
		if not _players_confirmed.has(false):
			$Tween.start()
			
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
	
func _on_selection_done(_object: Object, _key: NodePath) -> void:
	GameManager.current_game_state = GameManager.GameState.Fight
	queue_free()