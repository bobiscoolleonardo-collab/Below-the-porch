class_name inventory
extends Node

@export_category("Left Hand")
@export var left_item: TextureRect
var equip_left := false
var can_equip_left := true

@export_category("Right Hand")
@export var right_item: TextureRect
var equip_right := false
var can_equip_right := true

@export_category("Extras")
@export var left_animation: AnimationPlayer
@export var right_animation: AnimationPlayer
@export var socket: Node3D

@export var drop_distance := 1.5
@export var right_drop_hold_time := 0.45

var is_holding : bool = false

var left_scene: PackedScene
var right_scene: PackedScene
var left_pickup_scene: PackedScene
var right_pickup_scene: PackedScene
var left_spawned: Node3D
var right_spawned: Node3D

var drop_timer := 0.0

func _ready() -> void:
	global.inventory_ = self
	set_process(false)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("q"):
		toggle_left()
	elif event.is_action_pressed("e"):
		toggle_right()
	elif event.is_action_pressed("drop"):
		drop_timer = 0.0
		set_process(true)
	elif event.is_action_released("drop"):
		if !is_holding:
			set_process(false)
			drop_left_item()

func _process(delta: float) -> void:
	drop_timer += delta
	if drop_timer > (right_drop_hold_time * 0.2):
		is_holding = true
	else:
		is_holding = false
	if drop_timer >= right_drop_hold_time:
		set_process(false)
		drop_right_item()

func toggle_left() -> void:
	if left_scene == null or not can_equip_left:
		return
	can_equip_left = false
	equip_left = !equip_left
	if equip_left:
		left_spawned =  equip_item(left_scene, "left")
		left_animation.play("Equip Left")
	else:
		left_animation.play_backwards("Equip Left")
		await remove_spawned(left_spawned, 0.3)
		left_spawned = null
	await left_animation.animation_finished
	can_equip_left = true

func toggle_right() -> void:
	if right_scene == null or not can_equip_right:
		return
	can_equip_right = false
	equip_right = !equip_right
	if equip_right:
		right_spawned = equip_item(right_scene, "right")
		right_animation.play("Equip Right")
	else:
		right_animation.play_backwards("Equip Right")
		await remove_spawned(right_spawned, 0.3)
		right_spawned = null

	await right_animation.animation_finished
	can_equip_right = true

func equip_item(scene: PackedScene, side: String) -> Node3D:
	var spawned := scene.instantiate() as Node3D
	socket.add_child(spawned)
	spawned.transform = Transform3D.IDENTITY
	if spawned.has_method("equip_to"):
		spawned.call("equip_to", side)
		spawned.call("enter")

	return spawned

func remove_spawned(spawned: Node3D, delay: float = 0.0) -> void:
	if spawned == null:
		return
	if spawned.has_method("exit"):
		spawned.call("exit")
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout

	spawned.queue_free()

func add_item(icon: Texture2D, held_scene: PackedScene, pickup_scene: PackedScene) -> bool:
	if left_scene == null:
		left_scene = held_scene
		left_pickup_scene = pickup_scene
		left_item.texture = icon
		return true
	if right_scene == null:
		right_scene = held_scene
		right_pickup_scene = pickup_scene
		right_item.texture = icon
		return true
	return false

func drop_left_item() -> void:
	if left_pickup_scene == null:
		return
	if left_spawned:
		left_animation.play_backwards("Equip Left")
		await remove_spawned(left_spawned)
		left_spawned = null
	spawn_pickup(left_pickup_scene)
	left_scene = null
	left_pickup_scene = null
	left_item.texture = null
	equip_left = false

func drop_right_item() -> void:
	if right_pickup_scene == null:
		return
	if right_spawned:
		right_animation.play_backwards("Equip Right")
		await remove_spawned(right_spawned)
		right_spawned = null
	spawn_pickup(right_pickup_scene)
	right_scene = null
	right_pickup_scene = null
	right_item.texture = null
	equip_right = false

func spawn_pickup(pickup_scene: PackedScene) -> void:
	var pickup := pickup_scene.instantiate() as Node3D
	var spawn := pickup.find_child("Spawn") as Node3D
	get_tree().current_scene.add_child(pickup)
	pickup.global_position = get_drop_position() - Vector3(0, spawn.position.z, 0)
	pickup.rotation.y = randf_range(0.0, TAU)

func get_drop_position() -> Vector3:
	var start := get_tree().get_first_node_in_group("Start") as Node3D
	var end := get_tree().get_first_node_in_group("End") as Node3D
	if start == null or end == null:
		return global.player.global_position
	var ray_start := start.global_position
	var ray_end := end.global_position
	var query := PhysicsRayQueryParameters3D.create(ray_start, ray_end)

	query.exclude = [self, global.player]
	var space = get_tree().current_scene.get_world_3d().direct_space_state
	var result = space.intersect_ray(query)
	var hit_point: Vector3 = result.get("position", ray_end)

	DebugDraw3D.draw_line(ray_start, hit_point, Color.RED, 5.0)

	return hit_point + Vector3(randf_range(-0.2, 0.2), 0.0, randf_range(-0.2, 0.2))
