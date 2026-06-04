extends Interactable

@export var light_1: SpotLight3D
@export var light_2: SpotLight3D
@export var sound: AudioStreamPlayer3D

var on: bool = true
var can_interact: bool = true

func interact() -> void:
	if not can_interact:
		return

	if on:
		turn_off()
	else:
		turn_on()

func turn_on() -> void:
	can_interact = false
	light_1.visible = true
	light_2.visible = true
	sound.pitch_scale = randf_range(0.95, 1.05)
	sound.play()
	on = true
	await sound.finished
	can_interact = true

func turn_off() -> void:
	can_interact = false
	light_1.visible = false
	light_2.visible = false
	sound.pitch_scale = randf_range(0.95, 1.05)
	sound.play()
	on = false
	await sound.finished
	can_interact = true
