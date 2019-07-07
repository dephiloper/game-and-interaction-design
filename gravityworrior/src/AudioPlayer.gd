extends Node

var enemy_hit = preload("res://audio/enemy_hit.ogg")
var destroyer_laser_fade = preload("res://audio/destroyer_laser_fade.ogg")
var destroyer_laser_attack = preload("res://audio/destroyer_laser_attack.ogg")

var background = preload("res://audio/enemy_hit.ogg")

var audio_players = []

func _ready():
	var background_music_player = AudioStreamPlayer.new()
	background.set_loop(true)
	background_music_player.stream = background
	background_music_player.volume_db = -12
	add_child(background_music_player)
	# background_music_player.play()

func _physics_process(delta):
	for p in audio_players:
		if not p.is_playing():
			audio_players.erase(p)
			p.queue_free()
			break

func play_stream(stream):
	var player = AudioStreamPlayer.new()
	stream.set_loop(false)
	player.stream = stream
	add_child(player)
	player.play()

	audio_players.append(player)