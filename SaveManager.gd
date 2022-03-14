extends Node


const SAVE_PATH = 'user://'


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
		'rows': rows,
		'columns': columns,
		'storage_positions': game.board.storage_positions,
		'board_types': board_types,
		'stored_piece_type' : null if game.board.stored_piece == null else game.board.stored_piece.type,
		'current_piece_type': null if game.current_piece == null else game.current_piece.type,
		'score': game.score
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

	game.board.rows = data['rows']
	game.board.columns = data['columns']
	game.score = data['score']

	if game.current_piece:
		game.current_piece.queue_free()
	game.set_next_piece(data['current_piece_type'])

	for x in data['columns']:
		for y in data['rows']:
			if game.board.board[x][y]:
				game.board.board[x][y].queue_free()
			game.board.place_piece(data['board_types'][x][y], Vector2(x, y), false)
	
	if game.board.stored_piece:
		game.board.stored_piece.queue_free()
	# TODO: Fix storage to be properly dynamic and support multiple storage spots.
	game.board.store_piece(data['stored_piece_type'], game.board.storage_positions[0])

	save_file.close()

	return true


func get_save_file_path(name):
	return SAVE_PATH + name + '.save'
