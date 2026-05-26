# HeldItem.gd
extends Node3D

@onready var left_side: Node3D = $Left
@onready var right_side: Node3D = $Right
@onready var light: SpotLight3D = $SpotLight3D
@onready var animation : AnimationPlayer = $AnimationPlayer
@onready var sound : AudioStreamPlayer3D = $Sound

var base_position := Vector3.ZERO
var walk_time := 0.0
var walk_position := Vector3.ZERO
var walk_rotation := Vector3.ZERO

@export var walk_bob_speed := 8.0
@export var walk_bob_amount := 0.035
@export var walk_side_amount := 0.02
@export var walk_rotation_amount := 0.035
@export var walk_smooth := 10.0
@export var walk_speed_for_full_bob := 5.0

var on := preload("res://sounds/Flashlight/Flashlight On.wav")
var off := preload("res://sounds/Flashlight/Flashlight Off.wav")


var parent: Node3D

var base_rotation := Vector3.ZERO
var last_camera_rotation := Vector3.ZERO
var sway_rotation := Vector3.ZERO

@export var sway_amount := 5.0
@export var max_sway := 0.1
@export var sway_smooth := 12.0

var sway_speed := 50.0
var use_lag := false

var equipped_side: String = ""

func equip_to(side: String) -> void:
	equipped_side = side

	left_side.visible = side == "left"
	right_side.visible = side == "right"

func _ready() -> void:
	parent = get_parent() as Node3D
	base_rotation = rotation
	base_position = position

	if parent:
		last_camera_rotation = parent.global_rotation


func _process(delta: float) -> void:
	if parent == null:
		return

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

	_update_walk_animation(delta)

	rotation = base_rotation + sway_rotation + walk_rotation
	position = base_position + walk_position


func use_item() -> void:
	light.visible = !light.visible

func enter() -> bool:
	animation.play("equip")
	sound.stream = on
	sound.pitch_scale = randf_range(0.8, 1.2)
	sound.play()
	use_lag = true
	await animation.animation_finished
	use_item()
	return true

func exit() -> bool:
	use_item()
	sound.stream = off
	sound.pitch_scale = randf_range(0.8, 1.2)
	sound.play()
	use_lag = false
	animation.play_backwards("equip")
	return false

func _update_walk_animation(delta: float) -> void:
	var velocity: Vector3 = global.player.get_velocity() # CHANGE THIS NAME if yours is different
	var speed := Vector2(velocity.x, velocity.z).length()
	var move_amount = clamp(speed / walk_speed_for_full_bob, 0.0, 1.0)

	var target_position := Vector3.ZERO
	var target_rotation := Vector3.ZERO

	if move_amount > 0.05:
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


func _get_global_player_speed() -> float:
	var velocity = global.player.movement_speed

	if velocity is Vector3:
		return Vector2(velocity.x, velocity.z).length()

	if velocity is Vector2:
		return velocity.length()

	return 0.0
