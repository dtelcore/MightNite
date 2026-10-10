extends Control

var characters: Array = []
var stages: Array = []
var p1_index := 0
var p2_index := 1
var stage_index := 0
var p1_panels: Array = []
var p2_panels: Array = []
var stage_panels: Array = []


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	characters = [
		load("res://Characters/Ryuji/Ryuji.tres"),
		load("res://Characters/Titan/Titan.tres"),
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

	_side(0, "P1", 80)
	_side(1, "P2", 700)
	_stage_row()

	var start := Button.new()
	start.text = "START MATCH"
	start.position = Vector2(490, 640)
	start.size = Vector2(300, 52)
	start.pressed.connect(_start)
	add_child(start)
	var hint := Label.new()
	hint.text = "P1 A/D    P2 Left/Right    Stage Q/E    Enter start    Esc back"
	hint.position = Vector2(240, 600)
	hint.size = Vector2(800, 28)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(hint)
	_refresh()


func _side(player: int, caption: String, x: float) -> void:
	var label := Label.new()
	label.text = caption
	label.position = Vector2(x, 78)
	label.size = Vector2(480, 28)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(label)
	for i in characters.size():
		var panel := Panel.new()
		panel.position = Vector2(x + float(i) * 240.0, 116)
		panel.size = Vector2(220, 280)
		panel.gui_input.connect(_on_portrait.bind(player, i))
		var portrait := TextureRect.new()
		portrait.set_anchors_preset(Control.PRESET_FULL_RECT)
		portrait.offset_left = 8
		portrait.offset_top = 8
		portrait.offset_right = -8
		portrait.offset_bottom = -36
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.texture = _upper(characters[i].sprite)
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(portrait)
		var name_label := Label.new()
		name_label.text = characters[i].character_name.to_upper()
		name_label.position = Vector2(0, 244)
		name_label.size = Vector2(220, 28)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(name_label)
		add_child(panel)
		if player == 0:
			p1_panels.append(panel)
		else:
			p2_panels.append(panel)


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


func _upper(texture: Texture2D) -> Texture2D:
	if texture == null:
		return null
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = Rect2(0, 0, texture.get_width(), texture.get_height() * 0.55)
	return atlas


func _on_portrait(event: InputEvent, player: int, index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if player == 0:
			p1_index = index
		else:
			p2_index = index
		_refresh()


func _on_stage(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		stage_index = index
		_refresh()


func _refresh() -> void:
	for i in p1_panels.size():
		_paint(p1_panels[i], i == p1_index, Color(0.9, 0.25, 0.2))
	for i in p2_panels.size():
		_paint(p2_panels[i], i == p2_index, Color(0.25, 0.5, 0.95))
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
	GameManager.p1_data = characters[p1_index]
	GameManager.p2_data = characters[p2_index]
	GameManager.stage = stages[stage_index]
	GameManager.p1_rounds = 0
	GameManager.p2_rounds = 0
	get_tree().change_scene_to_file("res://Scenes/Match.tscn")
