class_name FighterRig
extends Node2D

const PIVOTS := {
	"Ryuji": {
		"rear_shoulder": Vector2(250, 300),
		"rear_elbow": Vector2(175, 400),
		"lead_shoulder": Vector2(460, 230),
		"lead_elbow": Vector2(530, 360),
		"rear_hip": Vector2(340, 610),
		"rear_knee": Vector2(200, 790),
		"lead_hip": Vector2(450, 600),
		"lead_knee": Vector2(560, 820),
	},
	"Titan": {
		"rear_shoulder": Vector2(250, 210),
		"rear_elbow": Vector2(168, 402),
		"lead_shoulder": Vector2(560, 200),
		"lead_elbow": Vector2(600, 400),
		"rear_hip": Vector2(320, 540),
		"rear_knee": Vector2(210, 730),
		"lead_hip": Vector2(500, 540),
		"lead_knee": Vector2(564, 712),
	},
}

var base_scale := 0.25
var lead_shoulder: Node2D
var lead_elbow: Node2D
var rear_shoulder: Node2D
var rear_elbow: Node2D
var lead_hip: Node2D
var lead_knee: Node2D
var rear_hip: Node2D
var rear_knee: Node2D
var body: Node2D

var _bones: Dictionary = {}
var _rest := Vector2.ZERO
var _cx := 0.0
var _foot_y := 0.0
var _tex_size := Vector2.ZERO
var _lean_rotation := 0.0
var _lean_offset := Vector2.ZERO


func setup(source: Texture2D, character: String, body_height: float) -> void:
	if source == null:
		return
	var key := character if PIVOTS.has(character) else "Ryuji"
	_measure(source)
	base_scale = body_height / _tex_size.y
	var folder := key.to_lower()
	body = Node2D.new()
	body.name = "Body"
	add_child(body)
	_add_chain(self, key, folder, "rear_hip", "rear_knee", "rear_thigh", "rear_shin", -2)
	_add_chain(body, key, folder, "rear_shoulder", "rear_elbow", "rear_upper", "rear_fore", -1)
	var torso := _make_sprite(folder, "torso")
	torso.position = _rest
	torso.z_index = 0
	body.add_child(torso)
	_add_chain(self, key, folder, "lead_hip", "lead_knee", "lead_thigh", "lead_shin", 1)
	_add_chain(body, key, folder, "lead_shoulder", "lead_elbow", "lead_upper", "lead_fore", 2)
	rear_hip = _bones["rear_hip"]
	rear_knee = _bones["rear_knee"]
	lead_hip = _bones["lead_hip"]
	lead_knee = _bones["lead_knee"]
	rear_shoulder = _bones["rear_shoulder"]
	rear_elbow = _bones["rear_elbow"]
	lead_shoulder = _bones["lead_shoulder"]
	lead_elbow = _bones["lead_elbow"]
	pose_idle()


func apply_facing(facing: int) -> void:
	scale = Vector2(base_scale * float(facing), base_scale)
	rotation = _lean_rotation
	position = Vector2(_lean_offset.x * float(facing), _lean_offset.y)


func pose_idle() -> void:
	_clear()


func pose_walk(phase: float) -> void:
	_clear()
	var c := cos(phase * TAU)
	var s := sin(phase * TAU)
	lead_hip.rotation = 0.34 * c
	rear_hip.rotation = -0.34 * c
	lead_knee.rotation = 0.62 * maxf(s, 0.0)
	rear_knee.rotation = -0.62 * maxf(-s, 0.0)
	lead_shoulder.rotation = -0.30 * c
	rear_shoulder.rotation = 0.30 * c
	lead_elbow.rotation = 0.28 * maxf(-c, 0.0)
	rear_elbow.rotation = -0.28 * maxf(c, 0.0)
	body.position = Vector2(0.0, 36.0 * absf(s))


func pose_squat(amount: float) -> void:
	_clear()
	_apply_squat(amount)


func pose_jump(amount: float) -> void:
	_clear()
	_apply_jump(amount)


func pose_attack(move_name: String, weight: float) -> void:
	_clear()
	var kind := _button(move_name)
	var normal := kind != move_name
	var low := normal and move_name.begins_with("2")
	var aerial := normal and move_name.begins_with("j")
	if low:
		_apply_squat(0.9)
	elif aerial:
		_apply_jump(1.0)
	var ext := _extension(weight)
	var snap := clampf(weight / 0.4, 0.0, 1.0)
	var extend := clampf((weight - 0.28) / 0.72, 0.0, 1.0)
	if kind == "LP":
		_jab(ext, 0.85)
	elif kind == "MP":
		_jab(ext, 1.15)
	elif kind == "HP":
		_cross(ext, 1.35)
	elif kind == "LK":
		_lead_kick(snap, extend, 0.9, false)
	elif kind == "MK":
		_lead_kick(snap, extend, 1.15, false)
	elif kind == "HK":
		_rear_kick(snap, extend, 1.2 if move_name == "6HK" else 1.0, move_name == "6HK")
	elif kind == "236P":
		_jab(ext, 1.35)
	elif kind == "623P":
		lead_shoulder.rotation = -1.25 * ext
		lead_elbow.rotation = -0.08 * ext
	elif kind == "360P" or kind == "throw":
		_both_arms(ext, 1.0)
	elif kind == "236236P":
		_both_arms(ext, 1.45)


func lean(rot: float, offset: Vector2) -> void:
	_lean_rotation = rot
	_lean_offset = offset


func pose_react(rot: float, offset: Vector2, knee: float) -> void:
	_clear()
	_lean_rotation = rot
	_lean_offset = offset
	lead_knee.rotation = knee
	rear_knee.rotation = -knee


