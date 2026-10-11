extends Control

const ROSTER: Array[String] = [
	"res://Characters/MartialHero/MartialHero.tres",
	"res://Characters/LightBandit/LightBandit.tres",
	"res://Characters/HeavyBandit/HeavyBandit.tres",
]

var index := 0
var list: VBoxContainer


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.04, 0.05, 0.08)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	for i in ROSTER.size():
		if ROSTER[i] == GameManager.move_list_character:
			index = i
	var title := Label.new()
	title.text = "MOVE LIST"
	title.position = Vector2(0, 12)
	title.size = Vector2(1280, 36)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	add_child(title)

	var previous := Button.new()
	previous.text = "PREV"
	previous.position = Vector2(280, 56)
	previous.size = Vector2(120, 40)
	previous.pressed.connect(func() -> void:
		index = posmod(index - 1, ROSTER.size())
		_fill()
	)
	add_child(previous)
	var next := Button.new()
	next.text = "NEXT"
	next.position = Vector2(880, 56)
	next.size = Vector2(120, 40)
	next.pressed.connect(func() -> void:
		index = posmod(index + 1, ROSTER.size())
		_fill()
	)
	add_child(next)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(80, 108)
	scroll.size = Vector2(1120, 520)
	add_child(scroll)
	list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 6)
	scroll.add_child(list)

	var back := Button.new()
	back.text = "BACK"
	back.position = Vector2(490, 648)
	back.size = Vector2(300, 52)
	back.add_theme_font_size_override("font_size", 24)
	back.pressed.connect(_leave)
	add_child(back)
	_fill()


func _fill() -> void:
	for child in list.get_children():
		child.queue_free()
	var data: CharacterData = load(ROSTER[index])
	GameManager.move_list_character = ROSTER[index]
	var heading := Label.new()
	heading.text = data.character_name.to_upper()
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 24)
	list.add_child(heading)
	for move in data.all_moves():
		var row := Label.new()
		row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.custom_minimum_size = Vector2(1080, 0)
		row.text = "%s    %s\n%s" % [move.move_name, _phrase(move), _keys_for(move.move_name)]
		row.add_theme_font_size_override("font_size", 16)
		list.add_child(row)


func _phrase(move: MoveData) -> String:
	var id := move.move_name
	if id == "236P":
		return "Quarter-circle forward + punch"
	if id == "623P":
		return "Forward, down, down-forward + punch"
	if id == "360P":
		return "Full circle + punch"
	if id == "236236P":
		return "Double quarter-circle forward + punch"
	if id == "throw":
		return "Light punch + light kick"
	if id == "6HK":
		return "Forward + heavy kick"
	var where := "Standing"
	var tail := id
	if id.begins_with("j"):
		where = "Jumping"
		tail = id.substr(1)
	elif id.begins_with("2"):
		where = "Crouching"
		tail = id.substr(1)
	elif id.begins_with("5"):
		tail = id.substr(1)
	var strength: String = GameManager.BUTTON_NAMES.get(_button_for_tail(tail), tail)
	return "%s %s" % [where, strength.to_lower()]


func _button_for_tail(tail: String) -> String:
	match tail:
		"LP":
			return "lp"
		"MP":
			return "mp"
		"HP":
			return "hp"
		"LK":
			return "lk"
		"MK":
			return "mk"
		"HK":
			return "hk"
		_:
			return ""


func _keys_for(id: String) -> String:
	var buttons: Array[String] = []
	if id == "throw":
		buttons = ["lp", "lk"]
	elif id.ends_with("P"):
		buttons = ["lp", "mp", "hp"]
	else:
		var tail := id.substr(maxi(id.length() - 2, 0))
		var button := _button_for_tail(tail)
		if button != "":
			buttons = [button]
	var parts: Array[String] = []
	for button in buttons:
		var p2_alt := GameManager.key_text("p2_" + button, 1)
		parts.append("%s  P1 %s   P2 %s / %s" % [
			GameManager.BUTTON_NAMES.get(button, button),
			GameManager.key_text("p1_" + button, 0),
			GameManager.key_text("p2_" + button, 0),
			p2_alt,
		])
	return "   ".join(parts)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		_leave()
		get_viewport().set_input_as_handled()


func _leave() -> void:
	var back := GameManager.move_list_return
	if back == "":
		back = "res://Scenes/MainMenu.tscn"
	get_tree().change_scene_to_file(back)
