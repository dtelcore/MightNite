extends Node

var p1_data: CharacterData
var p2_data: CharacterData
var stage: StageData
var p1_rounds := 0
var p2_rounds := 0
var debug := false
var hitstop_frames := 0
var button_order: Array[String] = ["hp", "mp", "lp", "hk", "mk", "lk"]
var keyboard_binds: Dictionary = {}
var local_p1_wins := 0
var local_p2_wins := 0
var online_wins := 0
var online_losses := 0
var move_list_character := ""
var move_list_return := "res://Scenes/MainMenu.tscn"
var _pads_ready := false

const BUTTON_NAMES := {
	"lp": "Light Punch",
	"mp": "Medium Punch",
	"hp": "Heavy Punch",
	"lk": "Light Kick",
	"mk": "Medium Kick",
	"hk": "Heavy Kick",
}

func _ready() -> void:
	process_physics_priority = -128
	_setup_inputs()
	load_settings()
	_load_defaults()


func _load_defaults() -> void:
	p1_data = load("res://Characters/MartialHero/MartialHero.tres")
	p2_data = load("res://Characters/HeavyBandit/HeavyBandit.tres")
	stage = load("res://Stages/dojo.tres")


func _physics_process(_delta: float) -> void:
	if _controller() != null:
		return
	if hitstop_frames > 0:
		hitstop_frames -= 1


func trigger_hitstop(frames: int) -> void:
	var controller = _controller()
	if controller:
		controller.trigger(frames)
	else:
		hitstop_frames = maxi(hitstop_frames, frames)


func is_frozen() -> bool:
	var controller = _controller()
	if controller:
		return controller.frames > 0
	return hitstop_frames > 0


func play_sfx(sound_name: String) -> void:
	AudioBank.play(self, sound_name)


func tally_text() -> String:
	if Net.online:
		return "ONLINE  %d W  %d L" % [online_wins, online_losses]
	return "RECORD  P1 %d W    P2 %d W" % [local_p1_wins, local_p2_wins]


func record_match(winner_index: int) -> void:
	if Net.online:
		if winner_index == Net.local_slot:
			online_wins += 1
		else:
			online_losses += 1
	elif winner_index == 0:
		local_p1_wins += 1
	else:
		local_p2_wins += 1
	save_settings()


func _controller():
	if not is_inside_tree():
		return null
	var nodes := get_tree().get_nodes_in_group("hitstop")
	if nodes.is_empty():
		return null
	return nodes[0]


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F1:
		debug = not debug
		save_settings()


func _default_binds() -> Dictionary:
	return {
		"p1_left": [KEY_A],
		"p1_right": [KEY_D],
		"p1_up": [KEY_W],
		"p1_down": [KEY_S],
		"p1_lp": [KEY_U],
		"p1_mp": [KEY_I],
		"p1_hp": [KEY_O],
		"p1_lk": [KEY_J],
		"p1_mk": [KEY_K],
		"p1_hk": [KEY_L],
		"p2_left": [KEY_LEFT],
		"p2_right": [KEY_RIGHT],
		"p2_up": [KEY_UP],
		"p2_down": [KEY_DOWN],
		"p2_lp": [KEY_KP_7, KEY_SEMICOLON],
		"p2_mp": [KEY_KP_8, KEY_APOSTROPHE],
		"p2_hp": [KEY_KP_9, KEY_BACKSLASH],
		"p2_lk": [KEY_KP_4, KEY_COMMA],
		"p2_mk": [KEY_KP_5, KEY_PERIOD],
		"p2_hk": [KEY_KP_6, KEY_SLASH],
	}


func bind_actions() -> Array[String]:
	var names: Array[String] = []
	for action in _default_binds().keys():
		names.append(str(action))
	return names


func bind_label(action: String) -> String:
	var side := "P1" if action.begins_with("p1_") else "P2"
	var tail := action.substr(3)
	if BUTTON_NAMES.has(tail):
		return "%s %s" % [side, BUTTON_NAMES[tail]]
	return "%s %s" % [side, tail.capitalize()]


func key_text(action: String, slot: int) -> String:
	var keys: Array = keyboard_binds.get(action, [])
	if slot < 0 or slot >= keys.size():
		return "-"
	return OS.get_keycode_string(int(keys[slot]))


func set_key_bind(action: String, slot: int, keycode: Key) -> bool:
	if not keyboard_binds.has(action):
		return false
	if keycode == KEY_NONE or keycode == KEY_ESCAPE or keycode == KEY_F1:
		return false
	var mine: Array = (keyboard_binds[action] as Array).duplicate()
	if slot < 0 or slot >= mine.size():
		return false
	var previous := int(mine[slot])
	var prefix := action.substr(0, 3)
	for other_name in keyboard_binds.keys():
		var other := str(other_name)
		if not other.begins_with(prefix):
			continue
		var other_keys: Array = keyboard_binds[other]
		for i in other_keys.size():
			if other == action and i == slot:
				continue
			if int(other_keys[i]) == int(keycode):
				other_keys[i] = previous
				keyboard_binds[other] = other_keys
	mine[slot] = int(keycode)
	keyboard_binds[action] = mine
	apply_keyboard_binds()
	save_settings()
	return true


