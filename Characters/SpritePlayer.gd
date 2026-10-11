class_name SpritePlayer
extends Node2D

var clip_name := ""

var _sprite: Sprite2D
var _clips: Dictionary = {}
var _frame_size := Vector2(200, 200)
var _pixel_scale := 3.0
var _foot_y := 122.0
var _center_x := 100.0
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
	_body_height = data.body_height
	_sprite = Sprite2D.new()
	_sprite.name = "Frames"
	_sprite.centered = true
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_sprite)
	for clip in ["idle", "combat_idle", "run", "jump", "fall", "attack", "attack_light", "attack_heavy", "hurt", "death", "recover"]:
		var path := "%s/%s.png" % [data.anim_folder, clip]
		if not ResourceLoader.exists(path):
			continue
		var tex: Texture2D = load(path)
		if tex == null:
			continue
		var frames := int(tex.get_width() / int(_frame_size.x))
		_clips[clip] = {"texture": tex, "frames": maxi(frames, 1)}
	if not _clips.has("idle") and _clips.has("combat_idle"):
		_clips["idle"] = _clips["combat_idle"]
	play("idle", true, 8.0)


func has_clip(clip: String) -> bool:
	return _clips.has(clip)


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
	_sprite.flip_h = facing < 0
	var shift := (_frame_size.x * 0.5 - _center_x) * _pixel_scale
	var foot := -(_foot_y - _frame_size.y * 0.5) * _pixel_scale
	_sprite.position = Vector2(shift * float(facing), foot + _body_height * 0.22 * _crouch)
	_sprite.scale = Vector2(_pixel_scale, _pixel_scale)


func _show_frame() -> void:
	if _sprite == null or not _clips.has(clip_name):
		return
	var info: Dictionary = _clips[clip_name]
	var tex: Texture2D = info["texture"]
	_sprite.texture = tex
	_sprite.region_enabled = true
	_sprite.region_rect = Rect2i(int(_frame * _frame_size.x), 0, int(_frame_size.x), int(_frame_size.y))
