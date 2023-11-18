extends Control


@onready var label = $Label as Label
@onready var slider = $Slider as HSlider

var is_value_set_initially = false

func _ready():
	var volume_percent = SettingsManager.load_setting('sound_effects', 'volume_percent', AudioManager.DEFAULT_SOUND_VOLUME_PERCENT)

	slider.value = slider.max_value * volume_percent


func _on_Slider_value_changed(value):
	var volume_percent = value / float(slider.max_value)

	SettingsManager.save_setting(self, 'sound_effects', 'volume_percent', volume_percent)
	AudioManager.update_volume(AudioManager.Bus.SOUND_EFFECTS, volume_percent)

	if is_value_set_initially:
		AudioManager.play(Audio.UI_CLICK)
	else:
		is_value_set_initially = true


func _on_MouseArea_mouse_entered():
	create_tween().tween_property(slider, 'modulate:a', 1, 0.1)


func _on_MouseArea_mouse_exited():
	create_tween().tween_property(slider, 'modulate:a', 0, 0.2).set_delay(0.5)
	
