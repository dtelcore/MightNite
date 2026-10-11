extends Control

var listening_action := ""
var listening_slot := -1
var key_buttons: Dictionary = {}
var order_labels: Array[Label] = []


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.04, 0.05, 0.08)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var title := Label.new()
	title.text = "SETTINGS"
	title.position = Vector2(0, 16)
	title.size = Vector2(1280, 48)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	add_child(title)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(40, 72)
	scroll.size = Vector2(1200, 560)
	add_child(scroll)

	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 8)
	scroll.add_child(box)

	var hint := Label.new()
	hint.text = "Click a key, then press the new one. Esc cancels a rebind. A key already used on that side swaps."
	hint.add_theme_font_size_override("font_size", 16)
	box.add_child(hint)

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 48)
	box.add_child(columns)
	columns.add_child(_bind_column("p1_"))
	columns.add_child(_bind_column("p2_"))

	var order_title := Label.new()
	order_title.text = "COMBO BUTTON ORDER"
	order_title.add_theme_font_size_override("font_size", 22)
	box.add_child(order_title)
	var order_hint := Label.new()
	order_hint.text = "When two attacks are buffered, the one higher in this list comes out."
	order_hint.add_theme_font_size_override("font_size", 16)
	box.add_child(order_hint)
	for i in GameManager.button_order.size():
		box.add_child(_order_row(i))

	var moves := Button.new()
	moves.text = "MOVE LIST"
	moves.custom_minimum_size = Vector2(280, 40)
	moves.pressed.connect(func() -> void:
		if GameManager.p1_data:
			GameManager.move_list_character = GameManager.p1_data.resource_path
		GameManager.move_list_return = "res://Scenes/Settings.tscn"
		get_tree().change_scene_to_file("res://Scenes/MoveList.tscn")
	)
	box.add_child(moves)

	var reset := Button.new()
	reset.text = "RESET CONTROLS"
	reset.custom_minimum_size = Vector2(280, 40)
	reset.pressed.connect(func() -> void:
		listening_action = ""
		listening_slot = -1
		GameManager.reset_controls()
		_refresh()
	)
	box.add_child(reset)

	var back := Button.new()
	back.text = "BACK"
	back.position = Vector2(490, 648)
	back.size = Vector2(300, 52)
	back.add_theme_font_size_override("font_size", 24)
	back.pressed.connect(_leave)
	add_child(back)
	_refresh()


func _bind_column(prefix: String) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2(540, 0)
	column.add_theme_constant_override("separation", 4)
	var heading := Label.new()
	heading.text = "PLAYER 1" if prefix == "p1_" else "PLAYER 2"
	heading.add_theme_font_size_override("font_size", 22)
	column.add_child(heading)
	for action in GameManager.bind_actions():
		if not action.begins_with(prefix):
			continue
		var keys: Array = GameManager.keyboard_binds[action]
		for slot in keys.size():
			column.add_child(_bind_row(action, slot))
	return column


func _bind_row(action: String, slot: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	var name := Label.new()
	name.text = GameManager.bind_label(action)
	name.custom_minimum_size = Vector2(220, 32)
	name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(name)
	var key := Button.new()
	key.custom_minimum_size = Vector2(180, 32)
	key.pressed.connect(_listen.bind(action, slot))
	row.add_child(key)
	key_buttons["%s:%d" % [action, slot]] = key
	return row


func _order_row(index: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var label := Label.new()
	label.custom_minimum_size = Vector2(280, 32)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)
	order_labels.append(label)
	var up := Button.new()
	up.text = "UP"
	up.custom_minimum_size = Vector2(72, 32)
	up.disabled = index == 0
	up.pressed.connect(_move_order.bind(index, -1))
	row.add_child(up)
	var down := Button.new()
	down.text = "DOWN"
	down.custom_minimum_size = Vector2(72, 32)
	down.disabled = index == GameManager.button_order.size() - 1
	down.pressed.connect(_move_order.bind(index, 1))
	row.add_child(down)
	return row


func _listen(action: String, slot: int) -> void:
	listening_action = action
	listening_slot = slot
	_refresh()


func _move_order(index: int, direction: int) -> void:
	GameManager.move_button_order(index, direction)
	_refresh()


func _refresh() -> void:
	for key in key_buttons.keys():
		var parts := str(key).split(":")
		var action := parts[0]
		var slot := int(parts[1])
		var button: Button = key_buttons[key]
		if listening_action == action and listening_slot == slot:
			button.text = "PRESS A KEY"
		else:
			button.text = GameManager.key_text(action, slot)
	for i in order_labels.size():
		var id := GameManager.button_order[i]
		order_labels[i].text = "%d. %s" % [i + 1, GameManager.BUTTON_NAMES.get(id, id)]


func _unhandled_input(event: InputEvent) -> void:
	if listening_action != "":
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode != KEY_ESCAPE:
				GameManager.set_key_bind(listening_action, listening_slot, event.physical_keycode)
			listening_action = ""
			listening_slot = -1
			_refresh()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		_leave()
		get_viewport().set_input_as_handled()


func _leave() -> void:
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")
