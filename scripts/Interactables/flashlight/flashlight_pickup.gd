extends Interactable

@export var item_icon: Texture2D
@export var held_scene: PackedScene
@export var pickup_scene: PackedScene

func interact() -> void:
	var scene_to_drop := load(scene_file_path)
	global.player.play_sound(preload("res://sounds/Equip.wav"), -5.0)
	if global.inventory_.add_item(item_icon, held_scene, scene_to_drop):
		queue_free()
