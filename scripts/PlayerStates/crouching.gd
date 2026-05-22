class_name crouching extends State


func update(_delta):
	if !global.player.default_collision.disabled:
		transition.emit("Idle")
	if global.player.velocity_y_last < -1.5:
		transition.emit("Falling")
