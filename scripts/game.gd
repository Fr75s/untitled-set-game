extends Node2D

@onready var global = get_node("/root/Globals")

@export var card_scene: PackedScene

signal set_found

var game_mode = ""
var game_complexity = 3

var cpu = false

# Card Variables
var all_cards = []
var expended_cards = []

var current_cards = []
var selected_cards = []

# Completion Counts
var sets_completed = 0
var decks_completed = 0

var max_sets = 0
var max_decks = 0

var total_rows = 4
var total_columns = game_complexity

var viewport_height = ProjectSettings.get_setting("display/window/size/viewport_height")
var viewport_width = ProjectSettings.get_setting("display/window/size/viewport_width")

var num_colors = game_complexity
var num_shapes = game_complexity
var num_fills = game_complexity
var num_counts = game_complexity

var num_variants = [num_colors, num_shapes, num_fills, num_counts]



# Starting Functions
func _ready():
	game_mode = global.game_mode
	
	match game_mode:
		"single":
			$UILayer/PregameScreen/PregameTitle.text = "Singleplayer"
			$UILayer/PregameScreen/SettingsContainer/SingleSettings.visible = true
		"speed":
			$UILayer/PregameScreen/PregameTitle.text = "Speedrun"
			$UILayer/PregameScreen/SettingsContainer/SpeedrunSettings.visible = true
	
	$UILayer/PregameScreen.visible = true

var initial_time = 0

func _on_start_button_pressed():
	# Play Sound
	if not(global.settings.mute_audio or global.settings.mute_sfx):
		$UILayer/UINodeAudio.play()
	
	$UILayer/PregameScreen.visible = false
	
	start_game()

func start_game():
	# Game Features
	#game_complexity = global.settings["game_complexity"]
	
	#num_colors = game_complexity
	#num_shapes = game_complexity
	#num_fills = game_complexity
	#num_counts = game_complexity
	
	#total_columns = game_complexity
	
	#num_variants = [num_colors, num_shapes, num_fills, num_counts]
	
	# Mode Specific Features
	match game_mode:
		"single":
			pass
		"speed":
			$UILayer/IngameUI/Speedrun.visible = true
			$UILayer/IngameUI/Speedrun/GameTimer.label_settings.font_color = Color("#f2f6ff")
			$UILayer/EndScreen/FinishLabel.text = "Speedrun Complete!"
			
			initial_time = Time.get_ticks_msec()
			
			match global.settings.speedrun_mode:
				"1 Deck":
					max_decks = 1
				"2 Decks":
					max_decks = 2
				"5 Decks":
					max_decks = 5
				"5 Sets":
					max_sets = 5
				"10 Sets":
					max_sets = 10
				"15 Sets":
					max_sets = 15
				"50 Sets":
					max_sets = 50
	
	# Hide Pregame UI, Show Ingame UI
	$UILayer/IngameUI.visible = true
	
	# Start Game
	form_randomization()
	prepare_game()





func form_randomization():
	for c in range(num_colors):
		for s in range(num_shapes):
			for f in range(num_fills):
				for k in range(num_counts):
					all_cards.append("%d%d%d%d" % [c, s, f, k])

func all_cards_integrity_check():
	for c in range(num_colors):
		for s in range(num_shapes):
			for f in range(num_fills):
				for k in range(num_counts):
					var combo = "%d%d%d%d" % [c, s, f, k]
					if (all_cards.find(combo) < 0):
						push_error("Integrity Check failed with %s" % combo)
						return
	print("All good")
	return

func prepare_game(slide_in: bool = false):
	for row in range(total_rows):
		for col in range(total_columns):
			var this_card = card_scene.instantiate()
			prepare_new_card(this_card, row, col, total_rows, not(slide_in))
			
	
	if !is_current_cards_viable():
		all_cards = []
		current_cards = []
		expended_cards = []
		selected_cards = []
		
		for child in $CardContainer.get_children():
			child.free()
		
		print("Let's try that again.")
		form_randomization()
		prepare_game()
	else:
		print("There's a set in there, don't worry.")



func generate_new_card_props() -> String:
	if (len(all_cards) == 0):
		print("No cards left, returning blank.")
		return "-"
	
	var index = randi() % len(all_cards)
	var card_props = all_cards.pop_at(index)
	expended_cards.append(card_props)
	
	current_cards.append(card_props)
	
	return card_props

