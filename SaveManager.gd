extends Node


const SAVE_VERSION = 0
const SAVE_PATH = 'user://'


func _ready():
	randomize()


func save_game(game: Game, name = 'game'):
	var save_file = File.new()
	var rows = game.board.rows
	var columns = game.board.columns
	var board_types = []

	for x in columns:
		board_types.append([])

		for y in rows:
			board_types[x].append(null)

			var piece = game.board.board[x][y]

			board_types[x][y] = null if piece == null else piece.type

	var data = {
		'save_version': SAVE_VERSION,
		'rows': rows,
		'columns': columns,
		'storage_positions': game.board.storage_positions,
		'board_types': board_types,
		'stored_piece_type' : null if game.board.stored_piece == null else game.board.stored_piece.type,
		'current_piece_type': null if game.current_piece == null else game.current_piece.type,
		'score': game.score,
		'game_rng_seed': game.rng.seed,
		'game_rng_state': game.rng.state,
		'board_rng_seed': game.board.rng.seed,
		'board_rng_state': game.board.rng.state,
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

	game.board.rows = data.get('rows', Board.STANDARD_ROWS)
	game.board.columns = data.get('columns', Board.STANDARD_COLUMNS)
	game.score = data.get('score', 0)

	game.rng.seed = data.get('game_rng_seed', randi())
	game.rng.state = data.get('game_rng_state', 0)

	game.board.rng.seed = data.get('board_rng_seed', randi())
	game.board.rng.state = data.get('board_rng_state', 0)

	if game.current_piece:
		game.current_piece.queue_free()
		game.current_piece = null
	game.set_next_piece(data.get('current_piece_type', null))

	for x in data['columns']:
		for y in data['rows']:
			if game.board.board[x][y]:
				game.board.board[x][y].queue_free()
				game.board.board[x][y] = null
			game.board.place_piece(data['board_types'][x][y], Vector2(x, y), false)
	
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
