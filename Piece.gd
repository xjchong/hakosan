class_name Piece
extends Node2D

onready var label = $Label
onready var highlight_rect = $HighlightRect
var type = 'unknown'


# Called when the node enters the scene tree for the first time.
func _ready():
	pass


func set_type(new_type):
	type = new_type
	set_label()


func highlight():
	highlight_rect.visible = true


func unhighlight():
	highlight_rect.visible = false
	
	
func set_label():
	label.text = type


func get_value():
	match type:
		'grass': return 5
		'bush': return 20
		'tree': return 100
		'bonfire': return 500
		'camp': return 1500
		'house': return 5000
		'mansion': return 20000
		'tower': return 100000
		'castle': return 500000
		'rock': return 0
		'mine': return 1000
		'gold': return 10000
		'treasure': return 50000
		_: return 0
		
