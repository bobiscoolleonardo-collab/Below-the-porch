# DoorController.gd
extends Node3D

@export var pivot: Node3D
@export var sound: AudioStreamPlayer3D
@export var handle : MeshInstance3D

@export var door_locked: bool = false
@export var automtically_close : bool = false
var close_timer : float = 5.0
var open_forward: float = 110.0
var closed_angle: float = 0.0

var opened: bool = false
var closed: bool = true
var moving: bool = false

var open_sound = preload("res://sounds/door/DoorOpen3.wav")
var close_sound = preload("res://sounds/door/DoorClose2.wav")
var locked_sound = preload("res://sounds/door/DoorLocked2.wav")

func interact() -> void:
	if door_locked:
		play_sound(locked_sound)
		return

	if moving:
		return

	if closed:
		open_door_forward()
	elif opened:
		close_door()
	
 
func _process(delta: float) -> void:
	if opened and automtically_close:
		close_timer -= delta
		print(close_timer)
		if close_timer <= 0.0:
			close_door()
			close_timer = 5.0

func get_tween(target_degrees: float) -> void:
	moving = true

	var tween = create_tween()
	tween.tween_property(
		pivot,
		"rotation_degrees:y",
		target_degrees,
		0.7
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	if closed:
		var tween2 = create_tween()
		tween2.tween_property(
			handle,
			"rotation_degrees:x",
			160,
			0.2
		).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_IN_OUT)
		tween2.tween_property(
			handle,
			"rotation_degrees:x",
			90,
			0.2
		).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_IN_OUT)

	await tween.finished
	moving = false

func open_door_forward() -> void:
	play_sound(open_sound)
	await get_tween(open_forward)
	opened = true
	closed = false
	close_timer = 5.0

func close_door() -> void:
	play_sound(close_sound)
	await get_tween(closed_angle)
	opened = false
	closed = true

func play_sound(sound_to_play: AudioStream) -> void:
	sound.stream = sound_to_play
	sound.pitch_scale = randf_range(0.8, 1.2)
	sound.play()
