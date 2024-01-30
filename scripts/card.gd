extends Sprite2D

# Red: 0.9686274509803922, 0.34901960784313724, 0.4823529411764706
# Green: 0.4549019607843137, 1.0, 0.4549019607843137
# Purple: 0.6666666666666666, 0.4549019607843137, 1.0

@onready var global = get_node("/root/Globals")

# Card properties
@export var color: int = 0
@export var shape: int = 0
@export var fill: int = 0
@export var count: int = 0

# The player that is currently selecting the card:
# - 0 if no players are selecting this card
# - 1 if player 1 is selecting this card
# - 2 if player 2 is selecting this card
# - 3 if both players are selecting this card
@export var selected: int = 0

signal clicked

# File name scheme: shape|fill|count

# The current colorscheme
@onready var display_colors = global.colors[global.settings["current_colors"]]

# Store cards that need to be positioned
var position_card_queue = []

func _ready():
	#display_colors = global.colors[global.settings["colors"]]
	# Position all queued cards
	for i in position_card_queue:
		position_card(i[0], i[1], i[2], i[3], i[4], i[5])
	# Prepare this card
	prepare_card()

# Set the color and texture of a card.
func prepare_card():
	$Shape.texture = load("res://assets/cards/%d%d%d.svg" % [shape, fill, count])
	
	$Shape.modulate = Color(display_colors[color])
	$Border.modulate = Color(display_colors[color])

# Highlight/Unhighlight this card when selected
func toggle_selected(_combo, player):
	# BLUE: 0.7, 0.9, 1.0
	# RED: 1.0, 0.7, 0.7
	# PURPLE: 0.8, 0.7, 1.0
	selected = selected ^ (2 ** (player - 1))
	match selected:
		0: # Unselected
			modulate = Color(1.0, 1.0, 1.0)
		1: # Player 1 selected
			modulate = Color(0.7, 0.9, 1.0)
		2: # Player 2 selected
			modulate = Color(1.0, 0.7, 0.7)
		3: # Player 1 & 2 selected
			modulate = Color(0.8, 0.7, 1.0)


# Position this card in the correct position on screen.
# Uses row/col as reference for positioning.
# - `instant` will instantly move the card to the position if true.
# - `finished` makes the cards vanish instead of positioning them.
func position_card(num_rows: int, num_cols: int, row: int, col: int, instant: bool = false, finished: bool = false):
	# Get the current screen size
	var viewport_height = ProjectSettings.get_setting("display/window/size/viewport_height")
	var viewport_width = ProjectSettings.get_setting("display/window/size/viewport_width")
	
	# Number of spaces is {screen width} / ({number of rows/columns} + 1)
	# Card is offset {row/column index} + 1 spaces
	
	# Calculate the x and y position from given information
	var this_card_x = (viewport_width / (num_cols + 1)) * (col + 1)
	var this_card_y = (viewport_height / (num_rows + 1)) * (row + 1)
	
	# 4 Rows - 0.15
	# 5 Rows - Smaller
	
	# Scale this card based on how many rows there are
	var this_card_scale = 0.15 * (4.0 / num_rows)
	if this_card_scale > 0.15 * (4.0 / 3.0):
		this_card_scale = 0.15 * (4.0 / 3.0)
	
	# Check if cards must disappear
	if !finished:
		if instant:
			# Set the position and scale of this card.
			position = Vector2(this_card_x, this_card_y)
			scale = Vector2(this_card_scale, this_card_scale)
		else:
			# Tween the position and scale of this card
			var tween = create_tween()
			tween.set_trans(Tween.TRANS_QUAD)
			tween.tween_property(self, "position", Vector2(this_card_x, this_card_y), 0.5)
			tween.parallel().tween_property(self, "scale", Vector2(this_card_scale, this_card_scale), 0.5)
	else:
		# Disappear the cards when done, don't move them also
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_QUAD)
		tween.tween_property(self, "scale", Vector2(0, 0), 0.5)

func position_card_when_ready(num_rows: int, num_cols: int, row: int, col: int, instant: bool = false, finished: bool = false):
	position_card_queue.append([num_rows, num_cols, row, col, instant, finished])


# Handle any click in the click area, and filter for left clicks/normal taps.
func _on_click_area_input_event(_viewport, event, _shape_idx):
	# Filter left clicks
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# Click audio
			if not(global.settings.mute_audio or global.settings.mute_sfx):
				$ClickAudioPlayer.play()
			
			# Send click signal with combo and P1
			clicked.emit("%d%d%d%d" % [color, shape, fill, count], 1)
