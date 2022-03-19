class_name Game
extends Node2D

onready var board = $Board as Board
onready var score_label = $ScoreLabel as Label
onready var highscore_label = $HighscoreLabel as Label
onready var game_over_label = $GameOverLabel as Label
onready var board_area = $BoardArea as PanelContainer
onready var recipe_overlay = $RecipeOverlay as RecipeOverlay
onready var new_game_button = $NewGameButton as Button
onready var undo_button = $UndoButton as Button
onready var board_theme_button = $BoardThemeButton as Button

const Piece = preload('res://Piece.tscn')
const ToastText = preload('res://ToastText.tscn')

var current_piece = null
var score = 0
var highscore = 0
var turn = 0

var rng = RandomNumberGenerator.new()
var rng_seed = null

func _ready():
	randomize()
	rng.seed = randi()

	if not SaveManager.load_game(self):
		board.setup_pieces()
		set_next_piece()

	score_label.text = String(score)

	highscore = SettingsManager.load_setting('highscore', 'value', 0)
	highscore_label.text = String(highscore)

	new_game_button.connect('pressed', self, 'reset_game')
	undo_button.connect('pressed', self, 'undo')
	board_area.connect('mouse_entered', self, 'on_mouse_entered_board_area')
	board_area.connect('mouse_exited', self, 'on_mouse_exited_board_area')
	board_theme_button.connect('pressed', self, 'cycle_board_theme')

	undo_button.visible = SaveManager.does_save_exist('undo')

	handle_game_over()


func _input(event):
	if event is InputEventMouseMotion:
		if current_piece != null and is_instance_valid(current_piece):
			if board.is_playable(current_piece.type):
				board.hover_piece(current_piece)
			else:
				board.reset_hover()
				current_piece.unhighlight()
				current_piece.position = get_global_mouse_position()
		
		# Show recipe overlay
		var board_position = board.get_mouse_to_board_position()

		if board_position != null:
			var board_piece = board.board[board_position.x][board_position.y]

			if board_piece != null:
				if board_piece.type == 'storage':
					var stored_piece = board.stored_piece

					if stored_piece:
						recipe_overlay.show_recipe(stored_piece.type)
				else:
					recipe_overlay.show_recipe(board_piece.type)
			elif current_piece != null and current_piece.visible:
				recipe_overlay.show_recipe(current_piece.type)
			else:
				recipe_overlay.clear_recipe()
		else:
			recipe_overlay.clear_recipe()
			
	elif event is InputEventMouseButton:
		if event.button_index == BUTTON_RIGHT and not event.pressed:
			var stored_piece_type = board.store_piece(current_piece.type, board.storage_positions[0])
			
			if stored_piece_type != 'error':
				current_piece.queue_free()
				AudioManager.play(Audio.STORE)

			if stored_piece_type == null:
				set_next_piece()
			else:
				set_next_piece(stored_piece_type)
		if event.button_index == BUTTON_LEFT and not event.pressed:
			var action_type = board.get_action_type(current_piece.type if current_piece else null)

			match action_type:
				'loot':
					SaveManager.save_game(self, 'undo')
					board.loot_piece()
					turn += 1
					AudioManager.play(Audio.LOOT)
				'place':
					SaveManager.save_game(self, 'undo')
					var value = board.place_piece(current_piece.type, turn)

					if value != null:
						current_piece.queue_free()
						set_next_piece()
						board.move_bears()
						board.trap_bears()
						increase_score(value + board.meld_tombstones(turn))

					turn += 1
					AudioManager.play(Audio.PLACE)
				'hammer':
					SaveManager.save_game(self, 'undo')
					var value = board.hammer_piece(turn)

					if value != null:
						AudioManager.play(Audio.REMOVE)
						decrease_score(value)
						current_piece.queue_free()
						set_next_piece()
						board.move_bears()
						board.trap_bears()
						increase_score(board.meld_tombstones(turn))

					turn += 1
				'store':
					var stored_piece_type = board.store_piece(current_piece.type)
					
					if stored_piece_type != 'error':
						current_piece.queue_free()
						AudioManager.play(Audio.STORE)

					if stored_piece_type == null:
						set_next_piece()
					else:
						set_next_piece(stored_piece_type)

			if OS.has_touchscreen_ui_hint():
				var closest_playable_position = board.get_closest_playable_position(current_piece.type)
				current_piece.position = board.get_position_from_board_position(closest_playable_position)
				if board.is_playable(current_piece.type, closest_playable_position):
					board.hover_piece(current_piece, closest_playable_position)

			SaveManager.save_game(self)

			if action_type != null:
				undo_button.visible = SaveManager.does_save_exist('undo')

			handle_game_over()


func increase_score(value):
	score += value
	score_label.text = String(score)


func decrease_score(value):
	score -= value
	score_label.text = String(score)


func set_next_piece(type = get_next_piece_type()):
	if type == null:
		type = get_next_piece_type()

	var piece = Piece.instance()
	piece.position = get_global_mouse_position()
	add_child(piece)
	piece.set_type(type)

	current_piece = piece



func get_next_piece_type():
	var roll = rng.randf()
	var chances = []
	var chance_acc = 0

	chances.append(['grass', 0.6])
	chances.append(['bush', 0.15])
	chances.append(['tree', 0.03])
	chances.append(['hut', 0.01])
	chances.append(['crystal', 0.03])
	chances.append(['hammer', 0.03])

	for chance in chances:
		chance_acc += chance[1]
		
		if roll < chance_acc:
			return chance[0]
	
	return 'bear'


func is_game_over():
	for x in board.columns:
		for y in board.rows:
			var piece = board.board[x][y]

			if piece == null:
				return false
			
			if piece.type == 'small_chest' or piece.type == 'large_chest':
				return false
	
	if current_piece != null and current_piece.type == 'hammer':
		return false

	if board.stored_piece == null or board.stored_piece.type == 'hammer':
		return false
	
	return true


func handle_game_over():
	if is_game_over():
		if game_over_label.visible == false:
			game_over_label.visible = true
			AudioManager.play(Audio.GAME_OVER)
	
		if score > highscore:
			highscore = score
			SettingsManager.save_setting(self, 'highscore', 'value', score)
	else:
		game_over_label.visible = false


func reset_game():
	AudioManager.play(Audio.UI_CLICK)

	if current_piece:
		current_piece.queue_free()
		current_piece = null
	
	if board.stored_piece:
		board.stored_piece.queue_free()
		board.stored_piece = null
	
	for x in board.columns:
		for y in board.rows:
			var piece = board.board[x][y]

			if piece:
				piece.queue_free()
			
			board.board[x][y] = null
	
	decrease_score(score)
	set_next_piece()
	board.setup_pieces()
	game_over_label.visible = false
	rng.seed = randi()
	rng.state = randi()
	board.rng.seed = randi()
	board.rng.state = randi()

	SaveManager.delete_save('undo')
	SaveManager.save_game(self)

	undo_button.visible = false
	highscore_label.text = String(highscore)


func undo():
	AudioManager.play(Audio.UI_CLICK)
	SaveManager.load_game(self, 'undo')
	SaveManager.save_game(self)
	SaveManager.delete_save('undo')
	score_label.text = String(score)
	undo_button.visible = false
	handle_game_over()


func on_mouse_entered_board_area():
	if current_piece != null:
		current_piece.visible = true


func on_mouse_exited_board_area():
	if current_piece != null:
		current_piece.visible = false


func cycle_board_theme():
	board.set_theme()
