extends Control

@onready var global = get_node("/root/Globals")

func _ready():
	$PlayButton.back_color = Color(global.colors[global.settings.current_colors][0])
	$PlayButton.update_back_color()
	$OptionsButton.back_color = Color(global.colors[global.settings.current_colors][2])
	$OptionsButton.update_back_color()



func _on_play_button_action_taken():
	print("Starting Game")
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_options_button_action_taken():
	pass # idk


func _on_settings_button_pressed():
	print("To the settings")
	get_tree().change_scene_to_file("res://scenes/ui/settings_menu.tscn")
