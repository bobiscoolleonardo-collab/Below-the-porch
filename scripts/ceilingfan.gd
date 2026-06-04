extends Node3D

@export var fan : MeshInstance3D

var spin_speed : float = 10.0
var should_spin : bool = false

func _process(delta: float) -> void:
	if should_spin:
		fan.rotation.y += delta * spin_speed

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body:
		if body.name == "Player":
			should_spin = true


func _on_area_3d_body_exited(body: Node3D) -> void:
	if body:
		if body.name == "Player":
			should_spin = false
