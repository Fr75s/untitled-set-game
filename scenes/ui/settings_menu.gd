extends Control

@onready var global = get_node("/root/Globals")


func _ready():
	generate_color_display()


func _on_back_button_pressed():
	print("Back from the settings")
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")


func generate_color_display():
	var i: int = 0
	for color in global.colors[global.settings["current_colors"]]:
		var display: Panel = $ColorDisplay.get_node("Color%d" % i)
		var stylebox: StyleBoxFlat = display.get_theme_stylebox("panel").duplicate()
		stylebox.set("bg_color", color)
		display.add_theme_stylebox_override("panel", stylebox)
		i += 1


func _on_colorscheme_setting_changed(_id, _value):
	generate_color_display()
