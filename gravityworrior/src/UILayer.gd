extends Node2D

const BUFF_SELECTION_SCENE = preload("res://src/BuffSelection.tscn")

func _ready() -> void:
	$BuffSelection.position = get_viewport().size / 2

func reinstantiate_buff_selection():
	var buff_scene = BUFF_SELECTION_SCENE.instance()
	add_child(buff_scene)
	buff_scene.name = "BuffSelection"
	buff_scene.position = get_viewport().size / 2