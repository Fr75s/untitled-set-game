extends Node

var DEBUG_AUTOPLAY = false

var settings = {
	"current_colors": "Default",
	"mute_audio": false,
	"mute_music": false,
	"mute_sfx": false
}

var colors = {
	"Default": ["#f7597b", "#7acc7a", "#aa74ff", "#74aaff", "#16171a"],
	"Alternative": ["#74aaff", "#7c7f8e", "#5dcc8c", "#f0db70", "#16171a"],
	"Plain": ["#ff5959", "#4cd94c", "#ba59ff", "#5990ff", "#242424"],
	"RGB": ["#ff0000", "#00ff00", "#8000ff", "#0000ff", "#000000"],
	"Sea": ["#dae55c", "#7bcdba", "#5c87cc", "#808080", "#242424"],
	"Monochrome Gray": ["#cccccc", "#999999", "#666666", "#333333", "#000000"]
}

var setting_options = {
	"colors": colors.keys()
}
