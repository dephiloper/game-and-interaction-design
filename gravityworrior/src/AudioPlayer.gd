extends Node

var enemy_hit = preload("res://audio/enemy_hit.ogg")
var destroyer_laser_fade = preload("res://audio/destroyer_laser_fade.ogg")
var destroyer_laser_attack = preload("res://audio/destroyer_laser_attack.ogg")
var enemy_sounds = [
	preload("res://audio/enemy_sound1.ogg"),
	preload("res://audio/enemy_sound2.ogg"),
	preload("res://audio/enemy_sound3.ogg")
]
var player_hit_sounds = [
	preload("res://audio/playerhit1.ogg"),
	preload("res://audio/playerhit2.ogg"),
	preload("res://audio/playerhit3.ogg"),
	preload("res://audio/playerhit4.ogg")
]
var explosion = preload("res://audio/explosion.ogg")
var player_boost = preload("res://audio/player_boost.ogg")
var player_shot = preload("res://audio/player_shot.ogg")

var background = preload("res://audio/enemy_hit.ogg")  # TODO

var audio_players = []
var audio_players_to_stop = []

func _ready():
	var background_music_player = AudioStreamPlayer.new()
	background.set_loop(true)
	background_music_player.stream = background
	background_music_player.volume_db = -12
	add_child(background_music_player)
	# background_music_player.play()

func _physics_process(delta):
	for p in audio_players_to_stop:
		p.volume_db = p.volume_db - 2
		if p.volume_db < -60:
			p.stop()
			audio_players_to_stop.erase(p)

	for p in audio_players:
		if not p.is_playing():
			audio_players.erase(p)
			p.queue_free()
			break

func play_stream(stream, volume=0):
	var player = AudioStreamPlayer.new()
	player.volume_db = volume
	stream.set_loop(false)
	player.stream = stream
	add_child(player)
	player.play()

	audio_players.append(player)

func play_enemy_sound(volume=0):
	var stream = enemy_sounds[randi()%len(enemy_sounds)]
	play_stream(stream, volume)

func play_player_hit_sound(volume=0):
	var stream = player_hit_sounds[randi()%len(player_hit_sounds)]
	play_stream(stream, volume)

func play_loop(stream, volume=0):
	var player = AudioStreamPlayer.new()
	player.volume_db = volume
	stream.set_loop(true)
	player.stream = stream
	add_child(player)
	player.play()

	audio_players.append(player)

	return player

func stop_player(player):
	audio_players_to_stop.append(player)