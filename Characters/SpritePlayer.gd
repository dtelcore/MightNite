class_name SpritePlayer
extends Node2D

var clip_name := ""

var _sprite: Sprite2D
var _clips: Dictionary = {}
var _frame_size := Vector2(200, 200)
var _pixel_scale := 3.0
var _foot_y := 122.0
var _center_x := 100.0
var _sheet_faces_right := true
var _loop := true
var _stretch := false
var _fps := 8.0
var _time := 0.0
var _frame := 0
var _crouch := 0.0
var _body_height := 150.0


func setup(data: CharacterData) -> void:
	_frame_size = Vector2(data.frame_size)
	_pixel_scale = data.pixel_scale
	_foot_y = data.foot_y
	_center_x = data.frame_center_x
	_sheet_faces_right = data.sheet_faces_right
	_body_height = data.body_height
	_sprite = Sprite2D.new()
	_sprite.name = "Frames"
	_sprite.centered = true
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_sprite)
	for clip in ["idle", "combat_idle", "run", "jump", "fall", "attack", "attack_light", "attack_heavy", "kick", "hurt", "death", "recover", "block", "crouch_block"]:
		var path := "%s/%s.png" % [data.anim_folder, clip]
		if not ResourceLoader.exists(path):
			continue
		var tex: Texture2D = load(path)
		if tex == null:
			continue
		var frames := int(tex.get_width() / int(_frame_size.x))
		_clips[clip] = {"texture": tex, "frames": maxi(frames, 1), "bounds": _measure(tex, maxi(frames, 1))}
	if not _clips.has("idle") and _clips.has("combat_idle"):
		_clips["idle"] = _clips["combat_idle"]
	play("idle", true, 8.0)


func has_clip(clip: String) -> bool:
	return _clips.has(clip)


func visual_rect() -> Rect2:
	if _sprite == null or not _clips.has(clip_name):
		return Rect2()
	var boxes: Array = _clips[clip_name]["bounds"]
	if _frame < 0 or _frame >= boxes.size():
		return Rect2()
	var box: Rect2 = boxes[_frame]
	var fw := _frame_size.x
	var fh := _frame_size.y
	var left := _pixel_x(box.position.x)
	var right := _pixel_x(box.position.x + box.size.x)
	var top := _pixel_y(box.position.y)
	var bottom := _pixel_y(box.position.y + box.size.y)
	return Rect2(minf(left, right), minf(top, bottom), absf(right - left), absf(bottom - top))


func _pixel_x(pixel: float) -> float:
	var from_center := pixel - _frame_size.x * 0.5
	if _sprite.flip_h:
		from_center = -from_center
	return from_center * _pixel_scale + _sprite.position.x


func _pixel_y(pixel: float) -> float:
	return (pixel - _frame_size.y * 0.5) * _pixel_scale + _sprite.position.y


func _measure(tex: Texture2D, frames: int) -> Array:
	var image := tex.get_image()
	var fw := int(_frame_size.x)
	var fh := int(_frame_size.y)
	var boxes: Array = []
	for frame_index in frames:
		var min_x := fw
		var min_y := fh
		var max_x := 0
		var max_y := 0
		var found := false
		if image != null:
			for y in fh:
				for x in fw:
					if image.get_pixel(frame_index * fw + x, y).a < 0.08:
						continue
					found = true
					min_x = mini(min_x, x)
					min_y = mini(min_y, y)
					max_x = maxi(max_x, x + 1)
					max_y = maxi(max_y, y + 1)
		if not found:
			boxes.append(Rect2(0, 0, fw, fh))
		else:
			boxes.append(Rect2(min_x, min_y, max_x - min_x, max_y - min_y))
	return boxes


func play(clip: String, loop: bool, fps: float) -> void:
	if not _clips.has(clip):
		if clip == "fall" and _clips.has("jump"):
			clip = "jump"
		elif clip == "attack_light" and _clips.has("attack"):
			clip = "attack"
		elif clip == "attack_heavy" and _clips.has("attack"):
			clip = "attack"
		elif clip == "recover" and _clips.has("idle"):
			clip = "idle"
		else:
			return
	if clip_name == clip and _loop == loop and not _stretch:
		_fps = fps
		return
	clip_name = clip
	_loop = loop
	_stretch = false
	_fps = fps
	_time = 0.0
	_frame = 0
	_show_frame()


func play_ratio(clip: String, ratio: float) -> void:
	if not _clips.has(clip):
		if clip == "attack_light" and _clips.has("attack"):
			clip = "attack"
		elif clip == "attack_heavy" and _clips.has("attack"):
			clip = "attack"
		elif clip == "recover" and _clips.has("idle"):
			clip = "idle"
		elif clip == "fall" and _clips.has("jump"):
			clip = "jump"
		else:
			return
	var count: int = _clips[clip]["frames"]
	var index := clampi(int(round(clampf(ratio, 0.0, 1.0) * float(count - 1))), 0, count - 1)
	if clip_name != clip or not _stretch:
		clip_name = clip
		_stretch = true
		_loop = false
	_frame = index
	_show_frame()


func tick(delta: float) -> void:
	if _stretch or clip_name == "" or not _clips.has(clip_name):
		return
	var count: int = _clips[clip_name]["frames"]
	if count <= 1:
		return
	_time += delta
	var step := 1.0 / maxf(_fps, 1.0)
	while _time >= step:
		_time -= step
		if _frame + 1 >= count:
			if _loop:
				_frame = 0
			else:
				_frame = count - 1
				_time = 0.0
				break
		else:
			_frame += 1
	_show_frame()


func set_crouch(amount: float) -> void:
	_crouch = clampf(amount, 0.0, 1.0)


func apply_facing(facing: int) -> void:
	if _sprite == null:
		return
	var look_right := facing > 0
	_sprite.flip_h = look_right != _sheet_faces_right
	var shift := (_frame_size.x * 0.5 - _center_x) * _pixel_scale
	var foot := -(_foot_y - _frame_size.y * 0.5) * _pixel_scale
	var mirror := -1.0 if _sprite.flip_h else 1.0
	_sprite.position = Vector2(shift * mirror, foot + _body_height * 0.22 * _crouch)
	_sprite.scale = Vector2(_pixel_scale, _pixel_scale)


func _show_frame() -> void:
	if _sprite == null or not _clips.has(clip_name):
		return
	var info: Dictionary = _clips[clip_name]
	var tex: Texture2D = info["texture"]
	_sprite.texture = tex
	_sprite.region_enabled = true
	_sprite.region_rect = Rect2i(int(_frame * _frame_size.x), 0, int(_frame_size.x), int(_frame_size.y))