func move_button_order(index: int, direction: int) -> void:
	var next := index + direction
	if index < 0 or next < 0 or index >= button_order.size() or next >= button_order.size():
		return
	var held := button_order[index]
	button_order[index] = button_order[next]
	button_order[next] = held
	save_settings()


func reset_controls() -> void:
	keyboard_binds = _default_binds()
	button_order = ["hp", "mp", "lp", "hk", "mk", "lk"]
	apply_keyboard_binds()
	save_settings()


func load_settings() -> void:
	var file := ConfigFile.new()
	if file.load("user://settings.cfg") != OK:
		return
	debug = bool(file.get_value("settings", "debug", debug))
	var order = file.get_value("settings", "button_order", [])
	if order is Array and order.size() == button_order.size():
		var next: Array[String] = []
		var seen := {}
		for item in order:
			var name := str(item)
			if not BUTTON_NAMES.has(name) or seen.has(name):
				next.clear()
				break
			seen[name] = true
			next.append(name)
		if next.size() == button_order.size():
			button_order = next
	for action in bind_actions():
		if not keyboard_binds.has(action):
			continue
		var saved = file.get_value("binds", action, null)
		if not (saved is Array):
			continue
		var current: Array = keyboard_binds[action]
		if saved.size() != current.size():
			continue
		var keys: Array = []
		for key in saved:
			keys.append(int(key))
		keyboard_binds[action] = keys
	local_p1_wins = int(file.get_value("tally", "local_p1_wins", 0))
	local_p2_wins = int(file.get_value("tally", "local_p2_wins", 0))
	online_wins = int(file.get_value("tally", "online_wins", 0))
	online_losses = int(file.get_value("tally", "online_losses", 0))
	apply_keyboard_binds()


func save_settings() -> void:
	var file := ConfigFile.new()
	file.set_value("settings", "debug", debug)
	file.set_value("settings", "button_order", button_order)
	for action in keyboard_binds.keys():
		file.set_value("binds", str(action), keyboard_binds[action])
	file.set_value("tally", "local_p1_wins", local_p1_wins)
	file.set_value("tally", "local_p2_wins", local_p2_wins)
	file.set_value("tally", "online_wins", online_wins)
	file.set_value("tally", "online_losses", online_losses)
	file.save("user://settings.cfg")


func apply_keyboard_binds() -> void:
	for action in keyboard_binds.keys():
		var name := str(action)
		if not InputMap.has_action(name):
			InputMap.add_action(name, 0.5)
		for event in InputMap.action_get_events(name):
			if event is InputEventKey:
				InputMap.action_erase_event(name, event)
		for keycode in keyboard_binds[action]:
			var event := InputEventKey.new()
			event.physical_keycode = int(keycode) as Key
			InputMap.action_add_event(name, event)


func _setup_inputs() -> void:
	if keyboard_binds.is_empty():
		keyboard_binds = _default_binds()
	apply_keyboard_binds()
	if _pads_ready:
		return
	_pads_ready = true
	_joy_axis("p1_left", 0, JOY_AXIS_LEFT_X, -1.0)
	_joy_axis("p1_right", 0, JOY_AXIS_LEFT_X, 1.0)
	_joy_axis("p1_up", 0, JOY_AXIS_LEFT_Y, -1.0)
	_joy_axis("p1_down", 0, JOY_AXIS_LEFT_Y, 1.0)
	_joy_button("p1_lp", 0, JOY_BUTTON_X)
	_joy_button("p1_mp", 0, JOY_BUTTON_Y)
	_joy_button("p1_hp", 0, JOY_BUTTON_RIGHT_SHOULDER)
	_joy_button("p1_lk", 0, JOY_BUTTON_A)
	_joy_button("p1_mk", 0, JOY_BUTTON_B)
	_joy_button("p1_hk", 0, JOY_BUTTON_RIGHT_STICK)

	_joy_axis("p2_left", 1, JOY_AXIS_LEFT_X, -1.0)
	_joy_axis("p2_right", 1, JOY_AXIS_LEFT_X, 1.0)
	_joy_axis("p2_up", 1, JOY_AXIS_LEFT_Y, -1.0)
	_joy_axis("p2_down", 1, JOY_AXIS_LEFT_Y, 1.0)
	_joy_button("p2_lp", 1, JOY_BUTTON_X)
	_joy_button("p2_mp", 1, JOY_BUTTON_Y)
	_joy_button("p2_hp", 1, JOY_BUTTON_RIGHT_SHOULDER)
	_joy_button("p2_lk", 1, JOY_BUTTON_A)
	_joy_button("p2_mk", 1, JOY_BUTTON_B)
	_joy_button("p2_hk", 1, JOY_BUTTON_RIGHT_STICK)


func _joy_button(action: String, device: int, button: JoyButton) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.5)
	var event := InputEventJoypadButton.new()
	event.device = device
	event.button_index = button
	InputMap.action_add_event(action, event)


func _joy_axis(action: String, device: int, axis: JoyAxis, value: float) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.5)
	var event := InputEventJoypadMotion.new()
	event.device = device
	event.axis = axis
	event.axis_value = value
	InputMap.action_add_event(action, event)
