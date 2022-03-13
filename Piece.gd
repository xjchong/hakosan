class_name Piece
extends Node2D

onready var label = $Label as Label
onready var highlight_rect = $HighlightRect as ColorRect
onready var tween = $Tween as Tween

var type = 'unknown'
var is_super = false
var pulse_positions = null


static func get_value_for_type(_type):
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
		'slime': 0,
		'grave': 0,
		'ruins': 1000,
		'dungeon': 5000,
	}

	return value_for_type.get(_type, 0)


func _ready():
	tween.connect('tween_all_completed', self, 'play_tween_pulse')


func set_type(new_type, new_is_super = false):
	type = new_type
	is_super = new_is_super
	set_label()


func highlight():
	highlight_rect.visible = true


func unhighlight():
	highlight_rect.visible = false


func pulse_on(towards_position):
	pulse_positions = [position, position.move_toward(towards_position, 4)]
	highlight_rect.visible = true
	play_tween_pulse()


func pulse_off():
	highlight_rect.visible = false
	tween.stop(self)

	if pulse_positions != null:
		position = pulse_positions[0]


func play_tween_pulse():
	var from = pulse_positions[0] if position == pulse_positions[0] else pulse_positions[1]
	var to = pulse_positions[1] if position == pulse_positions[0] else pulse_positions[0]

	tween.interpolate_property(self, 'position', from, to, 0.25)
	tween.start()

	
	
func set_label():
	label.text = type


func get_value():
	var modifier = 2 if is_super else 1

	return modifier * get_value_for_type(type)

		
