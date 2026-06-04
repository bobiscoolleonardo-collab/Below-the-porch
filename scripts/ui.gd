extends Node

@export var interact_icon : TextureRect

@export var menu : Panel
@export var exit_button : Button

func _ready() -> void:
	global.ui = self
	exit_button.button_down.connect(on_exit_button_press)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("exit"):
		if menu.visible:
			menu.visible = !menu.visible
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			get_tree().paused = false
		else:
			menu.visible = !menu.visible
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			get_tree().paused = true
		

func set_interact_visible(v : bool):
	interact_icon.visible = v

func on_exit_button_press():
	get_tree().quit()
