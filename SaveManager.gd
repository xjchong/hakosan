extends Node


const SAVE_VERSION = 1
const SAVE_PATH = 'user://'


func _ready():
	randomize()


func save_game(game: Game, name = 'game'):
	if does_save_exist(name):
		delete_save(name)

	var save_file = File.new()
	var rows = game.board.rows
	var columns = game.board.columns
	var board = []

	for x in columns:
		board.append([])

		for y in rows:
			board[x].append(null)

			var piece = game.board.board[x][y]

			if piece != null:
				board[x][y] = {
					'type': piece.type,
					'turn': piece.turn
				}

	var data = {
		'save_version': SAVE_VERSION,
		'rows': rows,
		'columns': columns,
		'storage_positions': game.board.storage_positions,
		'board': board,
		'stored_piece_type' : null if game.board.stored_piece == null else game.board.stored_piece.type,
		'current_piece_type': null if game.current_piece == null else game.current_piece.type,
		'turn': game.turn,
		'score': game.score,
		'game_rng_seed': String(game.rng.seed), # Long integers are converted to string, because parsing converts ints to float. Rounding errors!
		'game_rng_state': String(game.rng.state),
		'board_rng_seed': String(game.board.rng.seed),
		'board_rng_state': String(game.board.rng.state),
	}

	save_file.open(get_save_file_path(name), File.WRITE)
	save_file.store_line(to_json(data))
	save_file.close()


# Loads save data into the given game.
func load_game(game: Game, name = 'game'):
	var save_file = File.new()
	var path = get_save_file_path(name)

	if not save_file.file_exists(path):
		return null

	save_file.open(path, File.READ)

	var data = parse_json(save_file.get_line())

	if data['save_version'] == 0:
		upgrade_v0(data)

	game.board.rows = data.get('rows', Board.STANDARD_ROWS)
	game.board.columns = data.get('columns', Board.STANDARD_COLUMNS)
	game.score = data.get('score', 0)
	game.turn = data.get('turn', 0)

	game.rng.seed = int(data.get('game_rng_seed', randi()))
	game.rng.state = int(data.get('game_rng_state', randi()))

	game.board.rng.seed = int(data.get('board_rng_seed', randi()))
	game.board.rng.state = int(data.get('board_rng_state', randi()))

	if game.current_piece:
		game.current_piece.queue_free()
		game.current_piece = null
	game.set_next_piece(data.get('current_piece_type', null))

	for x in data['columns']:
		for y in data['rows']:
			if game.board.board[x][y]:
				game.board.board[x][y].queue_free()
				game.board.board[x][y] = null

			var piece = data['board'][x][y]

			if piece != null:
				game.board.place_piece(piece['type'], piece['turn'], Vector2(x, y), false)
	
	if game.board.stored_piece:
		game.board.stored_piece.queue_free()
		game.board.stored_piece = null
	# TODO: Fix storage to be properly dynamic and support multiple storage spots.
	game.board.store_piece(data.get('stored_piece_type', null), game.board.storage_positions[0])

	save_file.close()

	return true


func delete_save(name):
	var directory = Directory.new()
	var path = get_save_file_path(name)

	directory.remove(path)


func does_save_exist(name):
	var save_file = File.new()

	return save_file.file_exists(get_save_file_path(name))


func get_save_file_path(name):
	return SAVE_PATH + name + '.save'


func upgrade_v0(data):
	# Need to infer what 'board' should be from 'board_types' (deprecated).
	# In v0, we only have board types. But in v1 we should have a 2d array 'board',
	# where each entry is either null or a dictionary that describes what piece is there.__data__
	# A piece has both a 'type' and a 'turn'.
	# We should also add in the turn field for good measure.

	data['save_version'] = 1

	var rows = data['rows']
	var columns = data['columns']
	var board_types = data['board_types']
	var board = []

	for x in columns:
		board.append([])

		for y in rows:
			board[x].append(null)

			var type = board_types[x][y]

			if type != null:
				board[x][y] = {
					'type': type,
					'turn': 0,
				}

	data['board'] = board

	return data
