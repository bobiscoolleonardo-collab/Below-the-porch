class_name inventory extends Node

@export_category("Left Hand")
@export var left_hand : Control
@export var left_item : TextureRect
var equip_left : bool = false
var can_equip_left : bool = true

@export_category("Right Hand")
@export var right_hand : Control
@export var right_item : TextureRect
var equip_right : bool = false
var can_equip_right : bool = true

@export_category("Extras")
@export var left_animation : AnimationPlayer
@export var right_animation : AnimationPlayer

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("q"):
		if not can_equip_left:
			return
		can_equip_left = false
		equip_left = !equip_left
		if equip_left:
			left_animation.play("Equip Left")
		else:
			left_animation.play_backwards("Equip Left")
		await left_animation.animation_finished
		can_equip_left = true

	if event.is_action_pressed("e"):
		if not can_equip_right:
			return
		can_equip_right = false
		equip_right = !equip_right
		if equip_right:
			right_animation.play("Equip Right")
		else:
			right_animation.play_backwards("Equip Right")
		await right_animation.animation_finished
		can_equip_right = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
