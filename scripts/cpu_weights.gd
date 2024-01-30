extends Node

# CPU Randomizer weights

# Chance that the CPU will select a card each second.
# The greater the number, the more likely the CPU will select a card.
var cpu_select_likelihood = {
	"Easy": 0.1,
	"Average": 0.25,
	"Hard": 0.35,
	"Mathematician": 0.8
}

# List of odds that the CPU will make a set.
# The greater the number, the more likely the CPU will make a set upon selecting cards.
var cpu_set_likelihood = {
	"Easy": 0.5,
	"Average": 0.8,
	"Hard": 0.95,
	"Mathematician": 1.0
}
