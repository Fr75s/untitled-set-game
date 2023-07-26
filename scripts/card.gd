extends Sprite2D

# Red: 0.9686274509803922, 0.34901960784313724, 0.4823529411764706
# Green: 0.4549019607843137, 1.0, 0.4549019607843137
# Purple: 0.6666666666666666, 0.4549019607843137, 1.0

@onready var global = get_node("/root/Globals")

@export var color: int = 0
@export var shape: int = 0
@export var fill: int = 0
@export var count: int = 0

@export var selected: bool = false

signal clicked

# File name scheme: shape|fill|count

@onready var display_colors = global.colors[global.settings["current_colors"]]

# Called when the node enters the scene tree for the first time.
func _ready():
	#display_colors = global.colors[global.settings["colors"]]
	prepare_card()

func prepare_card():
	var card = Image.load_from_file("res://assets/cards/%d%d%d.svg" % [shape, fill, count])
	$Shape.texture = ImageTexture.create_from_image(card)
	
	$Shape.modulate = Color(display_colors[color])
	$Border.modulate = Color(display_colors[color])

func toggle_selected(_combo):
	if (selected):
		modulate = Color(1.0, 1.0, 1.0)
		selected = false
	else:
		modulate = Color(0.6, 0.8, 1.0)
		selected = true



func position_card(num_rows: int, num_cols: int, row: int, col: int, instant: bool = false, finished: bool = false):
	var viewport_height = ProjectSettings.get_setting("display/window/size/viewport_height")
	var viewport_width = ProjectSettings.get_setting("display/window/size/viewport_width")
	
	# Number of spaces is {screen width} / ({number of rows/columns} + 1)
	# Card is offset {row/column index} + 1 spaces
	
	var this_card_x = (viewport_width / (num_cols + 1)) * (col + 1)
	var this_card_y = (viewport_height / (num_rows + 1)) * (row + 1)
	
	# 4 Rows - 0.15
	# 5 Rows - Smaller
	
	var this_card_scale = 0.15 * (4.0 / num_rows)
	if this_card_scale > 0.15 * (4.0 / 3.0):
		this_card_scale = 0.15 * (4.0 / 3.0)
	
	if !finished:
		if instant:
			position = Vector2(this_card_x, this_card_y)
			scale = Vector2(this_card_scale, this_card_scale)
		else:
			var tween = create_tween()
			tween.set_trans(Tween.TRANS_QUAD)
			tween.tween_property(self, "position", Vector2(this_card_x, this_card_y), 0.5)
			tween.parallel().tween_property(self, "scale", Vector2(this_card_scale, this_card_scale), 0.5)
	else:
		# Disappear the cards when done, don't move them also
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_QUAD)
		tween.tween_property(self, "scale", Vector2(0, 0), 0.5)



func _on_click_area_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# Actions upon clicking
			if not(global.settings.mute_audio or global.settings.mute_sfx):
				$ClickAudioPlayer.play()
			
			clicked.emit("%d%d%d%d" % [color, shape, fill, count])
			#print("%d%d%d%d" % [color, shape, fill, count])
