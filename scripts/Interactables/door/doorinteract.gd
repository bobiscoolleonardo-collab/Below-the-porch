# DoorInteract.gd
extends Interactable

@export var door_controller: Node

func interact() -> void:
	door_controller.interact()
