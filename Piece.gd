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
