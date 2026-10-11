extends Control

var code_edit: LineEdit
var status_label: Label
var _moved := false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.05, 0.06, 0.09)
	add_child(bg)

	var title := Label.new()
	title.text = "ONLINE 1V1"
	title.position = Vector2(340, 120)
	title.size = Vector2(600, 64)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	add_child(title)

	status_label = Label.new()
	status_label.position = Vector2(240, 200)
	status_label.size = Vector2(800, 80)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(status_label)

	if not Net.configured():
		status_label.text = "Copy Core/SupabaseConfig.example.gd to Core/SupabaseConfig.gd and add the publishable key."
		_back_button()
		return

	var host := Button.new()
	host.text = "HOST ROOM"
	host.position = Vector2(490, 300)
	host.size = Vector2(300, 56)
	host.add_theme_font_size_override("font_size", 24)
	host.pressed.connect(func() -> void:
		Net.create_room()
	)
	add_child(host)

	code_edit = LineEdit.new()
	code_edit.placeholder_text = "ROOM CODE"
	code_edit.position = Vector2(490, 380)
	code_edit.size = Vector2(300, 48)
	code_edit.max_length = 4
	code_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(code_edit)

	var join := Button.new()
	join.text = "JOIN"
	join.position = Vector2(490, 444)
	join.size = Vector2(300, 52)
	join.pressed.connect(func() -> void:
		Net.join_room(code_edit.text)
	)
	add_child(join)
	_back_button()
	if not Net.notice_changed.is_connected(_on_notice):
		Net.notice_changed.connect(_on_notice)
	if not Net.room_updated.is_connected(_on_room):
		Net.room_updated.connect(_on_room)
	_on_notice(Net.notice)


func _back_button() -> void:
	var back := Button.new()
	back.text = "BACK"
	back.position = Vector2(490, 560)
	back.size = Vector2(300, 48)
	back.pressed.connect(func() -> void:
		Net.leave()
	)
	add_child(back)


func _on_notice(text: String) -> void:
	if status_label:
		status_label.text = text


func _on_room(row: Dictionary) -> void:
	if _moved or row.is_empty():
		return
	var guest = row.get("guest_id")
	if guest == null or str(guest) == "" or str(guest) == "<null>":
		if status_label and Net.local_slot == 0:
			status_label.text = "Room %s    waiting for opponent" % Net.room_code
		return
	_moved = true
	get_tree().change_scene_to_file("res://Scenes/CharacterSelect.tscn")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		Net.leave()
