class_name Board
extends Node2D

onready var background = $Background as ColorRect

const Piece = preload('res://Piece.tscn')

const ROWS = 6
const COLUMNS = 6
const PIECE_SIZE = 64
const PIECE_OFFSET = Vector2(int(PIECE_SIZE / 2), int(PIECE_SIZE / 2))

var board = []
var stored_piece = null

func _ready():
	background.set_size(Vector2(PIECE_SIZE * COLUMNS, PIECE_SIZE * ROWS))

	for x in COLUMNS:
		board.append([])

		for y in ROWS:
			board[x].append(null)


func setup_pieces():
	randomize()

	for x in COLUMNS:
		for y in ROWS:
			if x == 0 and y == 0:
				place_piece('storage', Vector2(x, y))
			else: 
				place_piece(get_starting_piece_type(), Vector2(x, y))


func place_piece(type, position = get_mouse_to_board_position()):
	if is_position_occupied(position) or type == null:
		return null

	var piece = Piece.instance()
	add_child(piece)
	piece.set_type(type)
	piece.position = Vector2(position.x * PIECE_SIZE, position.y * PIECE_SIZE) + PIECE_OFFSET

	board[position.x][position.y] = piece

	return 0


func is_position_occupied(position):
	return board[position.x][position.y] != null


func get_mouse_to_board_position():
	var mouse_position = get_local_mouse_position()
	var board_position = Vector2(int(mouse_position.x / PIECE_SIZE), int(mouse_position.y / PIECE_SIZE))

	if board_position.x < 0 or board_position.x >= COLUMNS:
		return null
	elif board_position.y < 0 or board_position.y >= ROWS:
		return null
	else:
		return board_position


func is_playable(piece, position = get_mouse_to_board_position()):
	return get_action_type(piece, position) != null


func get_action_type(piece, position = get_mouse_to_board_position()):
	if position == null:
		return null
	elif position == Vector2.ZERO:
		return 'store'
	elif piece.type == 'hammer' && is_position_occupied(position):
		return 'hammer'
	elif not is_position_occupied(position):
		return 'place'
	else:
		return null


func hover_piece(piece, position = get_mouse_to_board_position()):
	piece.highlight()
	piece.position = Vector2(
		position.x * PIECE_SIZE,
		position.y * PIECE_SIZE
	) + PIECE_OFFSET + self.position


func get_starting_piece_type():
	var roll = randf()
	var chances = []
	var chance_acc = 0

	chances.append(['grass', 0.15])
	chances.append(['bush', 0.06])
	chances.append(['tree', 0.03])
	chances.append(['rock', 0.03])
	chances.append(['grave', 0.03])
	chances.append(['slime', 0.03])

	for chance in chances:
		chance_acc += chance[1]

		if roll < chance_acc:
			return chance[0]

	
	return null
