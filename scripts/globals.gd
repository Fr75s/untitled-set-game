extends Node

# For the game itself

var game_mode = ""

# Settings & More

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

var colors = {
	"Default": ["#f7597b", "#7acc7a", "#aa74ff", "#74aaff", "#16171a"],
	"Alternative": ["#74aaff", "#7c7f8e", "#5dcc8c", "#f0db70", "#16171a"],
	"Plain": ["#ff5959", "#4cd94c", "#ba59ff", "#5990ff", "#242424"],
	"RGB": ["#ff0000", "#00ff00", "#8000ff", "#0000ff", "#000000"],
	"Sea": ["#dae55c", "#7bcdba", "#5c87cc", "#808080", "#242424"],
	"Monochrome Gray": ["#cccccc", "#333333", "#666666", "#999999", "#000000"]
}

var setting_options = {
	"colors": colors.keys(),
	"cpu_difficulty": ["None", "Easy", "Average", "Hard", "Mathematician"],
	"speedrun_mode": ["5 Sets", "10 Sets", "15 Sets", "50 Sets", "1 Deck", "2 Decks", "5 Decks"]
}

# Functions

func format_time(time_ms):
	var seconds = int(floor(time_ms / 1000.0))
	var minutes = int(floor(seconds / 60.0))
	
	minutes = "%02d" % (minutes)
	seconds = "%02d" % (seconds % 60)
	time_ms = "%03d" % (time_ms % 1000)
	
	return [str(minutes), str(seconds), str(time_ms)]

# DEBUG

var DEBUG_AUTOPLAY = false
