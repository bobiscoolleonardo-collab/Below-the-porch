class_name inventory extends Node

@export_category("Left Hand")
@export var left_item : TextureRect
var equip_left : bool = false
var can_equip_left : bool = true

@export_category("Right Hand")
@export var right_item : TextureRect
var equip_right : bool = false
var can_equip_right : bool = true

@export_category("Extras")
@export var left_animation : AnimationPlayer
@export var right_animation : AnimationPlayer
@export var socket : Node3D

var left_scene: PackedScene
var right_scene: PackedScene

var left_pickup_scene: PackedScene
var right_pickup_scene: PackedScene

var left_spawned: Node3D
var right_spawned: Node3D

@export var drop_distance := 1.5
@export var right_drop_hold_time := 0.45

var drop_holding := false
var drop_timer := 0.0

func _ready() -> void:
	global.inventory_ = self

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("q"):
		toggle_left()

	if event.is_action_pressed("e"):
		toggle_right()

	if event.is_action_pressed("drop") and not drop_holding:
		drop_holding = true
		drop_timer = 0.0

	if event.is_action_released("drop") and drop_holding:
		drop_holding = false
		drop_left_item()

func _process(delta: float) -> void:
	if drop_holding:
		drop_timer += delta

		if drop_timer >= right_drop_hold_time:
			drop_holding = false
			drop_right_item()

func toggle_left() -> void:
	if left_scene == null or not can_equip_left:
		return

	can_equip_left = false
	equip_left = !equip_left

	if equip_left:
		left_spawned = left_scene.instantiate()
		socket.add_child(left_spawned)
		left_spawned.transform = Transform3D.IDENTITY

		if left_spawned.has_method("equip_to"):
			left_spawned.call("equip_to", "left")
			left_spawned.call("enter")
		left_animation.play("Equip Left")
	else:
		left_animation.play_backwards("Equip Left")

		if left_spawned:
			left_spawned.call("exit")
			await get_tree().create_timer(0.3).timeout
			left_spawned.queue_free()
			left_spawned = null

	await left_animation.animation_finished
	can_equip_left = true


func toggle_right() -> void:
	if right_scene == null or not can_equip_right:
		return

	can_equip_right = false
	equip_right = !equip_right

	if equip_right:
		right_spawned = right_scene.instantiate()
		socket.add_child(right_spawned)
		right_spawned.transform = Transform3D.IDENTITY

		if right_spawned.has_method("equip_to"):
				right_spawned.call("equip_to", "right")
				right_spawned.call("enter")
		right_animation.play("Equip Right")
	else:
		right_animation.play_backwards("Equip Right")

		if right_spawned:
			right_spawned.call("exit")
			await get_tree().create_timer(0.3).timeout
			right_spawned.queue_free()
			right_spawned = null

	await right_animation.animation_finished
	can_equip_right = true

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
	spawn_pickup(left_pickup_scene)
	if left_spawned:
		left_spawned.call("exit")
		left_animation.play_backwards("Equip Left")
		left_spawned.queue_free()
		left_spawned = null
	left_scene = null
	left_pickup_scene = null
	left_item.texture = null
	equip_left = false

func spawn_pickup(pickup_scene: PackedScene) -> void:
	var pickup := pickup_scene.instantiate() as Node3D
	var spawn := pickup.find_child("Spawn")
	get_tree().current_scene.add_child(pickup)

	pickup.global_position = get_drop_position() - Vector3(0, spawn.position.z, 0)


func get_drop_position() -> Vector3:
	var start = get_tree().get_first_node_in_group("Start")
	var end = get_tree().get_first_node_in_group("End")
	var ray_start = start.global_position
	var ray_end = end.global_position

	
	var space = get_tree().current_scene.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(ray_start, ray_end)
	query.exclude = [self, global.player]
	var result = space.intersect_ray(query)

	var hit_point = result.get("position", ray_end)
	DebugDraw3D.draw_line(ray_start, hit_point, Color.RED, 5.0)
	return hit_point

func drop_right_item() -> void:
	if right_pickup_scene == null:
		return

	spawn_pickup(right_pickup_scene)

	if right_spawned:
		right_animation.play_backwards("Equip Right")
		right_spawned.queue_free()
		right_spawned = null

	right_scene = null
	right_pickup_scene = null
	right_item.texture = null
	equip_right = false
