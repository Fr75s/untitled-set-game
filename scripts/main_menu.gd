extends Control

@onready var global = get_node("/root/Globals")

func _ready():
	$SingleButton.back_color = Color(global.colors[global.settings.current_colors][0])
	$SingleButton.update_back_color()
	$SpeedButton.back_color = Color(global.colors[global.settings.current_colors][1])
	$SpeedButton.update_back_color()
	$MultiButton.back_color = Color(global.colors[global.settings.current_colors][2])
	$MultiButton.update_back_color()



func _on_settings_button_pressed():
	print("To the settings")
	get_tree().change_scene_to_file("res://scenes/ui/settings_menu.tscn")



func _on_single_button_action_taken():
	print("Starting Game (standard)")
	global.game_mode = "single"
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_speed_button_action_taken():
	print("Starting Game (speedrun)")
	global.game_mode = "speed"
	get_tree().change_scene_to_file("res://scenes/game.tscn")
