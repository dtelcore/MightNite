class_name InputManager
extends RefCounted

static func sample(player_index: int) -> Dictionary:
	var prefix := "p1" if player_index == 0 else "p2"
	var x := 0
	var y := 0
	if Input.is_action_pressed(prefix + "_right"):
		x += 1
	if Input.is_action_pressed(prefix + "_left"):
		x -= 1
	if Input.is_action_pressed(prefix + "_down"):
		y += 1
	if Input.is_action_pressed(prefix + "_up"):
		y -= 1
	var pressed := {}
	for button in Constants.BUTTONS:
		pressed[button] = Input.is_action_just_pressed(prefix + "_" + button)
	return {"dir": Vector2i(x, y), "pressed": pressed}
