class_name Game
extends Node2D

onready var board = $Board as Board
onready var score_label = $ScoreLabel as Label
onready var game_over_label = $GameOverLabel as Label
onready var board_area = $BoardArea as PanelContainer
onready var new_game_button = $NewGameButton as Button

const Piece = preload('res://Piece.tscn')
const ToastText = preload('res://ToastText.tscn')

var current_piece = null
var score = 0

func _ready():
	if not SaveManager.load_game(self):
		board.setup_pieces()
		set_next_piece()

	score_label.text = String(score)

	new_game_button.connect('pressed', self, 'reset_game')
	board_area.connect('mouse_entered', self, 'on_mouse_entered_board_area')
	board_area.connect('mouse_exited', self, 'on_mouse_exited_board_area')

	handle_game_over()


func _input(event):
	if event is InputEventMouseMotion:
		if current_piece != null and is_instance_valid(current_piece):
			if board.is_playable(current_piece):
				board.hover_piece(current_piece)
			else:
				board.reset_hover()
				current_piece.unhighlight()
				current_piece.position = get_global_mouse_position()
	elif event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and not event.pressed:
			var action_type = board.get_action_type(current_piece)

			match action_type:
				'loot':
					board.loot_piece()
					AudioManager.play(Audio.LOOT)
				'place':
					var value = board.place_piece(current_piece.type)

					if value != null:
						current_piece.queue_free()
						set_next_piece()
						board.move_bears()
						board.trap_bears()
						increase_score(value + board.meld_tombstoneyards())

					AudioManager.play(Audio.PLACE)
				'hammer':
					var value = board.hammer_piece()

					if value != null:
						AudioManager.play(Audio.REMOVE)
						decrease_score(value)
						current_piece.queue_free()
						set_next_piece()
						board.move_bears()
						board.trap_bears()
						increase_score(board.meld_tombstoneyards())
				'store':
					var stored_piece_type = board.store_piece(current_piece.type)
					
					if stored_piece_type != 'error':
						current_piece.queue_free()
						AudioManager.play(Audio.STORE)

					if stored_piece_type == null:
						set_next_piece()
					else:
						set_next_piece(stored_piece_type)

			SaveManager.save_game(self)

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
	var roll = randf()
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

	SaveManager.save_game(self)


func on_mouse_entered_board_area():
	if current_piece != null:
		current_piece.visible = true


func on_mouse_exited_board_area():
	if current_piece != null:
		current_piece.visible = false
