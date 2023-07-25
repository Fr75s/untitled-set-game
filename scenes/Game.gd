extends Node2D

@export var card_scene: PackedScene

signal set_found

var all_cards = []
var expended_cards = []

var current_cards = []
var selected_cards = []

# Called when the node enters the scene tree for the first time.
func _ready():
	#ProjectSettings.set_setting("rendering/environment/defaults/default_clear_color", Color("#16171a"))
	form_randomization()
	prepare_game()

var total_rows = 4
var total_columns = 3

var viewport_height = ProjectSettings.get_setting("display/window/size/viewport_height")
var viewport_width = ProjectSettings.get_setting("display/window/size/viewport_width")

var num_colors = 3
var num_shapes = 3
var num_fills = 3
var num_counts = 3

var num_variants = [num_colors, num_shapes, num_fills, num_counts]

func form_randomization():
	for c in range(num_colors):
		for s in range(num_shapes):
			for f in range(num_fills):
				for k in range(num_counts):
					all_cards.append("%d%d%d%d" % [c, s, f, k])

func prepare_game():
	var all_cards_backup = all_cards.slice(0)
	
	for row in range(total_rows):
		for col in range(total_columns):
			var this_card = card_scene.instantiate()
			prepare_new_card(this_card, row, col)
			
	
	if !is_current_cards_viable():
		all_cards = all_cards_backup
		current_cards = []
		expended_cards = []
		
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

func prepare_new_card(card, row, col, num_rows = total_rows):
	# Number of spaces is (value) + 1
	#var this_card_x = (viewport_width / (total_columns + 1)) * (col + 1)
	#var this_card_y = (viewport_height / (total_rows + 1)) * (row + 1)
	
	# Randomize Card Properties by taking value from list of all cards
	var card_props = generate_new_card_props()
	
	if (card_props != "-"):
		card.name = card_props
		
		card.color = card_props[0] as int
		card.shape = card_props[1] as int
		card.fill = card_props[2] as int
		card.count = card_props[3] as int
		
		card.position_card(num_rows, total_columns, row, col, true)
		
		card.clicked.connect(card.toggle_selected)
		card.clicked.connect(on_card_clicked)
		
		$CardContainer.add_child(card)

func on_card_clicked(combo: String):
	if (combo in selected_cards):
		selected_cards.remove_at(selected_cards.find(combo))
	else:
		selected_cards.append(combo)
		print(selected_cards)
	
	if len(selected_cards) == 3:
		process_set_viability()



func process_set_viability():
	if is_collection_set(selected_cards):
		var previous_cards = current_cards.slice(0)
		
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
			else:
				for i in range(len(current_cards)):
					$CardContainer.get_node(current_cards[i]).position_card(total_rows, total_columns, 0, 0, false, true)
				
				print("Well played.")
		
		print("Next set!")
		
		# AUTOPLAY
		#var viable_combos = is_current_cards_viable()
		#if is_current_cards_viable():
		#	await get_tree().create_timer(0.75).timeout
		#	on_card_clicked(viable_combos[0])
		#	on_card_clicked(viable_combos[1])
		#	on_card_clicked(viable_combos[2])

	else:
		for combo in selected_cards:
			$CardContainer.get_node(combo).modulate = Color(1.0, 1.0, 1.0)
			$CardContainer.get_node(combo).selected = false
		
		selected_cards = []
		print("not a set")

func is_current_cards_viable() -> bool:
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
					return true # Comment to AUTOPLAY
					# Uncomment to AUTOPLAY -> return [combo1, combo2, combo3]

	# No set found, that's not good.
	return false

func is_collection_set(collection) -> bool:
	for p in range(4):
		var properties_sum = 0
		for n in range(len(collection)):
			properties_sum += collection[n][p] as int
		
		if properties_sum % num_variants[p] != 0:
			return false
	
	return true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	var new_y = (get_viewport_rect().size.y - viewport_height) / 2
	$CardContainer.position.y = new_y
