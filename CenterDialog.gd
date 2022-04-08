class_name CenterDialog
extends CanvasLayer


onready var backgroundColorRect = $BackgroundColorRect as ColorRect
onready var acceptDialog = $CenterContainer/AcceptDialog as AcceptDialog


func show_accept(message):
	backgroundColorRect.visible = true
	acceptDialog.dialog_text = message
	acceptDialog.get_close_button().visible = false
	acceptDialog.show()
	acceptDialog.connect('confirmed', self, '_on_confirmed')
	_recenter()

	# warning-ignore:return_value_discarded
	get_tree().connect('screen_resized', self, '_recenter')
	get_tree().paused = true


func _recenter():
	acceptDialog.rect_position = (get_viewport().size / 2) - (acceptDialog.rect_size / 2)


func _on_confirmed():
	get_tree().paused = false
	queue_free()
