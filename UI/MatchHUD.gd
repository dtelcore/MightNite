class_name MatchHUD
extends CanvasLayer

var p1
var p2
var p1_fill: ColorRect
var p2_fill: ColorRect
var p1_shown := 1.0
var p2_shown := 1.0
var timer_label: Label
var announce_label: Label
var combo_label: Label
var rounds_label: Label
var debug_label: Label
var p1_name: Label
var p2_name: Label

const BAR_W := 460.0
const BAR_H := 22.0


func setup(a, b) -> void:
	layer = 10
	p1 = a
	p2 = b
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_bar(root, 36, true)
	_bar(root, 36, false)
	p1_name = _label(root, p1.data.character_name.to_upper(), 40, 28, 280, 28, HORIZONTAL_ALIGNMENT_LEFT)
	p2_name = _label(root, p2.data.character_name.to_upper(), 960, 28, 280, 28, HORIZONTAL_ALIGNMENT_RIGHT)
	timer_label = _label(root, "99", 590, 22, 100, 48, HORIZONTAL_ALIGNMENT_CENTER)
	timer_label.add_theme_font_size_override("font_size", 40)
	rounds_label = _label(root, "", 440, 96, 400, 24, HORIZONTAL_ALIGNMENT_CENTER)
	combo_label = _label(root, "", 490, 250, 300, 48, HORIZONTAL_ALIGNMENT_CENTER)
	combo_label.add_theme_font_size_override("font_size", 36)
	announce_label = _label(root, "", 240, 300, 800, 90, HORIZONTAL_ALIGNMENT_CENTER)
	announce_label.add_theme_font_size_override("font_size", 64)
	debug_label = _label(root, "", 24, 640, 900, 24, HORIZONTAL_ALIGNMENT_LEFT)
	var help := _label(root, _help_text(), 180, 680, 920, 22, HORIZONTAL_ALIGNMENT_CENTER)
	help.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
	refresh_rounds()


func _bar(root: Control, y: float, left: bool) -> void:
	var back := ColorRect.new()
	back.color = Color(0.08, 0.08, 0.1, 0.9)
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var x := 36.0 if left else 1280.0 - 36.0 - BAR_W
	back.position = Vector2(x, y + 36)
	back.size = Vector2(BAR_W, BAR_H)
	root.add_child(back)
	var fill := ColorRect.new()
	fill.color = Color(0.86, 0.16, 0.18) if left else Color(0.25, 0.52, 0.95)
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fill.position = back.position
	fill.size = back.size
	root.add_child(fill)
	if left:
		p1_fill = fill
	else:
		p2_fill = fill


func _label(root: Control, text: String, x: float, y: float, w: float, h: float, align: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.text = text
	label.position = Vector2(x, y)
	label.size = Vector2(w, h)
	label.horizontal_alignment = align
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color(0.96, 0.96, 0.98))
	root.add_child(label)
	return label


func set_time(seconds: int) -> void:
	if timer_label:
		timer_label.text = str(seconds)


func announce(text: String) -> void:
	if announce_label:
		announce_label.text = text


func refresh_rounds() -> void:
	if rounds_label == null:
		return
	rounds_label.text = "P1 %s    P2 %s" % [_pips(GameManager.p1_rounds), _pips(GameManager.p2_rounds)]


func _pips(count: int) -> String:
	var text := ""
	for i in 2:
		text += "●" if i < count else "○"
	return text


func _help_text() -> String:
	if Net.online:
		var side := "P1" if Net.local_slot == 0 else "P2"
		return "You are %s    use the P1 keys    delay %d    Esc menu" % [side, Net.input_delay]
	return "P1 WASD + UIO/JKL    P2 Arrows + ; ' \\ , . /    F1 debug    Esc menu"


func _process(_delta: float) -> void:
	if p1 == null or p2 == null or p1.hp == null:
		return
	p1_shown = lerpf(p1_shown, float(p1.hp.current) / float(p1.hp.maximum), 0.18)
	p2_shown = lerpf(p2_shown, float(p2.hp.current) / float(p2.hp.maximum), 0.18)
	p1_fill.size.x = BAR_W * p1_shown
	p2_fill.size.x = BAR_W * p2_shown
	p2_fill.position.x = 1280.0 - 36.0 - p2_fill.size.x
	var hits := maxi(p1.combo_count, p2.combo_count)
	combo_label.text = "%d HITS" % hits if hits >= 2 else ""
	if GameManager.debug:
		debug_label.text = "HITBOXES ON    P1 %s  P2 %s  combo %d/%d" % [p1.machine.state_name(), p2.machine.state_name(), p1.combo_count, p2.combo_count]
	else:
		debug_label.text = ""
