extends Node2D

@onready var global = get_node("/root/Globals")
@onready var cpu_weights = get_node("/root/CpuWeights")

@export var card_scene: PackedScene

signal set_found

# Set the game mode. Can be "single" or "speed"
var game_mode = ""
# Sets the number of permutations for cards.
# CURRENTLY UNIMPLEMENTED! DO NOT CHANGE!
var game_complexity: int = 3


# Card Variables
# Store every card permutation
var all_cards = []
# Store cards that have been made into sets
var expended_cards = []

# Store the current cards shown on screen
var current_cards = []
# Store the cards selected by the player
var selected_cards = []


# Store the CPU Action:
# 0: Idle
# 1: Selecting random cards
# 2: Forming a set
var cpu_action: int = 0
# Store the cards selected by the CPU
var cpu_selected_cards = []
# Store the current set visible in the cards on screen as an array of Combos
var cpu_current_set_combos = []


# Completion Counts
var sets_completed = 0
var decks_completed = 0

var cpu_sets_completed = 0

# Speedrun completion requirements
var max_sets = 0
var max_decks = 0


# The number of rows on screen, without any overflow
var total_rows: int = 4
# The number of columns on screen
var total_columns: int = game_complexity
# The number of extra rows needed to show a set on screen
var overflow = 0

# Width and Height of the current window size
var viewport_height = ProjectSettings.get_setting("display/window/size/viewport_height")
var viewport_width = ProjectSettings.get_setting("display/window/size/viewport_width")

# Card variant variables.
var num_colors = game_complexity
var num_shapes = game_complexity
var num_fills = game_complexity
var num_counts = game_complexity
var num_variants = [num_colors, num_shapes, num_fills, num_counts]

var initial_time = 0

# Prepare the scene.
func _ready():
	game_mode = global.game_mode
	
	# Prepare pre-game screen by showing correct mode's options
	match game_mode:
		"single":
			$UILayer/PregameScreen/PregameTitle.text = "Singleplayer"
			$UILayer/PregameScreen/SettingsContainer/SingleSettings.visible = true
		"speed":
			$UILayer/PregameScreen/PregameTitle.text = "Speedrun"
			$UILayer/PregameScreen/SettingsContainer/SpeedrunSettings.visible = true
			update_record_time("speedrun_mode", global.settings["speedrun_mode"])
	
	# Show pre-game screen
	$UILayer/PregameScreen.visible = true

# Action when pushing "begin game."
func _on_start_button_pressed():
	# Play Sound
	if not(global.settings.mute_audio or global.settings.mute_sfx):
		$UILayer/UINodeAudio.play()
	
	$UILayer/PregameScreen.visible = false
	start_game()

# Start the game.
# Called upon clicking "begin game."
func start_game():
	sets_completed = 0
	decks_completed = 0
	
	# Mode Specific Features
	match game_mode:
		"single":
			# Init the CPU if enabled
			if global.settings.cpu_difficulty != "None":
				print("Playing With CPU")
				
				# Reset Scoreboard
				cpu_sets_completed = 0
				cpu_action = 0
				update_scoreboard()
				
				# Show Head to Head UI
				$UILayer/IngameUI/HeadToHead.visible = true
				$UILayer/IngameUI/Stats/StatsLabel.text = ""
				
				# Start CPU Activity Loop
				$CPUActTimer.start()
			else:
				update_stats(false)
		"speed":
			# Show labels
			$UILayer/IngameUI/Speedrun.visible = true
			$UILayer/IngameUI/Speedrun/GameTimer.label_settings.font_color = Color("#f2f6ff")
			$UILayer/EndScreen/FinishLabel.text = "Speedrun Complete!"
			
			# Set the initial time to the current time
			initial_time = Time.get_ticks_msec()
			
			# Set game end variable.
			# Currently there must be one entry for every entry in global.settings.speedrun_mode
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
			
			update_stats(max_decks > 1)
	
	# Hide Pregame UI, Show Ingame UI
	$UILayer/IngameUI.visible = true
	
	# Start Game
	form_randomization()
	prepare_game()



# Append every possible card to all_cards
func form_randomization():
	for c in range(num_colors):
		for s in range(num_shapes):
			for f in range(num_fills):
				for k in range(num_counts):
					all_cards.append("%d%d%d%d" % [c, s, f, k])

