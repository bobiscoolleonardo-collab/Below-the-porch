extends CharacterBody3D

@export var sound: AudioStreamPlayer3D
@export var hands: Node3D
@export var neck: Node3D
@export var camera: Camera3D
@export var drop_item: SpringArm3D
@export var camera_component: CameraComponent
@export var post_processing1 : ColorRect
@export var flashlight_light: SpotLight3D
@export var start: Marker3D
@export var end: Marker3D
@export var ray_cast: RayCast3D
@export var default_collision: CollisionShape3D
@export var crouch_collision: CollisionShape3D
@export var crouch_ray: RayCast3D

var flashlight_users: Array[Node] = []
var current_interactable: Interactable

var is_moving := false
var is_sprinting := false
var is_crouching := false
var movement_speed := 0.0

var lerp_speed := 10.0
var crouch_height := 0.5
var stand_height := 1.0

var walk_speed := 3.0
var sprint_speed := 5.0
var crouch_speed := 1.5
var jump_velocity := 3.0

var pitch := 0.0
var sensitivity := 0.01
var mouse_delta := Vector2.ZERO
var target_roll := 0.0

var sway_smooth := 10.0
var sway_amount := 200.0
var bob_time := 0.0
var idle_bob_speed := 3.0
var idle_bob_amount := 0.03
var base_height := 0.0
var velocity_y_last := 0.0
var landing_offset := 0.0


func _ready() -> void:
	global.player = self
	await owner.ready
	post_processing1.show()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func play_sound(audio: AudioStream = null, volume := 0.0) -> void:
	sound.stream = audio
	sound.volume_db = volume
	sound.pitch_scale = randf_range(0.8, 1.2)
	sound.play()
	await sound.finished
	sound.stream = null

func _unhandled_input(event: InputEvent) -> void:
	if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED or camera_component.active:
		return
	if event is InputEventMouseMotion:
		mouse_delta += event.relative
		var yaw = -event.relative.x * sensitivity
		neck.rotate_y(yaw)
		drop_item.rotate_y(yaw)
		pitch = clampf(pitch - event.relative.y * sensitivity, deg_to_rad(-89.0), deg_to_rad(89.0))
		camera.rotation.x = pitch


func _physics_process(delta: float) -> void:
	var on_floor := is_on_floor()

	is_moving = false
	is_sprinting = false

	_update_crouch(delta)
	

	if not is_crouching:
		is_sprinting = Input.is_action_pressed("sprint")
		movement_speed = sprint_speed if is_sprinting else walk_speed

	if Input.is_action_just_pressed("interact"):
		_try_interact()

	if not on_floor:
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("space") and on_floor and not is_crouching:
		velocity.y = jump_velocity

	_update_camera(delta)
	_update_movement(delta)

	move_and_slide()
	camera_bob(delta)
	_check_interactable()

func _update_crouch(delta: float) -> void:
	var wants_crouch := Input.is_action_pressed("crouch")
	var should_crouch := wants_crouch or (is_crouching and crouch_ray.is_colliding())
	if should_crouch:
		movement_speed = crouch_speed
		neck.position.y = lerpf(neck.position.y, 0.244, delta * lerp_speed)
	else:
		neck.position.y = lerpf(neck.position.y, 0.791, delta * lerp_speed)
	if is_crouching == should_crouch:
		return
	is_crouching = should_crouch
	default_collision.disabled = is_crouching
	crouch_collision.disabled = not is_crouching

func _update_camera(delta: float) -> void:
	var smooth := delta * sway_smooth
	if camera_component.active:
		pitch = camera_component.update(delta, pitch, sway_smooth)
	else:
		var roll := clampf(-mouse_delta.x * delta * sway_amount * 0.001, -0.9, 0.9)
		camera.rotation.z = lerpf(camera.rotation.z, roll, smooth)
		camera.rotation.z = lerpf(camera.rotation.z, target_roll, smooth)

	mouse_delta = Vector2.ZERO
	target_roll = lerpf(target_roll, 0.0, delta * 5.0)

func _update_movement(delta: float) -> void:
	var input_dir := Input.get_vector("a", "d", "w", "s")
	var target_x := 0.0
	var target_z := 0.0
	if input_dir != Vector2.ZERO:
		var direction := neck.global_basis * Vector3(input_dir.x, 0.0, input_dir.y)
		direction.y = 0.0
		direction = direction.normalized()
		is_moving = true
		target_x = direction.x * movement_speed
		target_z = direction.z * movement_speed

	var smooth := 10.0 * delta
	velocity.x = lerpf(velocity.x, target_x, smooth)
	velocity.z = lerpf(velocity.z, target_z, smooth)

func _find_interactable(node: Node) -> Interactable:
	while is_instance_valid(node):
		if node is Interactable and not node.is_queued_for_deletion():
			return node

		node = node.get_parent()
	return null

func _check_interactable() -> void:
	if ray_cast.is_colliding():
		var interactable := _find_interactable(ray_cast.get_collider())
		if interactable:
			if interactable != current_interactable:
				current_interactable = interactable
				global.ui.set_interact_visible(true)
			return

	if current_interactable:
		_clear_interactable()

func _try_interact() -> void:
	if not is_instance_valid(current_interactable):
		_clear_interactable()
		return

	var interacted := current_interactable
	interacted.interact()

	if not is_instance_valid(interacted) or interacted.is_queued_for_deletion():
		_clear_interactable()

func _clear_interactable() -> void:
	current_interactable = null
	global.ui.set_interact_visible(false)

func request_flashlight_light(item: Node, enabled: bool) -> void:
	if enabled:
		if not flashlight_users.has(item):
			flashlight_users.append(item)
	else:
		flashlight_users.erase(item)

	var should_show := flashlight_users.size() > 0
	if flashlight_light.visible != should_show:
		flashlight_light.visible = should_show


func camera_bob(delta: float) -> void:
	var on_floor_moving := is_on_floor() and is_moving

	bob_time += delta * ((17.0 if is_sprinting else 12.0) if on_floor_moving else idle_bob_speed)

	if is_on_floor() and velocity_y_last < -1.5:
		landing_offset = 0.3

	velocity_y_last = velocity.y
	landing_offset = lerpf(landing_offset, 0.0, delta * 8.0)

	var amount := (0.04 if is_sprinting else 0.03) if on_floor_moving else idle_bob_amount
	var bob := sin(bob_time) * amount

	camera.position.y = lerpf(camera.position.y, base_height + bob - landing_offset, delta * 10.0)
