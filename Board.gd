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
var hover_position = null
var hover_piece_type = null

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
				place_piece('storage', Vector2.ZERO)
			else: 
				place_piece(get_starting_piece_type(), Vector2(x, y))


func place_piece(type, position = get_mouse_to_board_position()):
	if is_position_occupied(position) or type == null:
		return null

	var meld = get_meld(type, position)

	if meld[0] == type:
		var piece = Piece.instance()
		add_child(piece)
		piece.set_type(type)
		piece.position = Vector2(position.x * PIECE_SIZE, position.y * PIECE_SIZE) + PIECE_OFFSET
		board[position.x][position.y] = piece

		return 0
	else: 
		for meld_position in meld[1]:
			if meld_position != position:
				var meld_piece = board[meld_position.x][meld_position.y]
				meld_piece.queue_free()
				board[meld_position.x][meld_position.y] = null
			
		var piece = Piece.instance()
		add_child(piece)
		piece.set_type(meld[0])
		piece.position = Vector2(position.x * PIECE_SIZE, position.y * PIECE_SIZE) + PIECE_OFFSET
		board[position.x][position.y] = piece

		return piece.get_value()


func store_piece(type): 
	var old_stored_piece_type = null

	if stored_piece != null:
		old_stored_piece_type = stored_piece.type
		stored_piece.queue_free()

	stored_piece = Piece.instance()
	stored_piece.position = Vector2.ZERO + PIECE_OFFSET
	add_child(stored_piece)
	stored_piece.set_type(type)

	return old_stored_piece_type


func remove_piece(position = get_mouse_to_board_position()):
	if not is_position_occupied(position):
		return null

	var piece = board[position.x][position.y]
	var value = piece.get_value()

	board[position.x][position.y] = null
	piece.queue_free()

	return value


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
		return 'remove'
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

	# Don't want to retrigger pulsing of items.
	if piece.type == hover_piece_type and position == hover_position:
		return

	hover_piece_type = piece.type
	hover_position = position

	reset_pulse()

	var meld = get_meld(piece.type, position)

	for meld_position in meld[1]:
		if meld_position != position:
			var meld_piece = board[meld_position.x][meld_position.y]

			meld_piece.pulse_on(piece.position)


func reset_pulse():
	for row in ROWS:
		for col in COLUMNS:
			var piece = board[row][col]

			if piece != null:
				piece.pulse_off()


func get_group(type, position = get_mouse_to_board_position(), inside = [position]):
	var neighbors = get_neighbors(position)

	for neighbor in neighbors:
		var piece = board[neighbor.x][neighbor.y]

		if not neighbor in inside and piece != null and piece.type == type:
			inside.append(neighbor)
			get_group(type, neighbor, inside)

	return inside


func get_meld(type, position = get_mouse_to_board_position(), meld = []):
	var group = get_group(type, position)
	var upgrade = get_upgrade(type, group.size())

	if upgrade == null:
		return [type, meld]
	else: 
		# Note that the meld may contain duplicates of the origin position.
		return get_meld(upgrade, position, meld + group)



func get_neighbors(position):
	if (position == Vector2.ZERO): 
		return []

	var neighbors = []

	if position.x > 0:
		neighbors.append(position + Vector2.LEFT)
	
	if position.y > 0:
		neighbors.append(position + Vector2.UP)

	if position.x < COLUMNS - 1:
		neighbors.append(position + Vector2.RIGHT)

	if position.y < ROWS - 1:
		neighbors.append(position + Vector2.DOWN)

	return neighbors
	

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


func get_upgrade(type, quantity):
	var upgrade_for_type = {
		'grass': ['bush', 3],
		'bush': ['tree', 3],
		'tree': ['bonfire', 3],
		'bonfire': ['camp', 3],
		'camp': ['house', 3],
		'house': ['mansion', 3],
		'mansion': ['tower', 3],
		'tower': ['castle', 4],
		'rock': ['mine', 3],
		'mine': ['treasure', 3],
		'gold': ['treasure', 3],
		'grave': ['ruins', 3],
		'ruins': ['dungeon', 3],
		'dungeon': ['treasure', 3]
	}
	var upgrade = upgrade_for_type.get(type, [null, 0])

	if quantity >= upgrade[1]:
		return upgrade[0]
	else:
		return null