# Check if all_cards is missing any cards
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

# Prepare the current game.
# Ensures that all card nodes are created and that a set is in the current set before starting.
func prepare_game(slide_in: bool = false):
	# Prepare a new card node for every space
	for row in range(total_rows):
		for col in range(total_columns):
			var this_card = card_scene.instantiate()
			prepare_new_card(this_card, row, col, total_rows, not(slide_in))
	
	# Check if the current cards have a set present within them
	if !is_current_cards_viable():
		# Current cards do not have a set present within them,
		# reset cards and try again.
		# Reset every card array.
		all_cards = []
		current_cards = []
		expended_cards = []
		selected_cards = []
		
		# Free every card node.
		for child in $CardContainer.get_children():
			child.free()
		
		print("Let's try that again.")
		form_randomization()
		prepare_game()
	else:
		# Current cards have a set present within them, game is ready.
		print("There's a set in there, don't worry.")


# Generates the properties for a new card by picking a random
# card out of all_cards.
func generate_new_card_props() -> String:
	# Check if there are no cards left
	if (len(all_cards) == 0):
		print("No cards left, returning blank.")
		return "-"
	
	# Randomly select a card
	var index = randi() % len(all_cards)
	# Remove permutation from all_cards, add to expended and current cards
	var card_props = all_cards.pop_at(index)
	expended_cards.append(card_props)
	current_cards.append(card_props)
	
	return card_props

# Creates a new card node.
func prepare_new_card(card, row: int, col: int, num_rows: int = total_rows, no_move: bool = false):
	# Number of spaces is (value) + 1
	#var this_card_x = (viewport_width / (total_columns + 1)) * (col + 1)
	#var this_card_y = (viewport_height / (total_rows + 1)) * (row + 1)
	
	# Randomize Card Properties by taking value from list of all cards
	var card_props = generate_new_card_props()
	
	# Check if there are no cards left
	if (card_props != "-"):
		# Set the node name to the unique permutation
		card.name = card_props
		
		# Set other properties of the card
		card.color = int(card_props[0])
		card.shape = int(card_props[1])
		card.fill = int(card_props[2])
		card.count = int(card_props[3])
		
		# Check if the card should instantly appear
		if no_move:
			# Immediately position the card
			card.position_card(num_rows, total_columns, row, col, true)
		else:
			# Animate the card moving in
			card.position = Vector2(viewport_width, viewport_height)
			card.scale = Vector2(0.15, 0.15)
			card.position_card_when_ready(num_rows, total_columns, row, col)
		
		# Connect signals with card click
		card.clicked.connect(card.toggle_selected)
		card.clicked.connect(on_card_clicked)
		
		#print("Adding Card %s" % card.name)
		
		# Add the card to the card container node
		$CardContainer.add_child(card)
		
		#var out = ""
		#for child in $CardContainer.get_children():
		#	out += child.name + ";"
		#print(out)
	else:
		# No cards left, remove this node.
		card.queue_free()

# Handler function for selected cards.
func on_card_clicked(combo: String, _player: int = -1):
	# Modify the selected cards array based on whether the player is
	# selecting or deselecting this card
	if (combo in selected_cards):
		selected_cards.remove_at(selected_cards.find(combo))
	else:
		selected_cards.append(combo)
		print(selected_cards)
	
	# Check if the number of selected cards is the same as the size of a set
	if len(selected_cards) == game_complexity:
		# Check if the selected cards form a set
		process_set_viability()


# Define behavior when a set is or isn't found.
# Sets are actually determined by is_collection_set.
func process_set_viability():
	if is_collection_set(selected_cards):
		# var previous_cards = current_cards.slice(0)
		
		if not(global.settings.mute_audio or global.settings.mute_sfx):
			$Audio/CorrectAudio.play()
		
		# Speedrun Progress Processing
		sets_completed += 1
		if (game_mode != "single") or (global.settings["cpu_difficulty"] == "None"):
			update_stats(max_decks > 1)
		
		# Update Head to Head Scores
		update_scoreboard()
		
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
			
			# Remove cards from CPU selected
			if combo in cpu_selected_cards:
				cpu_selected_cards.remove_at(cpu_selected_cards.find(combo))
			
			# var prev_index = previous_cards.find(combo)
			
			#var row = prev_index / total_columns
			#var col = prev_index % total_columns
			
			var row = total_rows - 1
			var col = total_columns - 1
			
			current_cards.remove_at(index)
			for i in range(index, len(current_cards)):
				var this_row: int = i / total_columns
				var this_col: int = i % total_columns
				
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
		
		overflow = 0
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
			on_game_over()
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
		# Currently selected cards do not form a set.
		# Play incorrect sound.
		if not(global.settings.mute_audio or global.settings.mute_sfx):
			$Audio/IncorrectAudio.play()
		
		# Reset card highlights and unselect every card
		for combo in selected_cards:
			$CardContainer.get_node(combo).toggle_selected("", 1)
		
		# Clear selected cards array
		selected_cards = []
		print("Not a set")