func prepare_new_card(card, row: int, col: int, num_rows: int = total_rows, no_move: bool = false):
	# Number of spaces is (value) + 1
	#var this_card_x = (viewport_width / (total_columns + 1)) * (col + 1)
	#var this_card_y = (viewport_height / (total_rows + 1)) * (row + 1)
	
	# Randomize Card Properties by taking value from list of all cards
	var card_props = generate_new_card_props()
	
	if (card_props != "-"):
		card.name = card_props
		
		card.color = int(card_props[0])
		card.shape = int(card_props[1])
		card.fill = int(card_props[2])
		card.count = int(card_props[3])
		
		if no_move:
			card.position_card(num_rows, total_columns, row, col, true)
		else:
			card.position = Vector2(viewport_width, viewport_height)
			card.scale = Vector2(0.15, 0.15)
			card.position_card_when_ready(num_rows, total_columns, row, col)
		
		card.clicked.connect(card.toggle_selected)
		card.clicked.connect(on_card_clicked)
		
		#print("Adding Card %s" % card.name)
		$CardContainer.add_child(card)
		
		#var out = ""
		#for child in $CardContainer.get_children():
		#	out += child.name + ";"
		#print(out)
	else:
		card.queue_free()

func on_card_clicked(combo: String):
	if (combo in selected_cards):
		selected_cards.remove_at(selected_cards.find(combo))
	else:
		selected_cards.append(combo)
		print(selected_cards)
	
	# Check if selected cards is game complexity
	if len(selected_cards) == game_complexity:
		process_set_viability()



func process_set_viability():
	if is_collection_set(selected_cards):
		var previous_cards = current_cards.slice(0)
		
		if not(global.settings.mute_audio or global.settings.mute_sfx):
			$Audio/CorrectAudio.play()
		
		# Speedrun Progress Processing
		sets_completed += 1
		
		var speedrun_progress_value = 0
		match global.settings.speedrun_mode:
			"1 Deck", "2 Decks", "5 Decks":
				var current_deck_progress = (len(expended_cards) * 1.0 / (num_colors * num_shapes * num_fills * num_counts))
				speedrun_progress_value = (((current_deck_progress + decks_completed) / max_decks)) * 100
			"5 Sets", "10 Sets", "15 Sets", "50 Sets":
				speedrun_progress_value = (sets_completed * 1.0 / max_sets) * 100
		$UILayer/IngameUI/Speedrun/SpeedrunProgress.value = speedrun_progress_value
		
		# Get rid of the selected set, add a new set in place
		var first_index = -1
		for combo in selected_cards:
			$CardContainer.remove_child($CardContainer.get_node(combo))
			
			var index = current_cards.find(combo)
			if (first_index == -1):
				first_index = index
			
			var prev_index = previous_cards.find(combo)
			
			#var row = prev_index / total_columns
			#var col = prev_index % total_columns
			
			var row = total_rows - 1
			var col = total_columns - 1
			
			current_cards.remove_at(index)
			for i in range(index, len(current_cards)):
				var this_row = i / total_columns
				var this_col = i % total_columns
				
				# print("Repositioning card at i%d (%s) to %d, %d" % [i, current_cards[i], this_row, this_col])
				$CardContainer.get_node(current_cards[i]).position_card(total_rows, total_columns, this_row, this_col)
			
			# print(current_cards)
			# print("%02d %02d; %d, %d" % [prev_index, index, row, col])
			
			# Do not draw new cards when there are more than the default amount
			if (len(current_cards) < total_rows * total_columns):
				var this_card = card_scene.instantiate()
				prepare_new_card(this_card, row, col)
		
		selected_cards = []
		print("that's a set")
		
		print("For the next one: ", current_cards)
		
		var overflow = 0
		var game_over = false
		# Reposition cards if no sets can be found in the currently drawn cards
		while !is_current_cards_viable():
			overflow += 1
			print("Overflow going %d time(s)" % (overflow))
			print("There are now %d rows" % (total_rows + overflow))
			
			for i in range(len(current_cards)):
				var this_row = i / total_columns
				var this_col = i % total_columns
				
				$CardContainer.get_node(current_cards[i]).position_card(total_rows + overflow, total_columns, this_row, this_col)
			
			for i in range(total_columns):
				print("Overflow card at %d, %d" % [total_rows + overflow - 1, i])
				
				# With the way this works right now, the overflow cards currently pop in 
				# as they originate where they need to be
				# They instantly have the right position & scale
				var this_card = card_scene.instantiate()
				prepare_new_card(this_card, total_rows + overflow - 1, i, total_rows + overflow)
			
			if !is_current_cards_viable() && len(all_cards) == 0:
				print("Game over, no sets left to be found.")
				game_over = true
				break
		
		# Speedrun Game Over Checks
		if (game_mode == "speed"):
			if (max_sets > 0 and sets_completed >= max_sets):
				game_over = true
		
		# Reposition cards that may not be in the exact right place if overflow did occur
		for i in range(first_index):
			var this_row = i / total_columns
			var this_col = i % total_columns
			$CardContainer.get_node(current_cards[i]).position_card(total_rows + overflow, total_columns, this_row, this_col)
		
		# Alternatively, Reposition cards when there's less than rows * columns
		if (len(current_cards) < total_rows * total_columns):
			if !game_over:
				var num_rows = len(current_cards) / total_columns
				for i in range(len(current_cards)):
					var this_row = i / total_columns
					var this_col = i % total_columns
					$CardContainer.get_node(current_cards[i]).position_card(num_rows, total_columns, this_row, this_col)
		
		# Run game over section when no cards are left and no sets can be made.
		if game_over:
			for i in range(len(current_cards)):
				$CardContainer.get_node(current_cards[i]).position_card(total_rows, total_columns, 0, 0, false, true)
			
			decks_completed += 1
			
			# Timer Stop
			var speedrun_complete = false
			if (game_mode == "speed"):
				if (max_decks > 0 and decks_completed >= max_decks):
					speedrun_complete = true
					$UILayer/IngameUI/Speedrun/GameTimer.label_settings.font_color = Color("#74aaff")
					initial_time = 0
				if (max_sets > 0 and sets_completed >= max_sets):
					speedrun_complete = true
					$UILayer/IngameUI/Speedrun/GameTimer.label_settings.font_color = Color("#74aaff")
					initial_time = 0
			
			await get_tree().create_timer(0.75).timeout
			
			all_cards = []
			expended_cards = []
			current_cards = []
			selected_cards = []
			
			for child in $CardContainer.get_children():
				child.free()
			
			if (game_mode == "single") or (game_mode == "speed" and speedrun_complete):
				if not(global.settings.mute_audio or global.settings.mute_sfx):
					$Audio/WinAudio.play()
				
				$UILayer/IngameUI/Speedrun/SpeedrunProgress.visible = false
				$UILayer/EndScreen.visible = true
			else:
				# Prepare another deck
				form_randomization()
				prepare_game(true)
		else:
			print("Next set!")
		
		# AUTOPLAY
		if global.DEBUG_AUTOPLAY and not(game_over):
			var viable_combos = is_current_cards_viable()
			if is_current_cards_viable():
				print("CARDS LEFT: %d" % len(all_cards))
				await get_tree().create_timer(0.5).timeout
				on_card_clicked(viable_combos[0])
				on_card_clicked(viable_combos[1])
				on_card_clicked(viable_combos[2])

	else:
		if not(global.settings.mute_audio or global.settings.mute_sfx):
			$Audio/IncorrectAudio.play()
		
		for combo in selected_cards:
			$CardContainer.get_node(combo).modulate = Color(1.0, 1.0, 1.0)
			$CardContainer.get_node(combo).selected = false
		
		selected_cards = []
		print("not a set")

