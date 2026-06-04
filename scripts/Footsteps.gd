extends Node3D

@export var raycast: RayCast3D
@export var dynamic_footsteps: AudioStreamPlayer3D

@export var step_interval := 0.15
@export var speed_threshold := 0.75
@export var pitch_min := 0.9
@export var pitch_max := 1.1

@export var sound_mapping: Dictionary = {
	"Concrete": preload("res://sounds/Footsteps/Concrete8.wav"),
	"Default": preload("res://sounds/Footsteps/Concrete8.wav"),
	"Wood": preload("res://sounds/Footsteps/WoodFootstep5.wav"),
	"Carpet": preload("res://sounds/Footsteps/CarpetFootstep1.wav")
}

var step_timer := 0.0

func _ready() -> void:
	step_timer = step_interval

func _process(delta: float) -> void:
	var current_interval := 0.5
	var volume := -25.0
	if global.player.is_sprinting:
		current_interval = 0.35
		volume = -24.0
	elif global.player.is_crouching:
		volume = -40.0

	step_interval = current_interval
	dynamic_footsteps.volume_db = volume
	var speed_limit := speed_threshold * speed_threshold
	var is_moving = global.player.velocity.length_squared() > speed_limit
	if global.player.is_on_floor() and is_moving:
		step_timer -= delta
		if step_timer <= 0.0:
			play_footstep()
			step_timer = current_interval
	else:
		step_timer = current_interval
	
	if global.player.velocity_y_last < -1.5:
		play_footstep()

func play_footstep() -> void:
	var material_name := "Default"
	if raycast.is_colliding():
		var collider := raycast.get_collider()
		if collider and collider.is_in_group("Concrete"):
			material_name = "Concrete"
		elif collider and  collider.is_in_group("Wood"):
			material_name = "Wood"
		elif collider and collider.is_in_group("Carpet"):
			material_name = "Carpet"

	dynamic_footsteps.stream = sound_mapping.get(material_name, sound_mapping["Default"])
	dynamic_footsteps.pitch_scale = randf_range(pitch_min, pitch_max)
	dynamic_footsteps.play()
