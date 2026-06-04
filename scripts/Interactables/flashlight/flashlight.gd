extends Node3D

const SOUND_ON: AudioStream = preload("res://sounds/Flashlight/Flashlight On.wav")
const SOUND_OFF: AudioStream = preload("res://sounds/Flashlight/Flashlight Off.wav")

@onready var left_side: Node3D = $Left
@onready var right_side: Node3D = $Right
@onready var animation: AnimationPlayer = $AnimationPlayer
@onready var sound: AudioStreamPlayer3D = $Sound

@export var walk_bob_speed := 8.0
@export var walk_bob_amount := 0.035
@export var walk_side_amount := 0.02
@export var walk_rotation_amount := 0.035
@export var walk_smooth := 10.0
@export var walk_speed_for_full_bob := 5.0

@export var sway_amount := 5.0
@export var max_sway := 0.1
@export var sway_smooth := 12.0

var light: SpotLight3D
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
	if parent == null or global.player == null:
		return

	_update_sway(delta)
	_update_walk_animation(delta)

	rotation.x = base_rotation.x + sway_rotation.x + walk_rotation.x
	rotation.y = base_rotation.y + sway_rotation.y + walk_rotation.y
	rotation.z = base_rotation.z + sway_rotation.z + walk_rotation.z

	position.x = base_position.x + walk_position.x
	position.y = base_position.y + walk_position.y
	position.z = base_position.z + walk_position.z


func _update_sway(delta: float) -> void:
	var camera_rotation := parent.global_rotation
	var rotation_delta := camera_rotation - last_camera_rotation
	last_camera_rotation = camera_rotation

	var target_x := 0.0
	var target_y := 0.0
	var target_z := 0.0

	if use_lag:
		rotation_delta.x = wrapf(rotation_delta.x, -PI, PI)
		rotation_delta.y = wrapf(rotation_delta.y, -PI, PI)

		target_x = clampf(-rotation_delta.x * sway_amount, -max_sway, max_sway)
		target_y = clampf(-rotation_delta.y * sway_amount, -max_sway, max_sway)
		target_z = clampf(rotation_delta.y * sway_amount * 0.5, -max_sway, max_sway)

	var smooth := clampf(delta * sway_smooth, 0.0, 1.0)

	sway_rotation.x = lerpf(sway_rotation.x, target_x, smooth)
	sway_rotation.y = lerpf(sway_rotation.y, target_y, smooth)
	sway_rotation.z = lerpf(sway_rotation.z, target_z, smooth)


func _update_walk_animation(delta: float) -> void:
	var velocity = global.player.velocity
	var speed_sq = velocity.x * velocity.x + velocity.z * velocity.z
	var full_bob_speed := maxf(walk_speed_for_full_bob, 0.001)
	var move_amount := clampf(sqrt(speed_sq) / full_bob_speed, 0.0, 1.0)

	var target_pos_x := 0.0
	var target_pos_y := 0.0
	var target_rot_x := 0.0
	var target_rot_z := 0.0

	if move_amount > 0.05 and global.player.is_on_floor():
		walk_time += delta * walk_bob_speed

		var side := sin(walk_time)
		var bob := sin(walk_time * 2.0)

		target_pos_x = side * walk_side_amount * move_amount
		target_pos_y = -absf(bob) * walk_bob_amount * move_amount
		target_rot_x = bob * walk_rotation_amount * move_amount
		target_rot_z = -side * walk_rotation_amount * move_amount

	var smooth := clampf(delta * walk_smooth, 0.0, 1.0)

	walk_position.x = lerpf(walk_position.x, target_pos_x, smooth)
	walk_position.y = lerpf(walk_position.y, target_pos_y, smooth)
	walk_position.z = lerpf(walk_position.z, 0.0, smooth)

	walk_rotation.x = lerpf(walk_rotation.x, target_rot_x, smooth)
	walk_rotation.y = lerpf(walk_rotation.y, 0.0, smooth)
	walk_rotation.z = lerpf(walk_rotation.z, target_rot_z, smooth)


func use_item() -> void:
	set_light(!light_on)
	_play_sound(SOUND_ON if light_on else SOUND_OFF)


func set_light(value: bool) -> void:
	if light_on == value:
		return

	light_on = value
	global.player.request_flashlight_light(self, light_on)


func enter() -> bool:
	set_process(true)
	use_lag = true

	if parent:
		last_camera_rotation = parent.global_rotation

	animation.play("equip")
	_play_sound(SOUND_ON)
	await animation.animation_finished

	set_light(true)
	return true


func exit() -> bool:
	set_light(false)
	use_lag = false

	_play_sound(SOUND_OFF)
	animation.play_backwards("equip")
	await animation.animation_finished

	set_process(false)
	return false


func _play_sound(stream: AudioStream) -> void:
	sound.stream = stream
	sound.pitch_scale = randf_range(0.8, 1.2)
	sound.play()
