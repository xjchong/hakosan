class_name Board
extends Node2D

onready var background = $Background as ColorRect

const Piece = preload('res://Piece.tscn')
const PieceCompanion = preload('res://Piece.gd')
const ToastText = preload('res://ToastText.tscn')

const STANDARD_ROWS = 6
const STANDARD_COLUMNS = 6
const STANDARD_STORAGE_POSITIONS = [Vector2.ZERO]

const PIECE_SIZE = 64
const PIECE_OFFSET = Vector2(int(PIECE_SIZE / 2), int(PIECE_SIZE / 2))

var rows = STANDARD_ROWS
var columns = STANDARD_COLUMNS
var storage_positions = STANDARD_STORAGE_POSITIONS
var board = []
var stored_piece = null
var hover_position = null
var hover_piece_type = null

var rng = RandomNumberGenerator.new()


func _ready():
	randomize()
	rng.seed = randi()

	background.set_size(Vector2(PIECE_SIZE * columns, PIECE_SIZE * rows))

	for x in columns:
		board.append([])

		for y in rows:
			board[x].append(null)


func setup_pieces():
	for x in STANDARD_COLUMNS:
		for y in STANDARD_ROWS:
			var position = Vector2(x, y)

			if position in STANDARD_STORAGE_POSITIONS:
				place_piece('storage', position, false)
			else: 
				place_piece(get_starting_piece_type(), position, false)
	
	trap_bears()


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
		'small_chest': 
			piece.queue_free()
			board[position.x][position.y] = null
			return
		'large_chest':
			piece.queue_free()
			board[position.x][position.y] = null
			return
		_:
			return


func place_piece(type, position = get_mouse_to_board_position(), should_fx = true):
	if is_position_occupied(position) or type == null:
		return null

	if type == 'crystal':
		type = get_wildcard_type(position)
	
	var placed_piece = Piece.instance()
	add_child(placed_piece)
	placed_piece.set_type(type)
	placed_piece.position = get_position_from_board_position(position)
	board[position.x][position.y] = placed_piece

	var value = meld_at_position(position, should_fx)

	# No meld happened.
	if value == null:
		value = placed_piece.get_value()

		if should_fx and value > 0:
			toast('+%d' % value, position)

	return value


func meld_at_position(position, should_fx = true):
	if position == null:
		return null
	
	var piece = board[position.x][position.y]

	if piece == null:
		return null
	
	var meld = get_meld(piece.type, position)

	if meld[0] == piece.type:
		return null
	else:
		for meld_position in meld[1]:
			if meld_position != position:
				var meld_piece = board[meld_position.x][meld_position.y]
				meld_piece.meld(get_position_from_board_position(position))
				board[meld_position.x][meld_position.y] = null
		
		piece.queue_free()

		var new_piece = Piece.instance()
		add_child(new_piece)
		new_piece.set_type(meld[0])
		new_piece.position = get_position_from_board_position(position)
		board[position.x][position.y] = new_piece

		var value = new_piece.get_value()

		if should_fx:
			AudioManager.play(Audio.MELD)

			if value > 0:
				toast('+%d' % value, position)
		
		return value


func toast(text, position):
	var toast_text = ToastText.instance()
	var offset = Vector2.UP * int(PIECE_SIZE / 2.0)
	toast_text.text = text
	toast_text.position = get_position_from_board_position(position) + offset
	add_child(toast_text)


func store_piece(type, position = get_mouse_to_board_position()): 
	if not position in storage_positions:
		return 'error'

	var old_stored_piece_type = null

	if stored_piece != null:
		old_stored_piece_type = stored_piece.type
		stored_piece.queue_free()

	stored_piece = Piece.instance()
	stored_piece.position = position + PIECE_OFFSET
	stored_piece.scale = Vector2(0.9, 0.9)
	add_child(stored_piece)
	stored_piece.set_type(type)

	return old_stored_piece_type


func hammer_piece(position = get_mouse_to_board_position()):
	if not is_position_occupied(position) or position in storage_positions:
		return null

	var piece = board[position.x][position.y]
	var type = piece.type
	var value = piece.get_value()

	piece.queue_free()
	board[position.x][position.y] = null

	match type:
		'mountain':
			value = -place_piece('small_chest', position)
			return value
		'bear':
			value = place_piece('tombstone', position)
			return value
		_: 
			if value > 0:
				toast('-%d' % value, position)
			return value


func is_position_occupied(position):
	return board[position.x][position.y] != null


func get_mouse_to_board_position():
	var mouse_position = get_local_mouse_position()
	var board_position = Vector2(int(mouse_position.x / PIECE_SIZE), int(mouse_position.y / PIECE_SIZE))

	if board_position.x < 0 or board_position.x >= columns:
		return null
	elif board_position.y < 0 or board_position.y >= rows:
		return null
	else:
		return board_position


func is_playable(piece, position = get_mouse_to_board_position()):
	return get_action_type(piece, position) != null


func get_action_type(piece, position = get_mouse_to_board_position()):
	if position == null:
		return null
	
	var board_piece = board[position.x][position.y]

	if board_piece != null and (board_piece.type == 'small_chest' or board_piece.type == 'large_chest'):
		return 'loot'
	elif position in storage_positions:
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
	for row in rows:
		for col in columns:
			var piece = board[row][col]

			if piece != null and is_instance_valid(piece):
				piece.pulse_off()
	
	hover_piece_type = null
	hover_position = null


