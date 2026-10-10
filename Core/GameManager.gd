extends Node

var p1_data: CharacterData
var p2_data: CharacterData
var stage: StageData
var p1_rounds := 0
var p2_rounds := 0
var debug := false
var hitstop_frames := 0

func _ready() -> void:
	process_physics_priority = -128
	_setup_inputs()
	_load_defaults()


func _load_defaults() -> void:
	p1_data = load("res://Characters/Ryuji/Ryuji.tres")
	p2_data = load("res://Characters/Titan/Titan.tres")
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


func _setup_inputs() -> void:
	if InputMap.has_action("p1_left"):
		return
	_key("p1_left", KEY_A)
	_key("p1_right", KEY_D)
	_key("p1_up", KEY_W)
	_key("p1_down", KEY_S)
	_key("p1_lp", KEY_U)
	_key("p1_mp", KEY_I)
	_key("p1_hp", KEY_O)
	_key("p1_lk", KEY_J)
	_key("p1_mk", KEY_K)
	_key("p1_hk", KEY_L)

	_key("p2_left", KEY_LEFT)
	_key("p2_right", KEY_RIGHT)
	_key("p2_up", KEY_UP)
	_key("p2_down", KEY_DOWN)
	_key("p2_lp", KEY_KP_7)
	_key("p2_mp", KEY_KP_8)
	_key("p2_hp", KEY_KP_9)
	_key("p2_lk", KEY_KP_4)
	_key("p2_mk", KEY_KP_5)
	_key("p2_hk", KEY_KP_6)
	_key("p2_lp", KEY_SEMICOLON)
	_key("p2_mp", KEY_APOSTROPHE)
	_key("p2_hp", KEY_BACKSLASH)
	_key("p2_lk", KEY_COMMA)
	_key("p2_mk", KEY_PERIOD)
	_key("p2_hk", KEY_SLASH)

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


func _key(action: String, keycode: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.5)
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	InputMap.action_add_event(action, event)


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
