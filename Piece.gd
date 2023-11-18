class_name Piece
extends Node2D

@onready var label = $Label as Label
@onready var appearance = $AppearanceSprite as AnimatedSprite2D
@onready var highlight_rect = $HighlightRect as ColorRect
@onready var animation_player = $AnimationPlayer as AnimationPlayer

var type = 'unknown'
var turn = 0
var pulse_positions = null
var tween_pulse: Tween = null


static func get_value_for_type(_type):
	var value_for_type = {
		'grass': 5,
		'bush': 20,
		'super_bush': 40,
		'tree': 100,
		'super_tree': 200,
		'hut': 500,
		'super_hut': 1000,
		'house': 1500,
		'super_house': 3000,
		'mansion': 5000,
		'super_mansion': 10000,
		'castle': 20000,
		'super_castle': 40000,
		'floating_castle': 100000,
		'super_floating_castle': 200000,
		'triple_castle': 500000,
		'rock': 0,
		'mountain': 1000,
		'small_chest': 10000,
		'large_chest': 50000,
		'bear': 0,
		'tombstone': 0,
		'church': 1000,
		'super_church': 2000,
		'cathedral': 5000,
		'super_cathedral': 10000,
	}

	return value_for_type.get(_type, 0)


func set_type(new_type):
	type = new_type
	set_appearance()


func set_turn(new_turn):
	turn = new_turn
	label.text = str(new_turn)


func highlight():
	animation_player.play('highlight')


func unhighlight():
	animation_player.play('RESET')


func pulse_on(towards_position):
	pulse_positions = [position, position.move_toward(towards_position, 4)]
	play_tween_pulse()


func pulse_off():
	if tween_pulse:
		tween_pulse.stop()
	if pulse_positions != null:
		position = pulse_positions[0]


func play_tween_pulse():
	var from = pulse_positions[0] if position == pulse_positions[0] else pulse_positions[1]
	var to = pulse_positions[1] if position == pulse_positions[0] else pulse_positions[0]
	
	tween_pulse = create_tween()
	await tween_pulse.tween_property(self, 'position', to, 0.25).from(from).finished
	play_tween_pulse()


func move(to):
	create_tween().tween_property(self, 'position', to, 0.3)


func meld(to, should_fx = true):
	if should_fx:
		var tween_meld = create_tween()
		(tween_meld.tween_property(self, 'position', to, 0.1)
			.set_trans(Tween.TRANS_LINEAR)
			.set_ease(Tween.EASE_IN))
		(tween_meld.tween_property(self, 'modulate', Color(1, 1, 1, 0), 0.1)
			.from(Color(1, 1, 1, 1)))
		await tween_meld.finished
		queue_free()
	else:
		queue_free()


func set_appearance():
	var frame_for_type = {
		'grass': 0,
		'bush': 1,
		'super_bush': 19,
		'tree': 2,
		'super_tree': 20,
		'hut': 3,
		'super_hut': 21,
		'house': 4,
		'super_house': 22,
		'mansion': 5,
		'super_mansion': 23,
		'castle': 6,
		'super_castle': 24,
		'floating_castle': 7,
		'super_floating_castle': 25,
		'triple_castle': 8,
		'bear': 9,
		'tombstone': 10,
		'church': 11,
		'super_church': 26,
		'cathedral': 12,
		'super_cathedral': 27,
		'small_chest': 13,
		'large_chest': 14,
		'crystal': 15,
		'hammer': 16,
		'rock': 17,
		'mountain': 18,
		'storage': 34,
		'arrow': 35,
	}

	appearance.frame = frame_for_type.get(type, 34)


func get_value():
	return get_value_for_type(type)

		