func move_bears():
	var bear_positions = []

	# Get the positions of all the bears on board.
	for y in rows:
		for x in columns:
			var piece = board[x][y]

			if piece != null and piece.type == 'bear':
				bear_positions.append(Vector2(x, y))
	
	rng_shuffle(bear_positions)

	# Attempt to move each of the bears on the the board.
	for position in bear_positions:
		var neighbors = get_neighbors(position)
		rng_shuffle(neighbors)

		for neighbor in neighbors:
			if not is_position_occupied(neighbor):
				var bear = board[position.x][position.y]

				# TODO: Why is this check necessary?
				if bear != null:
					board[position.x][position.y] = null
					board[neighbor.x][neighbor.y] = bear

					bear.move(get_position_from_board_position(neighbor))


func trap_bears():
	for y in rows:
		for x in columns:
			var piece = board[x][y]

			if piece == null or piece.type != 'bear':
				continue
			
			var group = get_group('bear', Vector2(x, y))
			var is_group_trapped = true
			
			for bear_position in group:
				var neighbors = get_neighbors(bear_position)

				for neighbor in neighbors:
					if board[neighbor.x][neighbor.y] == null:
						is_group_trapped = false
						break
				
				if not is_group_trapped:
					break
				
			if is_group_trapped:
				for bear_position in group:
					var bear = board[bear_position.x][bear_position.y]

					if bear != null:
						bear.set_type('tombstone')


func meld_tombstones():
	var score = 0

	for y in rows:
		for x in columns:
			var piece = board[x][y]

			if piece == null or piece.type != 'tombstone':
				continue
			
			var group = get_group('tombstone', Vector2(x, y))
			var newest_tombstone = piece
			var newest_tombstone_position = Vector2(x, y)

			for tombstone_position in group:
				var tombstone = board[tombstone_position.x][tombstone_position.y]

				if tombstone != null and tombstone.type == 'tombstone' and tombstone.timestamp > newest_tombstone.timestamp:
					newest_tombstone = tombstone
					newest_tombstone_position = tombstone_position
			
			var meld_value = meld_at_position(newest_tombstone_position)
			
			if meld_value != null:
				score += meld_value
	
	return score


func get_wildcard_type(position):
	var neighbors = get_neighbors(position)
	var tried_types = []
	var best_type = null
	var best_meld_value = 0
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
		var meld_value = PieceCompanion.get_value_for_type(meld[0])
		var meld_size = meld[1].size()

		if meld[0] == piece.type:
			# Meld was unsuccessful with this type.
			continue
		elif meld_value > best_meld_value or (meld_value == best_meld_value and meld_size > best_meld_size):
			best_type = piece.type
			best_meld_value = meld_value
			best_meld_size = meld_size
	
	if best_type == null or best_type == 'crystal':
		return 'rock'
	else:
		return best_type


func get_group(type, position = get_mouse_to_board_position(), inside = [position]):
	var neighbors = get_neighbors(position)

	for neighbor in neighbors:
		var piece = board[neighbor.x][neighbor.y]

		if not neighbor in inside and piece != null and can_types_group(piece.type, type):
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

	if position.x < columns - 1:
		neighbors.append(position + Vector2.RIGHT)

	if position.y < rows - 1:
		neighbors.append(position + Vector2.DOWN)

	return neighbors
	

func get_starting_piece_type():
	var roll = rng.randf()
	var chances = []
	var chance_acc = 0

	chances.append(['grass', 0.15])
	chances.append(['bush', 0.06])
	chances.append(['tree', 0.03])
	chances.append(['rock', 0.03])
	chances.append(['tombstone', 0.03])
	chances.append(['bear', 0.03])

	for chance in chances:
		chance_acc += chance[1]

		if roll < chance_acc:
			return chance[0]

	
	return null


func get_upgrade(type, quantity):
	var upgrade_for_type = {
		'grass': ['bush', 3],
		'bush': ['tree', 3],
		'super_bush': ['tree', 3],
		'tree': ['hut', 3],
		'super_tree': ['hut', 3],
		'hut': ['house', 3],
		'super_hut': ['house', 3],
		'house': ['mansion', 3],
		'super_house': ['mansion', 3],
		'mansion': ['castle', 3],
		'super_mansion': ['castle', 3],
		'castle': ['floating_castle', 3],
		'super_castle': ['floating_castle', 3],
		'floating_castle': ['triple_castle', 4],
		'rock': ['mountain', 3],
		'mountain': ['large_chest', 3],
		'small_chest': ['large_chest', 3],
		'tombstone': ['church', 3],
		'church': ['cathedral', 3],
		'super_church': ['cathedral', 3],
		'cathedral': ['small_chest', 3],
		'super_cathedral': ['small_chest', 3],
	}
	var upgrade = upgrade_for_type.get(type, [null, 0])

	if quantity >= upgrade[1]:
		return 'super_' + upgrade[0] if can_super(upgrade[0], quantity) else upgrade[0]
	else:
		return null


func can_types_group(type1, type2):
	if type1 == type2:
		return true
	
	if type1.length() > type2.length():
		return 'super_' + type2 == type1
	elif type1.length() < type2.length():
		return 'super_' + type1 == type2
	else:
		return false


func can_super(type, quantity):
	var can_super = [
		'bush',
		'tree',
		'hut',
		'house',
		'mansion',
		'castle',
		'floating_castle',
		'church',
		'cathedral',
	]

	return quantity > 3 and type in can_super


func rng_shuffle(list):
	var n = list.size()
	for i in range(0, n - 2):
		var j = rng.randi_range(0, n - 1)
		var swap = list[i]

		list[i] = list[j]
		list[j] = swap

