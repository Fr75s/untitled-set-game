extends Control

@export_category("Credit Labels")
@export var descriptor: String = ""
@export var credited_name: String = ""

# Called when the node enters the scene tree for the first time.
func _ready():
	$Descriptor.text = descriptor
	$Name.text = credited_name
