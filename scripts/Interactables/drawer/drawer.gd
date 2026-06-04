extends Interactable

@export var drawer_base: Node
@export var drawer_index: int = 0

@export var open_distance: float = -1.3
@export var open_speed: float = 0.5
@export var sound: AudioStreamPlayer3D

var is_open := false
var spawned : bool = false
var closed_z: float
var tween: Tween

func _ready() -> void:
	closed_z = self.position.z

func interact() -> void:
	if tween and tween.is_running():
		return

	if not is_open:
		if drawer_base and not spawned and drawer_base.has_method("spawn_item_in_drawer"):
			spawned = true
			drawer_base.spawn_item_in_drawer(drawer_index)

	var target_z := closed_z + open_distance if not is_open else closed_z

	if sound:
		sound.pitch_scale = randf_range(0.9, 1.1)
		sound.play()

	tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "position:z", target_z, open_speed)

	is_open = not is_open
