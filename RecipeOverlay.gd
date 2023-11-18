class_name RecipeOverlay
extends Node2D

const Piece = preload('res://Piece.tscn')

const recipe_for_type = {
	'grass': [3, 'bush'],
	'super_grass': [3, 'bush'],
	'bush': [3, 'tree'],
	'super_bush': [3, 'tree'],
	'tree': [3, 'hut'],
	'super_tree': [3, 'hut'],
	'hut': [3, 'house'],
	'super_hut': [3, 'house'],
	'house': [3, 'mansion'],
	'super_house': [3, 'mansion'],
	'mansion': [3, 'castle'],
	'super_mansion': [3, 'castle'],
	'castle': [3, 'floating_castle'],
	'super_castle': [3, 'floating_castle'],
	'floating_castle': [4, 'triple_castle'],
	'super_floating_castle': [4, 'triple_castle'],
	'tombstone': [3, 'church'],
	'church': [3, 'cathedral'],
	'super_church': [3, 'cathedral'],
	'cathedral': [3, 'small_chest'],
	'super_cathedral': [3, 'small_chest'],
	'small_chest': [3, 'large_chest'],
	'rock': [3, 'mountain'],
	'mountain': [3, 'large_chest'],
}

const PIECE_SCALE = Vector2(0.5, 0.5)


var pieces = []


func _ready():
	pass # Replace with function body.


func show_recipe(type):
	clear_recipe()

	var recipe = recipe_for_type.get(type, null)

	if recipe == null:
		return
	
	var offset = Vector2(32, 0)

	for i in recipe[0]:
		instance_piece(type, offset * i)

	instance_piece('arrow', offset * recipe[0])
	instance_piece(recipe[1], offset * (recipe[0] + 1))


func instance_piece(type, position):
	var piece = Piece.instantiate()
	add_child(piece)
	piece.scale = PIECE_SCALE
	piece.set_type(type)
	piece.position = position
	pieces.append(piece)

func clear_recipe():
	for piece in pieces:
		piece.queue_free()

	pieces = []

		


