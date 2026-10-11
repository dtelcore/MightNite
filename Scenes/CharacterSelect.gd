extends Control

var characters: Array = []
var stages: Array = []
var p1_index := 0
var p2_index := 2
var stage_index := 0
var p1_panels: Array = []
var stage_panels: Array = []
var hint: Label
var start_button: Button
var online_ready := false
var _online_seeded := false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	characters = [
		load("res://Characters/MartialHero/MartialHero.tres"),
		load("res://Characters/LightBandit/LightBandit.tres"),
		load("res://Characters/HeavyBandit/HeavyBandit.tres"),
	]
	stages = [
		load("res://Stages/dojo.tres"),
		load("res://Stages/shrine.tres"),
		load("res://Stages/neon.tres"),
		load("res://Stages/dock.tres"),
		load("res://Stages/pit.tres"),
	]
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.05, 0.06, 0.09)
	add_child(bg)

	var title := Label.new()
	title.text = "CHOOSE FIGHTERS"
	title.position = Vector2(340, 24)
	title.size = Vector2(600, 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	add_child(title)

	_roster()
	_stage_row()

	var start := Button.new()
	start.text = "READY" if Net.online else "START MATCH"
	start.position = Vector2(490, 640)
	start.size = Vector2(300, 52)
	start.pressed.connect(_start)
	add_child(start)
	start_button = start
	hint = Label.new()
	hint.text = "P1 A/D or click    P2 arrows or right click    Stage Q/E    Enter start"
	hint.position = Vector2(140, 600)
	hint.size = Vector2(1000, 28)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(hint)
	if Net.online:
		if not Net.room_updated.is_connected(_on_online_room):
			Net.room_updated.connect(_on_online_room)
		_on_online_room(Net.room)
	_refresh()


func _roster() -> void:
	var label := Label.new()
	label.text = "P1 RED    P2 BLUE"
	label.position = Vector2(340, 78)
	label.size = Vector2(600, 28)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(label)
	var panel_w := 200.0
	var gap := 24.0
	var total := float(characters.size()) * panel_w + float(characters.size() - 1) * gap
	var x0 := (1280.0 - total) * 0.5
	for i in characters.size():
		var panel := Panel.new()
		panel.position = Vector2(x0 + float(i) * (panel_w + gap), 112)
		panel.size = Vector2(panel_w, 250)
		panel.gui_input.connect(_on_portrait.bind(i))
		var portrait := TextureRect.new()
		portrait.set_anchors_preset(Control.PRESET_FULL_RECT)
		portrait.offset_left = 8
		portrait.offset_top = 8
		portrait.offset_right = -8
		portrait.offset_bottom = -36
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		portrait.texture = _portrait(characters[i])
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(portrait)
		var name_label := Label.new()
		name_label.text = characters[i].character_name.to_upper()
		name_label.position = Vector2(0, 214)
		name_label.size = Vector2(panel_w, 28)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(name_label)
		add_child(panel)
		p1_panels.append(panel)


func _stage_row() -> void:
	var label := Label.new()
	label.text = "STAGE"
	label.position = Vector2(40, 420)
	label.size = Vector2(120, 28)
	add_child(label)
	for i in stages.size():
		var panel := Panel.new()
		panel.position = Vector2(40 + float(i) * 246.0, 456)
		panel.size = Vector2(230, 120)
		panel.gui_input.connect(_on_stage.bind(i))
		var thumb := TextureRect.new()
		thumb.set_anchors_preset(Control.PRESET_FULL_RECT)
		thumb.offset_left = 6
		thumb.offset_top = 6
		thumb.offset_right = -6
		thumb.offset_bottom = -24
		thumb.texture = stages[i].texture
		thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		thumb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(thumb)
		var name_label := Label.new()
		name_label.text = stages[i].stage_name
		name_label.position = Vector2(0, 94)
		name_label.size = Vector2(230, 22)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(name_label)
		add_child(panel)
		stage_panels.append(panel)


func _portrait(data: CharacterData) -> Texture2D:
	if data == null or data.sprite == null:
		return null
	var atlas := AtlasTexture.new()
	atlas.atlas = data.sprite
	atlas.region = Rect2(0, 0, data.frame_size.x, data.frame_size.y)
	return atlas


func _on_portrait(event: InputEvent, index: int) -> void:
	if not (event is InputEventMouseButton) or not event.pressed:
		return
	if Net.online:
		if event.button_index != MOUSE_BUTTON_LEFT:
			return
		if Net.local_slot == 0:
			p1_index = index
		else:
			p2_index = index
		_push_online(false)
		_refresh()
		return
	if event.button_index == MOUSE_BUTTON_RIGHT:
		p2_index = index
	elif event.button_index == MOUSE_BUTTON_LEFT:
		p1_index = index
	else:
		return
	_refresh()


func _on_stage(event: InputEvent, index: int) -> void:
	if Net.online and Net.local_slot != 0:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		stage_index = index
		if Net.online:
			_push_online(false)
		_refresh()


func _refresh() -> void:
	for i in p1_panels.size():
		var color := Color(1, 1, 1, 0.12)
		if i == p1_index and i == p2_index:
			color = Color(0.85, 0.45, 0.75)
		elif i == p1_index:
			color = Color(0.9, 0.25, 0.2)
		elif i == p2_index:
			color = Color(0.25, 0.5, 0.95)
		_paint(p1_panels[i], i == p1_index or i == p2_index, color)
	for i in stage_panels.size():
		_paint(stage_panels[i], i == stage_index, Color(0.95, 0.8, 0.25))


func _paint(panel: Panel, selected: bool, color: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.13, 0.16)
	style.border_color = color if selected else Color(1, 1, 1, 0.12)
	style.set_border_width_all(4 if selected else 1)
	style.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", style)


func _unhandled_input(event: InputEvent) -> void:
	if Net.online:
		_online_input(event)
		return
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_A:
			p1_index = posmod(p1_index - 1, characters.size())
		KEY_D:
			p1_index = posmod(p1_index + 1, characters.size())
		KEY_LEFT:
			p2_index = posmod(p2_index - 1, characters.size())
		KEY_RIGHT:
			p2_index = posmod(p2_index + 1, characters.size())
		KEY_Q, KEY_UP:
			stage_index = posmod(stage_index - 1, stages.size())
		KEY_E, KEY_DOWN:
			stage_index = posmod(stage_index + 1, stages.size())
		KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
			_start()
			return
		KEY_ESCAPE:
			get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")
			return
		_:
			return
	_refresh()


func _start() -> void:
	if Net.online:
		_push_online(true)
		return
	GameManager.p1_data = characters[p1_index]
	GameManager.p2_data = characters[p2_index]
	GameManager.stage = stages[stage_index]
	GameManager.p1_rounds = 0
	GameManager.p2_rounds = 0
	get_tree().change_scene_to_file("res://Scenes/Match.tscn")


func _online_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var index := p1_index if Net.local_slot == 0 else p2_index
	match event.keycode:
		KEY_A:
			index = posmod(index - 1, characters.size())
		KEY_D:
			index = posmod(index + 1, characters.size())
		KEY_Q, KEY_UP:
			if Net.local_slot != 0:
				return
			stage_index = posmod(stage_index - 1, stages.size())
		KEY_E, KEY_DOWN:
			if Net.local_slot != 0:
				return
			stage_index = posmod(stage_index + 1, stages.size())
		KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
			_push_online(true)
			return
		KEY_ESCAPE:
			Net.leave()
			return
		_:
			return
	if Net.local_slot == 0:
		p1_index = index
	else:
		p2_index = index
	_push_online(false)
	_refresh()


func _push_online(ready: bool) -> void:
	online_ready = ready
	var index := p1_index if Net.local_slot == 0 else p2_index
	Net.push_local(_character_id(index), _stage_id(), ready)
	if start_button:
		start_button.text = "WAITING" if ready else "READY"


func _on_online_room(row: Dictionary) -> void:
	if row.is_empty() or not Net.online:
		return
	if not _online_seeded:
		_online_seeded = true
		p1_index = _index_for_character(_clean(row.get("p1_character", "MartialHero")))
		p2_index = _index_for_character(_clean(row.get("p2_character", "HeavyBandit")))
		stage_index = _index_for_stage(_clean(row.get("stage_id", "dojo")))
	elif Net.local_slot == 0:
		p2_index = _index_for_character(_clean(row.get("p2_character", "HeavyBandit")))
	else:
		p1_index = _index_for_character(_clean(row.get("p1_character", "MartialHero")))
		stage_index = _index_for_stage(_clean(row.get("stage_id", "dojo")))
	online_ready = bool(row.get("host_ready")) if Net.local_slot == 0 else bool(row.get("guest_ready"))
	if start_button:
		start_button.text = "WAITING" if online_ready else "READY"
	if hint:
		var side := "P1" if Net.local_slot == 0 else "P2"
		var stage_help := "Q/E stage" if Net.local_slot == 0 else "Host picks the stage"
		hint.text = "You are %s    A/D fighter    %s    Enter ready    P1 %s    P2 %s" % [
			side,
			stage_help,
			"ready" if row.get("host_ready") else "picking",
			"ready" if row.get("guest_ready") else "picking",
		]
	_refresh()


func _character_id(index: int) -> String:
	return Net.CHARACTER_IDS.get(characters[index].character_name, "MartialHero")


func _stage_id() -> String:
	return Net.STAGE_IDS.get(stages[stage_index].stage_name, "dojo")


func _index_for_character(id: String) -> int:
	for i in characters.size():
		if _character_id(i) == id:
			return i
	return 0


func _index_for_stage(id: String) -> int:
	for i in stages.size():
		if Net.STAGE_IDS.get(stages[i].stage_name, "") == id:
			return i
	return 0


func _clean(value) -> String:
	if value == null:
		return ""
	var text := str(value)
	if text == "<null>":
		return ""
	return text
