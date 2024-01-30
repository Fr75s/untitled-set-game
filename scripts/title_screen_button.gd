extends Button

@onready var global = get_node("/root/Globals")

@export var label: String = ""
@export var back_color: Color = Color("#f2f6ff")

signal action_taken

var focused: bool = false

func _ready():
	$Front/ButtonLabel.text = label
	update_back_color()

# Updates the StyleBox override on the back panel.
func update_back_color():
	var back_stylebox: StyleBoxFlat = $Back.get_theme_stylebox("panel").duplicate()
	back_stylebox.set("bg_color", back_color)
	$Back.add_theme_stylebox_override("panel", back_stylebox)

func _on_button_image_item_rect_changed():
	# Set pivot
	var height = $Front.size.y
	var radius = height * (30.0 / 400.0)
	$Front.pivot_offset = Vector2(radius, height - radius)



var focus_response: bool = false

const tween_duration: float = 0.25

func toggle_focus(to: bool):
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	if !to:
		tween.tween_property($Front, "rotation_degrees", 0, tween_duration)
		focused = false
	else:
		tween.tween_property($Front, "rotation_degrees", -1.5, tween_duration)
		focused = true
		
		# Delay triggering action
		focus_response = true
		get_tree().create_timer(0.05).timeout.connect(func(): focus_response = false)

func _on_focus_entered():
	toggle_focus(true)

func _on_focus_exited():
	toggle_focus(false)



func _on_pressed():
	if not(global.settings.mute_audio or global.settings.mute_sfx):
		$ClickAudioPlayer.play()
	if focused && (!focus_response):
		action_taken.emit()
