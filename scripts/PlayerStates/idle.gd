class_name idle extends State

func update(_delta):
	if global.player.is_moving and global.player.is_on_floor() and !global.player.is_crouching:
		transition.emit("Walking")
	if global.player.is_on_floor() and Input.is_action_pressed("space") and !global.player.is_crouching:
		transition.emit("Jumping")
	if global.player.velocity_y_last < -1.5:
		transition.emit("Falling")
	if Input.is_action_pressed("crouch"):
		transition.emit("Crouching")
