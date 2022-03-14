class_name Piece
extends Node2D

onready var label = $Label as Label
onready var appearance = $AppearanceSprite as AnimatedSprite
onready var highlight_rect = $HighlightRect as ColorRect
onready var tween_pulse = $TweenPulse as Tween
onready var tween_move = $TweenMove as Tween
onready var tween_meld = $TweenMeld as Tween

var type = 'unknown'
var is_super = false
var pulse_positions = null
var timestamp = 0


static func get_value_for_type(_type):
	var value_for_type = {
		'grass': 5,
		'bush': 20,
		'tree': 100,
		'hut': 500,
		'house': 1500,
		'mansion': 5000,
		'castle': 20000,
		'floating_castle': 100000,
		'triple_castle': 500000,
		'rock': 0,
		'mountain': 1000,
		'small_chest': 10000,
		'large_chest': 50000,
		'bear': 0,
		'tombstone': 0,
		'church': 1000,
		'cathedral': 5000,
	}

	return value_for_type.get(_type, 0)


func _ready():
	timestamp = OS.get_ticks_msec()
	tween_pulse.connect('tween_all_completed', self, 'play_tween_pulse')
	tween_meld.connect('tween_all_completed', self, 'queue_free')


func set_type(new_type, new_is_super = false):
	type = new_type
	is_super = new_is_super
	set_appearance()


func highlight():
	highlight_rect.visible = true


func unhighlight():
	highlight_rect.visible = false


func pulse_on(towards_position):
	pulse_positions = [position, position.move_toward(towards_position, 4)]
	play_tween_pulse()


func pulse_off():
	tween_pulse.stop(self)

	if pulse_positions != null:
		position = pulse_positions[0]


func play_tween_pulse():
	var from = pulse_positions[0] if position == pulse_positions[0] else pulse_positions[1]
	var to = pulse_positions[1] if position == pulse_positions[0] else pulse_positions[0]

	tween_pulse.interpolate_property(self, 'position', from, to, 0.25)
	tween_pulse.start()


func move(to):
	tween_move.interpolate_property(self, 'position', position, to, 0.3)
	tween_move.start()


func meld(to):
	tween_meld.interpolate_property(self, 'position', position, to, 0.1, Tween.TRANS_LINEAR, Tween.EASE_IN)
	tween_meld.interpolate_property(self, 'modulate', Color(1, 1, 1, 1), Color(1, 1, 1, 0), 0.1)
	tween_meld.start()
	
	
func set_label():
	label.text = type


func set_appearance():
	var frame_for_type = {
		'grass': 0,
		'bush': 1,
		'tree': 2,
		'hut': 3,
		'house': 4,
		'mansion': 5,
		'castle': 6,
		'floating_castle': 7,
		'triple_castle': 8,
		'bear': 9,
		'tombstone': 10,
		'church': 11,
		'cathedral': 12,
		'small_chest': 13,
		'large_chest': 14,
		'crystal': 15,
		'hammer': 16,
		'rock': 17,
		'mountain': 18,
		'storage': 35,
	}

	appearance.frame = frame_for_type.get(type, 34)


func get_value():
	var modifier = 2 if is_super else 1

	return modifier * get_value_for_type(type)

		
