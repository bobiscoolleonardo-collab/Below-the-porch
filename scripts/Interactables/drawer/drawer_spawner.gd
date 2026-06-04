extends Node3D

@export var drawer_spawns: Array[Marker3D]
@export var drawer_items: Array[PackedScene]

var spawned_items: Array[Node3D] = []

func _ready() -> void:
	spawned_items.resize(drawer_spawns.size())

func spawn_item_in_drawer(drawer_index: int) -> void:
	if drawer_index < 0 or drawer_index >= drawer_spawns.size():
		return

	if spawned_items[drawer_index]:
		return

	if drawer_index >= drawer_items.size():
		return

	var item_scene := drawer_items[drawer_index]
	if item_scene == null:
		return

	var spawn := drawer_spawns[drawer_index]
	var item := item_scene.instantiate()

	spawn.add_child(item)
	item.position = Vector3(0, -0.1, 0)
	item.scale = Vector3(2, 2, 2)
	item.rotation.y = randf_range(0.0, TAU)

	spawned_items[drawer_index] = item
