extends Control

@onready var global = get_node("/root/Globals")

@export var setting_name: String
@export var setting_id: String

# Called when the node enters the scene tree for the first time.
func _ready():
	$SettingNameMargins/SettingName.text = setting_name
	$Toggle.button_pressed = global.settings[setting_id]

func _on_toggle_pressed():
	if not(global.settings.mute_audio or global.settings.mute_sfx):
		$ActionPlayer.play()
	
	print("Setting %s to %s" % [setting_id, str(!global.settings[setting_id])])
	global.settings[setting_id] = !global.settings[setting_id]
