class_name Game
extends Node2D

onready var board = $Board as Board

const Piece = preload('res://Piece.tscn')

var current_piece = null
var score = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	board.setup_pieces()
	current_piece = get_next_piece()


func _process(_delta):
	if current_piece != null:
		if board.is_playable(current_piece):
			board.hover_piece(current_piece)
		else:
			current_piece.unhighlight()
			current_piece.position = get_global_mouse_position()


func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and not event.pressed:
			var action_type = board.get_action_type(current_piece)

			match action_type:
				'place':
					var value = board.place_piece(current_piece.type)

					if value != null:
						score += value
						current_piece.queue_free()
						current_piece = get_next_piece()
				'remove':
					var value = board.remove_piece()

					if value != null:
						score -= value
						current_piece.queue_free()
						current_piece = get_next_piece()


func get_next_piece():
	var type = get_next_piece_type()
	var piece = Piece.instance()
	add_child(piece)
	piece.set_type(type)

	return piece


func get_next_piece_type():
	var roll = randf()
	var chances = []
	var chance_acc = 0

	chances.append(['grass', 0.6])
	chances.append(['bush', 0.15])
	chances.append(['tree', 0.03])
	chances.append(['bonfire', 0.01])
	chances.append(['crystal', 0.03])
	chances.append(['hammer', 0.03])

	for chance in chances:
		chance_acc += chance[1]
		
		if roll < chance_acc:
			return chance[0]
	
	return 'slime'
	
	
