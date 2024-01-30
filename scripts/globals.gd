extends Node

# For the game itself
var game_mode = ""

# Settings/Options
var settings = {
	# Generic Settings
	"current_colors": "Default",
	"mute_audio": false,
	"mute_music": false,
	"mute_sfx": false,
	
	# Gamemode Settings
	"cpu_difficulty": "None",
	"speedrun_mode": "1 Deck"
}

# Colorschemes
var colors = {
	"Default": ["#f7597b", "#7acc7a", "#aa74ff", "#74aaff", "#16171a"],
	"Alternative": ["#74aaff", "#7c7f8e", "#5dcc8c", "#f0db70", "#16171a"],
	"Plain": ["#ff5959", "#4cd94c", "#ba59ff", "#5990ff", "#242424"],
	"RGB": ["#ff0000", "#00ff00", "#8000ff", "#0000ff", "#000000"],
	"Sea": ["#dae55c", "#7bcdba", "#5c87cc", "#808080", "#242424"],
	"Monochrome Gray": ["#cccccc", "#333333", "#666666", "#999999", "#000000"]
}

# Define the options given when selecting in list settings.
var setting_options = {
	"colors": colors.keys(),
	"cpu_difficulty": ["None", "Easy", "Average", "Hard", "Mathematician"],
	"speedrun_mode": ["5 Sets", "10 Sets", "15 Sets", "50 Sets", "1 Deck", "2 Decks", "5 Decks"]
}

# Define Default Speedrun Records (in ms)
var speedrun_records = {
	"5 Sets": -1,
	"10 Sets": -1,
	"15 Sets": -1,
	"50 Sets": -1,
	"1 Deck": -1,
	"2 Decks": -1,
	"5 Decks": -1,
}

# Functions

# Format the time in ms to 00:00.000
func format_time(time_ms: int):
	if time_ms == -1:
		return ["--", "--", "---"]
	else:
		var seconds: int = int(floor(time_ms / 1000.0))
		var minutes: int = int(floor(seconds / 60.0))
		
		var minutes_s: String = "%02d" % (minutes)
		var seconds_s: String = "%02d" % (seconds % 60)
		var time_ms_s: String = "%03d" % (time_ms % 1000)
		
		return [minutes_s, seconds_s, time_ms_s]

# Save one speedrun record to file.
func save_record(category: String, time_ms: int):
	# Set Record
	speedrun_records[category] = time_ms
	
	# Write to File
	var record_file = FileAccess.open("user://records.json", FileAccess.WRITE)
	var records_as_json = JSON.stringify(speedrun_records)
	record_file.store_string(records_as_json)
	record_file.close()

# Load speedrun records
func load_records():
	var record_file = FileAccess.open("user://records.json", FileAccess.READ)
	var json = JSON.new()
	var error = json.parse(record_file.get_as_text())
	if error == OK:
		var stored_records = json.data
		for record_label in stored_records:
			speedrun_records[record_label] = stored_records[record_label]
	else:
		print("Couldn't Load Records! ", json.get_error_message())


# Load records when ready
func _ready():
	load_records()

# DEBUG
var DEBUG_AUTOPLAY = false
