extends Control

@onready var global = get_node("/root/Globals")

@export var setting_name: String
@export var setting_id: String
@export var setting_list_id: String

var setting_list
var setting_list_index

# Called when the node enters the scene tree for the first time.
func _ready():
	setting_list = global.setting_options[setting_list_id]
	setting_list_index = setting_list.find(global.settings[setting_id])
	
	$SettingName.text = setting_name
	update_display()



func update_display():
	$ListContainer/ListDisplay.text = str(global.settings[setting_id])

func _on_list_left_button_pressed():
	if not(global.settings.mute_audio or global.settings.mute_sfx):
		$ActionPlayer.play()
	
	setting_list_index -= 1
	if (setting_list_index < 0):
		setting_list_index = len(setting_list) - 1
	
	global.settings[setting_id] = setting_list[setting_list_index]
	update_display()

func _on_list_right_button_pressed():
	if not(global.settings.mute_audio or global.settings.mute_sfx):
		$ActionPlayer.play()
	
	setting_list_index += 1
	if (setting_list_index >= len(setting_list)):
		setting_list_index = 0
	
	global.settings[setting_id] = setting_list[setting_list_index]
	update_display()
