extends Node2D

const BUFF_SELECTION_SCENE = preload("res://src/BuffSelection.tscn")
const BUFF_SECECTION_OFFSET = Vector2(-35, -32) # idk, magic number

func reinstantiate_buff_selection():
	var buff_scene = BUFF_SELECTION_SCENE.instance()
	add_child(buff_scene)
	buff_scene.name = "BuffSelection"
	
	var mid = get_viewport().size / 2 + BUFF_SECECTION_OFFSET
	buff_scene.margin_left = mid.x - (buff_scene.get_node("ColorRect").rect_size.x/2)
	buff_scene.margin_top = mid.y - (buff_scene.get_node("ColorRect").rect_size.y/2)