# Define behavior for when a set is found by the CPU.
func process_cpu_set_viability():
	if is_collection_set(cpu_selected_cards):
		# var previous_cards = current_cards.slice(0)
		
		if not(global.settings.mute_audio or global.settings.mute_sfx):
			$Audio/CorrectAudio.play()
		
		cpu_sets_completed += 1
		
		# Update Head to Head Scores
		update_scoreboard()
		
		# Get rid of the selected set, add a new set in place
		var first_index = -1
		for combo in cpu_selected_cards:
			$CardContainer.remove_child($CardContainer.get_node(combo))
			
			# Remove cards from player selected
			if combo in selected_cards:
				selected_cards.remove_at(selected_cards.find(combo))
			
			var index = current_cards.find(combo)
			if (first_index == -1):
				first_index = index
			
			# var prev_index = previous_cards.find(combo)
			
			var row = total_rows - 1
			var col = total_columns - 1
			
			current_cards.remove_at(index)
			for i in range(index, len(current_cards)):
				var this_row = i / total_columns
				var this_col = i % total_columns
				
				# print("Repositioning card at i%d (%s) to %d, %d" % [i, current_cards[i], this_row, this_col])
				$CardContainer.get_node(current_cards[i]).position_card(total_rows, total_columns, this_row, this_col)
			
			# Do not draw new cards when there are more than the default amount
			if (len(current_cards) < total_rows * total_columns):
				var this_card = card_scene.instantiate()
				prepare_new_card(this_card, row, col)
		
		cpu_selected_cards = []
		print("CPU Has found a set")
		
		overflow = 0
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
			on_game_over()
		else:
			print("Next set!")

	else:
		# Currently selected cards do not form a set.
		# Reset card highlights and unselect every card
		for combo in cpu_selected_cards:
			$CardContainer.get_node(combo).toggle_selected("", 2)
		
		# Clear selected cards array
		cpu_selected_cards = []

# Check if there is a set present in the currently shown cards.
# NOTE: For variable game complexity to work, this will need to be modified.
func is_current_cards_viable():
	# Check every combination of two cards
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
					cpu_current_set_combos = [combo1, combo2, combo3]
					if global.DEBUG_AUTOPLAY:
						return [combo1, combo2, combo3]
					else:
						return true
	
	# No set found, that's not good.
	return false

# Check if the currently selected cards form a set
# NOTE: For variable game complexity to work, this will need to be modified.
func is_collection_set(collection) -> bool:
	for p in range(4):
		var properties_sum = 0
		for n in range(len(collection)):
			properties_sum += int(collection[n][p])
		
		if properties_sum % num_variants[p] != 0:
			return false
	
	return true


# Handler for CPU Actions.
func _on_cpu_act_timer_timeout():
	# Check if CPU is idle
	if cpu_action == 0:
		cpu_action = 2 if randf() <= cpu_weights.cpu_set_likelihood[global.settings["cpu_difficulty"]] else 1
	
	# Check if card should be selected
	if randf() <= cpu_weights.cpu_select_likelihood[global.settings["cpu_difficulty"]]:
		# Select card based on action
		var card_index: int = 0
		var card_combo: String = ""
		print("CPU Selecting card (%d)" % cpu_action)
		if cpu_action == 1:
			# Select random card
			card_index = randi() % $CardContainer.get_child_count()
			card_combo = $CardContainer.get_child(card_index).name
		elif cpu_action == 2:
			# Select card in set
			card_combo = cpu_current_set_combos[len(cpu_selected_cards)]
			card_index = get_node("CardContainer/" + card_combo).get_index()
		
		if !(card_combo in cpu_selected_cards):
			cpu_selected_cards.append(card_combo)
			$CardContainer.get_child(card_index).toggle_selected(card_combo, 2)
		
		if len(cpu_selected_cards) == game_complexity:
			# Check if the selected cards form a set
			process_cpu_set_viability()