func _apply_squat(amount: float) -> void:
	lead_knee.rotation = 0.7 * amount
	rear_knee.rotation = -0.7 * amount
	lead_hip.rotation = 0.18 * amount
	rear_hip.rotation = -0.18 * amount
	body.position = Vector2(0.0, 78.0 * amount)


func _apply_jump(amount: float) -> void:
	lead_hip.rotation = 0.32 * amount
	rear_hip.rotation = -0.32 * amount
	lead_knee.rotation = -0.2 * amount
	rear_knee.rotation = 0.2 * amount
	lead_shoulder.rotation = -0.2 * amount
	rear_shoulder.rotation = -0.2 * amount
	body.position = Vector2(0.0, -20.0 * amount)


func _jab(ext: float, reach: float) -> void:
	lead_shoulder.rotation = -0.85 * reach * ext
	lead_elbow.rotation = -0.18 * reach * ext
	rear_shoulder.rotation = 0.22 * ext


func _cross(ext: float, reach: float) -> void:
	rear_shoulder.rotation = -0.95 * reach * ext
	rear_elbow.rotation = -0.2 * reach * ext
	lead_shoulder.rotation = 0.18 * ext


func _both_arms(ext: float, reach: float) -> void:
	lead_shoulder.rotation = -0.9 * reach * ext
	rear_shoulder.rotation = -0.75 * reach * ext
	lead_elbow.rotation = -0.12 * reach * ext
	rear_elbow.rotation = -0.12 * reach * ext


func _lead_kick(snap: float, extend: float, reach: float, high: bool) -> void:
	var lift := 0.95 * reach if high else 0.7 * reach
	var base_knee := lead_knee.rotation
	lead_hip.rotation -= lift * snap
	lead_knee.rotation = base_knee + 0.55 * snap * (1.0 - extend) * reach
	rear_shoulder.rotation = -0.18 * snap
	lead_shoulder.rotation = 0.22 * snap


func _rear_kick(snap: float, extend: float, reach: float, high: bool) -> void:
	var lift := 0.9 * reach if high else 0.72 * reach
	var base_knee := rear_knee.rotation
	rear_hip.rotation -= lift * snap
	rear_knee.rotation = base_knee - 0.55 * snap * (1.0 - extend) * reach
	lead_shoulder.rotation = -0.18 * snap
	rear_shoulder.rotation = 0.2 * snap


func _button(move_name: String) -> String:
	if move_name == "6HK":
		return "HK"
	if move_name.length() >= 3:
		var head := move_name.substr(0, 1)
		var tail := move_name.substr(1)
		if (head == "j" or head == "2" or head == "5") and tail in ["LP", "MP", "HP", "LK", "MK", "HK"]:
			return tail
	return move_name


func _extension(weight: float) -> float:
	if weight < 0.22:
		return -0.35 * (weight / 0.22)
	return -0.35 + 1.35 * ((weight - 0.22) / 0.78)


func _clear() -> void:
	for bone_name in _bones.keys():
		(_bones[bone_name] as Node2D).rotation = 0.0
	if body:
		body.position = Vector2.ZERO
	_lean_rotation = 0.0
	_lean_offset = Vector2.ZERO


func _measure(source: Texture2D) -> void:
	_tex_size = source.get_size()
	_foot_y = _tex_size.y * 0.96
	var min_x := _tex_size.x * 0.08
	var max_x := _tex_size.x * 0.92
	var img := source.get_image()
	if img != null:
		var found := false
		for y in range(img.get_height() - 1, -1, -1):
			for x in range(0, img.get_width(), 3):
				if img.get_pixel(x, y).a > 0.12:
					_foot_y = float(y)
					found = true
					break
			if found:
				break
		min_x = _tex_size.x
		max_x = 0.0
		for y in range(0, img.get_height(), 2):
			for x in range(0, img.get_width(), 2):
				if img.get_pixel(x, y).a > 0.12:
					min_x = minf(min_x, float(x))
					max_x = maxf(max_x, float(x))
	_cx = (min_x + max_x) * 0.5
	_rest = Vector2(0.0, _tex_size.y * 0.5 - _foot_y)


func _local(pixel: Vector2) -> Vector2:
	return Vector2(pixel.x - _cx, pixel.y - _foot_y)


func _add_chain(parent: Node2D, character: String, folder: String, joint_name: String, bend_name: String, upper_part: String, lower_part: String, z: int) -> void:
	var joint_px: Vector2 = PIVOTS[character][joint_name]
	var bend_px: Vector2 = PIVOTS[character][bend_name]
	var joint := Node2D.new()
	joint.name = joint_name
	joint.z_index = z
	joint.position = _local(joint_px)
	parent.add_child(joint)
	_bones[joint_name] = joint
	var upper := _make_sprite(folder, upper_part)
	upper.position = _rest - _local(joint_px)
	joint.add_child(upper)
	var bend := Node2D.new()
	bend.name = bend_name
	bend.position = _local(bend_px) - _local(joint_px)
	joint.add_child(bend)
	_bones[bend_name] = bend
	var lower := _make_sprite(folder, lower_part)
	lower.position = _rest - _local(bend_px)
	bend.add_child(lower)


func _make_sprite(folder: String, part: String) -> Sprite2D:
	var spr := Sprite2D.new()
	spr.name = part
	spr.texture = load("res://assets/processed/%s/%s.png" % [folder, part])
	spr.centered = true
	spr.offset = Vector2(_tex_size.x * 0.5 - _cx, 0.0)
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	return spr
