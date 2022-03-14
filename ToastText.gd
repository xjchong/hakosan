extends Node2D

onready var label = $Label as Label
onready var tween = $Tween as Tween

var velocity = Vector2(0, -100)
var text = '???'

func _ready():
	z_index = 100
	label.text = text
	tween.interpolate_property(label, 'modulate:a', 0, 1, 0.5, Tween.TRANS_QUART, Tween.EASE_OUT)
	tween.interpolate_property(label, 'modulate:a', 1, 0, 0.1, Tween.TRANS_LINEAR, Tween.EASE_IN, 0.8)
	tween.connect('tween_all_completed', self, 'on_tween_complete')
	tween.start()


func _process(delta):
	self.position += velocity * delta
	velocity *= Vector2(0.8, 0.8)


func on_tween_complete():
	queue_free()



