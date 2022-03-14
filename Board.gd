class_name Board
extends Node2D

onready var background = $Background as ColorRect

const Piece = preload('res://Piece.tscn')
const PieceCompanion = preload('res://Piece.gd')

const ROWS = 6
const COLUMNS = 6
const PIECE_SIZE = 64
const PIECE_OFFSET = Vector2(int(PIECE_SIZE / 2), int(PIECE_SIZE / 2))
const STORAGE_POSITION = Vector2.ZERO

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
				place_piece('storage', STORAGE_POSITION)
			else: 
				place_piece(get_starting_piece_type(), Vector2(x, y))
	
	trap_slimes()


func get_position_from_board_position(board_position):
	return Vector2(board_position.x * PIECE_SIZE, board_position.y * PIECE_SIZE) + PIECE_OFFSET


# TODO: Add actual loot inside!
func loot_piece(position = get_mouse_to_board_position()):
	if position == null:
		return

	var piece = board[position.x][position.y]
	var type = null

	if piece != null:
		type = piece.type
	
	match type:
		'gold': 
			piece.queue_free()
			board[position.x][position.y] = null
			return
		'treasure':
			piece.queue_free()
			board[position.x][position.y] = null
			return
		_:
			return


func place_piece(type, position = get_mouse_to_board_position()):
	if is_position_occupied(position) or type == null:
		return null

	if type == 'crystal':
		type = get_wildcard_type(position)

	var meld = get_meld(type, position)
	var value = null

	if meld[0] == type:
		var piece = Piece.instance()
		add_child(piece)
		piece.set_type(type)
		piece.position = get_position_from_board_position(position)
		board[position.x][position.y] = piece

		value = 0
	else: 
		for meld_position in meld[1]:
			if meld_position != position:
				var meld_piece = board[meld_position.x][meld_position.y]
				meld_piece.meld(get_position_from_board_position(position))
				board[meld_position.x][meld_position.y] = null
			
		var piece = Piece.instance()
		add_child(piece)
		piece.set_type(meld[0])
		piece.position = get_position_from_board_position(position)
		board[position.x][position.y] = piece

		value = piece.get_value()
	
	return value


func store_piece(type): 
	var old_stored_piece_type = null

	if stored_piece != null:
		old_stored_piece_type = stored_piece.type
		stored_piece.queue_free()

	stored_piece = Piece.instance()
	stored_piece.position = STORAGE_POSITION + PIECE_OFFSET
	add_child(stored_piece)
	stored_piece.set_type(type)

	return old_stored_piece_type


func hammer_piece(position = get_mouse_to_board_position()):
	if not is_position_occupied(position) or position == STORAGE_POSITION:
		return null

	var piece = board[position.x][position.y]
	var type = piece.type
	var value = piece.get_value()

	piece.queue_free()
	board[position.x][position.y] = null

	match type:
		'mine':
			return -place_piece('gold', position)
		'slime':
			return -place_piece('grave', position)
		_: 
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
	
	var board_piece = board[position.x][position.y]

	if board_piece != null and (board_piece.type == 'gold' or board_piece.type == 'treasure'):
		return 'loot'
	elif position == STORAGE_POSITION:
		return 'store'
	elif piece.type == 'hammer' && is_position_occupied(position):
		return 'hammer'
	elif not piece.type == 'hammer' and not is_position_occupied(position):
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

	reset_hover()

	hover_piece_type = piece.type
	hover_position = position

	var type = get_wildcard_type(position) if piece.type == 'crystal' else piece.type
	var meld = get_meld(type, position)

	for meld_position in meld[1]:
		if meld_position != position:
			var meld_piece = board[meld_position.x][meld_position.y]

			meld_piece.pulse_on(piece.position - self.position)


func reset_hover():
	for row in ROWS:
		for col in COLUMNS:
			var piece = board[row][col]

			if piece != null:
				piece.pulse_off()
	
	hover_piece_type = null
	hover_position = null


func move_slimes():
	var slime_positions = []

	# Get the positions of all the slimes on board.
	for y in ROWS:
		for x in COLUMNS:
			var piece = board[x][y]

			if piece != null and piece.type == 'slime':
				slime_positions.append(Vector2(x, y))
	
	slime_positions.shuffle()

	# Attempt to move each of the slimes on the the board.
	for position in slime_positions:
		var neighbors = get_neighbors(position)
		neighbors.shuffle()

		for neighbor in neighbors:
			if not is_position_occupied(neighbor):
				var slime = board[position.x][position.y]

				# TODO: Why is this check necessary?
				if slime != null:
					board[position.x][position.y] = null
					board[neighbor.x][neighbor.y] = slime

					slime.move(get_position_from_board_position(neighbor))


func trap_slimes():
	for y in ROWS:
		for x in COLUMNS:
			var piece = board[x][y]

			if piece == null or piece.type != 'slime':
				continue
			
			var group = get_group('slime', Vector2(x, y))
			var is_group_trapped = true
			
			for slime_position in group:
				var neighbors = get_neighbors(slime_position)

				for neighbor in neighbors:
					if board[neighbor.x][neighbor.y] == null:
						is_group_trapped = false
						break
				
				if not is_group_trapped:
					break
				
			if is_group_trapped:
				for slime_position in group:
					var slime = board[slime_position.x][slime_position.y]

					if slime != null:
						slime.set_type('grave')


func meld_graveyards():
	var score = 0

	for y in ROWS:
		for x in COLUMNS:
			var piece = board[x][y]

			if piece == null or piece.type != 'grave':
				continue
			
			var group = get_group('grave', Vector2(x, y))
			var newest_grave = piece
			var newest_grave_position = Vector2(x, y)

			for grave_position in group:
				var grave = board[grave_position.x][grave_position.y]

				if grave != null and grave.type == 'grave' and grave.timestamp > newest_grave.timestamp:
					newest_grave = grave
					newest_grave_position = grave_position
			
			newest_grave.queue_free()
			board[newest_grave_position.x][newest_grave_position.y] = null
			score += place_piece('grave', newest_grave_position)
	
	return score


func get_wildcard_type(position):
	var neighbors = get_neighbors(position)
	var tried_types = []
	var best_type = null
	var best_meld_size = 0

	for neighbor in neighbors:
		var piece = board[neighbor.x][neighbor.y]

		if piece == null:
			continue
		
		if piece.type in tried_types:
			continue
		else:
			tried_types.append(piece.type)

		var meld = get_meld(piece.type, position)
		var best_value = PieceCompanion.get_value_for_type(best_type)
		var meld_value = PieceCompanion.get_value_for_type(meld[0])

		if meld[0] == piece.type:
			# Meld was unsuccessful with this type.
			continue
		elif meld_value > best_value or (meld_value == best_value and meld[1].size() > best_meld_size):
			best_type = piece.type
			best_meld_size = meld[1].size()
	
	if best_type == null or best_type == 'crystal':
		return 'rock'
	else:
		return best_type


func get_group(type, position = get_mouse_to_board_position(), inside = [position]):
	var neighbors = get_neighbors(position)

	for neighbor in neighbors:
		var piece = board[neighbor.x][neighbor.y]

		if not neighbor in inside and piece != null and piece.type == type:
			inside.append(neighbor)
			get_group(type, neighbor, inside)

	return inside


# Returns [resulting type at position, list of positions melded including the origin]
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