# Define behavior upon clearing a deck.
func on_game_over():
	# Play Disappearing Cards Animation
	for i in range(len(current_cards)):
		$CardContainer.get_node(current_cards[i]).position_card(total_rows, total_columns, 0, 0, false, true)
	
	decks_completed += 1
	
	# Stop Speedrun Timer
	var speedrun_complete = false
	if (game_mode == "speed"):
		# Stop Timer
		update_stats(max_decks > 1)
		if (max_decks > 0 and decks_completed >= max_decks) or (max_sets > 0 and sets_completed >= max_sets):
			speedrun_complete = true
			var speedrun_time_ms = Time.get_ticks_msec() - initial_time
			initial_time = 0
			if (global.speedrun_records[global.settings["speedrun_mode"]] == -1) \
					or (speedrun_time_ms < global.speedrun_records[global.settings["speedrun_mode"]]):
				$UILayer/IngameUI/Speedrun/GameTimer.label_settings.font_color = Color("#ffbb74")
				global.save_record(global.settings["speedrun_mode"], speedrun_time_ms)
			else:
				$UILayer/IngameUI/Speedrun/GameTimer.label_settings.font_color = Color("#74aaff")
	
	# Stop CPU Timer
	$CPUActTimer.stop()
	
	# Wait 0.75s
	await get_tree().create_timer(0.75).timeout
	
	all_cards = []
	expended_cards = []
	current_cards = []
	selected_cards = []
	
	for child in $CardContainer.get_children():
		child.free()
	
	if (game_mode == "single") or (game_mode == "speed" and speedrun_complete):
		if not(global.settings.mute_audio or global.settings.mute_sfx):
			if sets_completed >= cpu_sets_completed:
				$Audio/WinAudio.play()
			else:
				$Audio/LoseAudio.play()
				pass
		
		if (game_mode == "single") and (global.settings["cpu_difficulty"] != "None"):
			if sets_completed >= cpu_sets_completed:
				$UILayer/EndScreen/FinishLabel.text = "You Won!"
			else:
				$UILayer/EndScreen/FinishLabel.text = "You Lost..."
		
		$UILayer/IngameUI/Speedrun/SpeedrunProgress.visible = false
		$UILayer/EndScreen.visible = true
	else:
		# Prepare another deck
		form_randomization()
		prepare_game(true)



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	# Process Game size changes
	var new_y = (get_viewport_rect().size.y - viewport_height) / 2
	$CardContainer.position.y = new_y
	
	# Update speedrun timer
	if (game_mode == "speed") and (initial_time > 0):
		var current_time = Time.get_ticks_msec() - initial_time
		var formatted_time = global.format_time(current_time)
		$UILayer/IngameUI/Speedrun/GameTimer.text = formatted_time[0] + ":" + formatted_time[1] + "." + formatted_time[2]


# Restart the game.
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


# Update the stats label on the top right corner, showing your progress.
func update_stats(show_decks: bool = false):
	var new_label = ""
	new_label += "Sets Found: %d\n" % sets_completed
	if show_decks:
		new_label += "Decks Completed: %d\n" % decks_completed
	
	$UILayer/IngameUI/Stats/StatsLabel.text = new_label

# Update the record time displayed when speedrun mode is changed
func _on_speedrun_mode_setting_setting_changed(id: String, value):
	update_record_time(id, value)

func update_record_time(id: String, value):
	# Sanity Check
	if id == "speedrun_mode":
		var record_time_ms: int = global.speedrun_records[value]
		var record_time: Array = global.format_time(record_time_ms)
		$UILayer/PregameScreen/SettingsContainer/SpeedrunSettings/RecordTime.text = \
				"Record Time: %s:%s.%s" % [record_time[0], record_time[1], record_time[2]]

# Update the stats label on the top right corner, showing your progress.
func update_scoreboard():
	$UILayer/IngameUI/HeadToHead/Display/P1/P1Score.text = "%d" % sets_completed
	$UILayer/IngameUI/HeadToHead/Display/P2/P2Score.text = "%d" % cpu_sets_completed
