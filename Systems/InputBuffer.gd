class_name InputBuffer
extends Node

var frame := 0
var dir_hist: Array[Vector2i] = []
var btn_hist: Array = []
var held_dir := Vector2i.ZERO
var facing := 1
var forward_tap_frame := -999
var back_tap_frame := -999
var prev_rel_x := 0


func capture(sample: Dictionary) -> void:
	frame += 1
	held_dir = sample.get("dir", Vector2i.ZERO)
	dir_hist.append(held_dir)
	btn_hist.append((sample.get("pressed", {}) as Dictionary).duplicate())
	if dir_hist.size() > 24:
		dir_hist.pop_front()
		btn_hist.pop_front()
	var rel_x := held_dir.x * facing
	if rel_x > 0 and prev_rel_x <= 0:
		if forward_tap_frame > 0 and frame - forward_tap_frame <= 16 and frame - forward_tap_frame > 1:
			forward_tap_frame = -frame
		else:
			forward_tap_frame = frame
	if rel_x < 0 and prev_rel_x >= 0:
		if back_tap_frame > 0 and frame - back_tap_frame <= 16 and frame - back_tap_frame > 1:
			back_tap_frame = -frame
		else:
			back_tap_frame = frame
	prev_rel_x = rel_x


func dash_tapped(forward: bool) -> bool:
	var stamp := forward_tap_frame if forward else back_tap_frame
	# A negative stamp is the frame a double tap was confirmed. The initial
	# sentinel is also negative, so it only counts when it was set this frame.
	if stamp < 0 and frame + stamp >= 0 and frame + stamp <= 2:
		if forward:
			forward_tap_frame = 0
		else:
			back_tap_frame = 0
		return true
	return false


func relative_held() -> Vector2i:
	return Vector2i(held_dir.x * facing, held_dir.y)


func pressed_within(buttons: Array, window: int = Constants.BUFFER_FRAMES) -> bool:
	var count := mini(window, btn_hist.size())
	for step in count:
		var record: Dictionary = btn_hist[btn_hist.size() - 1 - step]
		for button in buttons:
			if record.get(button, false):
				return true
	return false


func first_pressed(order: Array) -> String:
	for button in order:
		if pressed_within([button]):
			return button
	return ""


func consume_buttons() -> void:
	var count := mini(Constants.BUFFER_FRAMES, btn_hist.size())
	for step in count:
		var record: Dictionary = btn_hist[btn_hist.size() - 1 - step]
		for button in Constants.BUTTONS:
			record[button] = false


func matches(pattern: Array, window: int = 18) -> bool:
	var seq := _sequence(window)
	var index := 0
	for digit in seq:
		if digit == pattern[index]:
			index += 1
			if index >= pattern.size():
				return true
	return false


func has_360(window: int = 20) -> bool:
	var found := {4: false, 2: false, 6: false}
	for digit in _sequence(window):
		if found.has(digit):
			found[digit] = true
	return found[4] and found[2] and found[6]


func _sequence(window: int) -> Array[int]:
	var seq: Array[int] = []
	var start := maxi(0, dir_hist.size() - window)
	var prev := -1
	for i in range(start, dir_hist.size()):
		var digit := _numpad(dir_hist[i])
		if digit != 5 and digit != prev:
			seq.append(digit)
			prev = digit
	return seq


func _numpad(dir: Vector2i) -> int:
	var x := dir.x * facing
	var y := dir.y
	if x == 0 and y == 0:
		return 5
	if x > 0 and y > 0:
		return 3
	if x > 0 and y < 0:
		return 9
	if x < 0 and y > 0:
		return 1
	if x < 0 and y < 0:
		return 7
	if x > 0:
		return 6
	if x < 0:
		return 4
	if y > 0:
		return 2
	return 8