func is_current_cards_viable():
	# We just need to find 1 set
	for i in range(len(current_cards)):
		for j in range(i + 1, len(current_cards)):
			var combo1 = current_cards[i]
			var combo2 = current_cards[j]
			
			# Form the ideal third combo
			var combo3 = ""
			for p in range(4):
				var properties_sum = int(combo1[p]) + int(combo2[p])
				if (properties_sum % num_variants[p]) == 0:
					combo3 += "0"
				else:
					combo3 += str(num_variants[p] - (properties_sum % num_variants[p]))
			
			# Check if any of the next cards matches as the ideal third combo
			for k in range(j + 1, len(current_cards)):
				if current_cards[k] == combo3:
					# A set is found! Immediately leave.
					print("the set that's found is [%s %s %s]" % [combo1, combo2, combo3])
					print("items are at indices [%d, %d, %d]" % [i, j, k])
					if global.DEBUG_AUTOPLAY:
						return [combo1, combo2, combo3]
					else:
						return true
	
	# No set found, that's not good.
	return false

func is_collection_set(collection) -> bool:
	for p in range(4):
		var properties_sum = 0
		for n in range(len(collection)):
			properties_sum += int(collection[n][p])
		
		if properties_sum % num_variants[p] != 0:
			return false
	
	return true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	# Process Game size changes
	var new_y = (get_viewport_rect().size.y - viewport_height) / 2
	$CardContainer.position.y = new_y
	
	# Timer
	if (game_mode == "speed") and (initial_time > 0):
		var current_time = Time.get_ticks_msec() - initial_time
		var formatted_time = global.format_time(current_time)
		$UILayer/IngameUI/Speedrun/GameTimer.text = formatted_time[0] + ":" + formatted_time[1] + "." + formatted_time[2]



func _on_restart_button_pressed():
	if not(global.settings.mute_audio or global.settings.mute_sfx):
		$UILayer/UINodeAudio.play()
	
	$UILayer/EndScreen.visible = false
	start_game()

func _on_main_menu_button_pressed():
	print("Returning to the Main Menu")
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _on_back_button_pressed():
	print("Returning to the Main Menu")
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
