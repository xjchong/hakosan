class_name Piece
extends Node2D

onready var label = $Label
onready var highlight_rect = $HighlightRect
var type = 'unknown'
var is_super = false


# Called when the node enters the scene tree for the first time.
func _ready():
	pass


func set_type(new_type, new_is_super = false):
	type = new_type
	is_super = new_is_super
	set_label()


func highlight():
	highlight_rect.visible = true


func unhighlight():
	highlight_rect.visible = false


func pulse_on(towards_position):
	highlight_rect.visible = true


func pulse_off():
	highlight_rect.visible = false
	
	
func set_label():
	label.text = type


func get_value():
	var modifier = 2 if is_super else 1
	var value_for_type = {
		'grass': 5,
		'bush': 20,
		'tree': 100,
		'bonfire': 500,
		'camp': 1500,
		'house': 5000,
		'mansion': 20000,
		'tower': 100000,
		'castle': 500000,
		'rock': 0,
		'mine': 1000,
		'gold': 10000,
		'treasure': 50000,
	}

	return modifier * value_for_type.get(type, 0)

		
