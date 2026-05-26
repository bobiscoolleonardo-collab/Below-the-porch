extends Node3D

@export var raycast : RayCast3D
@export var dynamic_footsteps : AudioStreamPlayer3D

@export var step_interval : float = 0.15
@export var speed_threshold : float = 0.75

@export var sound_mapping : Dictionary = {
	"Concrete": preload("res://sounds/ConcreteFootstep6.wav"),
	"Default": preload("res://sounds/ConcreteFootstep6.wav")
}

@export var pitch_min : float = 0.9
@export var pitch_max : float = 1.1

var step_timer : float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	step_timer = step_interval


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not global.player.is_sprinting:
		step_interval = 0.5
		dynamic_footsteps.volume_db = -35
	if global.player.is_crouching:
		dynamic_footsteps.volume_db = -50
		step_interval = 0.5
	if global.player.is_sprinting:
		step_interval = 0.35
		dynamic_footsteps.volume_db = -32
	
	if global.player.is_on_floor() and global.player.velocity.length() > speed_threshold:
		step_timer -= delta
		if step_timer <= 0:
			play_footstep()
			step_timer = step_interval
	else:
		step_timer = step_interval

func play_footstep() -> void:
	if raycast.is_colliding():
		var collider = raycast.get_collider()
		var material_name = "Default"
		
		if collider:
			if collider.is_in_group("Concrete"):
				material_name = "Concrete"
			elif collider.is_in_group("Default"):
				material_name = "Default"
		
		if sound_mapping.has(material_name):
			dynamic_footsteps.stream = sound_mapping[material_name]
		else:
			dynamic_footsteps.stream = sound_mapping["Default"]
	
	dynamic_footsteps.pitch_scale = randf_range(pitch_min, pitch_max)
	dynamic_footsteps.play()
