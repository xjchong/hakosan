extends Node2D

@onready var label = $Label as Label

var velocity = Vector2(0, -100)
var text = '???'

func _ready():
	z_index = 100
	label.text = text

	(create_tween().tween_property(label, 'modulate:a', 1, 0.5)
		.set_trans(Tween.TRANS_QUART)
		.set_ease(Tween.EASE_OUT))
	await (create_tween().tween_property(label, 'modulate:a', 0, 0.1)
		.set_trans(Tween.TRANS_LINEAR)
		.set_ease(Tween.EASE_IN)
		.set_delay(0.8)
		.finished)
	queue_free()


func _process(delta):
	self.position += velocity * delta
	velocity *= Vector2(0.8, 0.8)


func on_tween_complete():
	queue_free()



