extends Control

@onready var global = get_node("/root/Globals")


func _on_back_button_pressed():
	print("Back from the settings")
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
