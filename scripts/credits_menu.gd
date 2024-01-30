extends Control

func _on_back_button_pressed():
	print("Back from the credits")
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
