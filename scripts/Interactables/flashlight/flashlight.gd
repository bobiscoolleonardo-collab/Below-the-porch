extends Node3D

@onready var left_side: Node3D = $Left
@onready var right_side: Node3D = $Right
var light: SpotLight3D
@onready var animation: AnimationPlayer = $AnimationPlayer
@onready var sound: AudioStreamPlayer3D = $Sound

var on := preload("res://sounds/Flashlight/Flashlight On.wav")
var off := preload("res://sounds/Flashlight/Flashlight Off.wav")

@export var walk_bob_speed := 8.0
@export var walk_bob_amount := 0.035
@export var walk_side_amount := 0.02
@export var walk_rotation_amount := 0.035
@export var walk_smooth := 10.0
@export var walk_speed_for_full_bob := 5.0

@export var sway_amount := 5.0
@export var max_sway := 0.1
@export var sway_smooth := 12.0

var player: CharacterBody3D
var parent: Node3D

var equipped_side := ""
var use_lag := false
var light_on := false

var base_position := Vector3.ZERO
var base_rotation := Vector3.ZERO
var last_camera_rotation := Vector3.ZERO
var sway_rotation := Vector3.ZERO
var walk_position := Vector3.ZERO
var walk_rotation := Vector3.ZERO
var walk_time := 0.0


func _ready() -> void:
	player = global.player
	parent = get_parent() as Node3D

	base_position = position
	base_rotation = rotation

	if parent:
		last_camera_rotation = parent.global_rotation

	light = global.player.flashlight_light
	set_process(false)


func equip_to(side: String) -> void:
	equipped_side = side
	left_side.visible = side == "left"
	right_side.visible = side == "right"


func _process(delta: float) -> void:
	if parent == null or player == null:
		return

	_update_sway(delta)
	_update_walk_animation(delta)

	rotation = base_rotation + sway_rotation + walk_rotation
	position = base_position + walk_position


func _update_sway(delta: float) -> void:
	var camera_rotation := parent.global_rotation
	var rotation_delta := camera_rotation - last_camera_rotation

	rotation_delta.x = wrapf(rotation_delta.x, -PI, PI)
	rotation_delta.y = wrapf(rotation_delta.y, -PI, PI)

	last_camera_rotation = camera_rotation

	var target_sway := Vector3.ZERO

	if use_lag:
		target_sway.x = clamp(-rotation_delta.x * sway_amount, -max_sway, max_sway)
		target_sway.y = clamp(-rotation_delta.y * sway_amount, -max_sway, max_sway)
		target_sway.z = clamp(rotation_delta.y * sway_amount * 0.5, -max_sway, max_sway)

	sway_rotation = sway_rotation.lerp(target_sway, delta * sway_smooth)


func _update_walk_animation(delta: float) -> void:
	var speed := Vector2(player.velocity.x, player.velocity.z).length()
	var move_amount = clamp(speed / walk_speed_for_full_bob, 0.0, 1.0)

	var target_position := Vector3.ZERO
	var target_rotation := Vector3.ZERO

	if move_amount > 0.05 and player.is_on_floor():
		walk_time += delta * walk_bob_speed

		var side := sin(walk_time)
		var bob := sin(walk_time * 2.0)

		target_position.x = side * walk_side_amount * move_amount
		target_position.y = -abs(bob) * walk_bob_amount * move_amount

		target_rotation.x = bob * walk_rotation_amount * move_amount
		target_rotation.z = -side * walk_rotation_amount * move_amount

	var smooth = clamp(delta * walk_smooth, 0.0, 1.0)
	walk_position = walk_position.lerp(target_position, smooth)
	walk_rotation = walk_rotation.lerp(target_rotation, smooth)


func use_item() -> void:
	set_light(!light_on)
	_play_sound(on if light_on else off)


func set_light(value: bool) -> void:
	light_on = value
	global.player.request_flashlight_light(self, light_on)


func enter() -> bool:
	set_process(true)
	use_lag = true

	animation.play("equip")
	_play_sound(on)
	await animation.animation_finished

	set_light(true)
	return true


func exit() -> bool:
	set_light(false)
	use_lag = false

	_play_sound(off)
	animation.play_backwards("equip")
	await animation.animation_finished

	set_process(false)
	return false


func _play_sound(stream: AudioStream) -> void:
	sound.stream = stream
	sound.pitch_scale = randf_range(0.8, 1.2)
	sound.play()
