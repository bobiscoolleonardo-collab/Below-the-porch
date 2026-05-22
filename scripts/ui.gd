extends Node

@export var interact_icon : TextureRect

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	global.ui = self


func set_interact_visible(v : bool):
	interact_icon.visible = v
