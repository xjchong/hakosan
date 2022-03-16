extends Control


onready var label = $Label as Label
onready var slider = $VSlider as VSlider
onready var tween = $Tween as Tween

var is_value_set_initially = false

func _ready():
	var volume_percent = SettingsManager.load_setting('sound_effects', 'volume_percent', AudioManager.DEFAULT_SOUND_VOLUME_PERCENT)

	slider.value = slider.max_value * volume_percent


func _on_VSlider_value_changed(value):
	var volume_percent = value / float(slider.max_value)

	SettingsManager.save_setting(self, 'sound_effects', 'volume_percent', volume_percent)
	AudioManager.update_volume(AudioManager.Bus.SOUND_EFFECTS, volume_percent)

	if is_value_set_initially:
		AudioManager.play(Audio.UI_CLICK)
	else:
		is_value_set_initially = true


func _on_MouseArea_mouse_entered():
	tween.remove_all()
	tween.interpolate_property(slider, 'modulate:a', slider.modulate.a, 1, 0.1)
	tween.start()


func _on_MouseArea_mouse_exited():
	tween.remove_all()
	tween.interpolate_property(slider, 'modulate:a', 1, 0, 0.3, 0, 2, 0.5)
	tween.start()
