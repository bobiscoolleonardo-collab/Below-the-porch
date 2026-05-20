extends CharacterBody3D

@export var hands : Node3D
@export var neck : Node3D
@export var camera : Camera3D
@export var camera_component : CameraComponent
@export var Postprocess1 : MeshInstance3D

@export var default_collision : CollisionShape3D
@export var crouch_collision : CollisionShape3D
@export var crouch_ray : RayCast3D
var lerp_speed = 10.0

var is_moving : bool
var movement_speed : float
var is_sprinting : bool
var is_crouching : bool

var crouch_height : float = 0.5
var stand_height : float = 1.0

var walk_speed := 3.0
var sprint_speed := 5.0
var crouch_speed := 1.5
var jump_velocity := 4.5

var pitch := 0.0
var sensitivity := 0.01
var mouse_delta := Vector2.ZERO
var target_roll := 0.0

var sway_smooth := 10.0
var sway_amount :=  200.0
var bob_time := 0.0
var idle_bob_speed := 3.0
var idle_bob_amount := 0.03
var base_height := 0
var velocity_y_last := 0.0
var landing_offset := 0.0

func _ready() -> void:
	global.player = self
	await owner.ready
	Postprocess1.visible = true

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED and not camera_component.active:
		if event is InputEventMouseMotion:
			mouse_delta += event.relative
			neck.rotate_y(-event.relative.x * sensitivity)
			hands.rotate_y(-event.relative.x * sensitivity)
			pitch -= event.relative.y * sensitivity
			pitch = clamp(pitch, deg_to_rad(-89), deg_to_rad(89))
			camera.rotation.x = pitch


func _physics_process(delta: float) -> void:
	is_moving = false
	is_sprinting = false
	
	if !is_crouching:
		is_sprinting = Input.is_action_pressed("sprint")
		movement_speed = sprint_speed if is_sprinting else walk_speed
	
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	if Input.is_action_pressed("crouch"):
		default_collision.disabled = true
		crouch_collision.disabled = false
		neck.position.y = lerp(neck.position.y, 0.244, delta * lerp_speed)
		movement_speed = crouch_speed
		is_crouching = true
	elif !crouch_ray.is_colliding():
		is_crouching = false
		neck.position.y = lerp(neck.position.y, 0.791, delta * lerp_speed)
		default_collision.disabled = false
		crouch_collision.disabled  = true
	
	if Input.is_action_just_pressed("space") and is_on_floor():
		velocity.y = jump_velocity
	
	if camera_component.active:
		pitch = camera_component.update(delta, pitch, sway_smooth)
		mouse_delta = Vector2.ZERO
	else:
		camera.rotation.z = lerp(camera.rotation.z, clamp(-mouse_delta.x * delta * sway_amount * 0.001, -0.9, 0.9), delta * sway_smooth)
		mouse_delta = Vector2.ZERO
		camera.rotation.z = lerp(camera.rotation.z, target_roll, delta * sway_smooth)
		
	var input_dir := Input.get_vector("a", "d", "w", "s")
	var target_velocity = Vector3.ZERO
	var direction := neck.global_transform.basis * Vector3(input_dir.x, 0, input_dir.y)
	direction.y = 0
	direction = direction.normalized()
	if direction:
		is_moving = true
		target_velocity.x = direction.x * movement_speed
		target_velocity.z = direction.z * movement_speed
	velocity.x = lerp(velocity.x, target_velocity.x, 10 * delta)
	velocity.z = lerp(velocity.z, target_velocity.z, 10 * delta)
	target_roll = lerp(target_roll, 0.0, delta * 5.0)
	move_and_slide()
	camera_bob(delta)

func camera_bob(delta: float) -> void:
	var on_floor_moving = is_on_floor() and is_moving
	bob_time += delta * ((17.0 if is_sprinting else 12.0) if on_floor_moving else idle_bob_speed)
	if is_on_floor() and velocity_y_last < -3.5:
		landing_offset = 0.3
	velocity_y_last = velocity.y
	landing_offset = lerp(landing_offset, 0.0, delta * 8.0)
	var bob := sin(bob_time) * ((0.04 if is_sprinting else 0.03) if on_floor_moving else idle_bob_amount)
	camera.position.y = lerp(camera.position.y, base_height + bob - landing_offset, delta * 10.0)
