extends Control


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := TextureRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.texture = load("res://assets/tokyo.jpg")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var shade := ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.02, 0.03, 0.06, 0.55)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	var title := Label.new()
	title.text = "MIGHT NITE"
	title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title.position = Vector2(-300, 160)
	title.size = Vector2(600, 90)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 72)
	add_child(title)

	var sub := Label.new()
	sub.text = "LOCAL 1V1"
	sub.set_anchors_preset(Control.PRESET_CENTER_TOP)
	sub.position = Vector2(-200, 250)
	sub.size = Vector2(400, 36)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 22)
	add_child(sub)

	var fight := Button.new()
	fight.text = "FIGHT"
	fight.position = Vector2(490, 380)
	fight.size = Vector2(300, 64)
	fight.add_theme_font_size_override("font_size", 28)
	fight.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://Scenes/CharacterSelect.tscn")
	)
	add_child(fight)

	var hint := Label.new()
	hint.text = "Enter to fight    Esc to quit"
	hint.position = Vector2(340, 470)
	hint.size = Vector2(600, 30)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(hint)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER or event.keycode == KEY_SPACE:
			get_tree().change_scene_to_file("res://Scenes/CharacterSelect.tscn")
		elif event.keycode == KEY_ESCAPE:
			get_tree().quit()
