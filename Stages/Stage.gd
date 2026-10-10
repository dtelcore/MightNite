extends Node2D

var floor_y := Constants.FLOOR_Y
var left_wall := -640.0
var right_wall := 640.0
var stage_data: StageData


func setup(data: StageData) -> void:
	add_to_group("stage")
	stage_data = data
	floor_y = Constants.FLOOR_Y
	var spr := Sprite2D.new()
	spr.name = "Background"
	spr.texture = data.texture
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	spr.z_index = -10
	var tex_h := float(data.texture.get_height())
	var tex_w := float(data.texture.get_width())
	var display_h := data.display_height
	var scale_factor := display_h / tex_h
	spr.scale = Vector2(scale_factor, scale_factor)
	spr.position = Vector2(0, floor_y + display_h * (0.5 - data.floor_ratio))
	add_child(spr)
	var display_w := tex_w * scale_factor
	left_wall = -display_w * 0.5 + data.wall_inset
	right_wall = display_w * 0.5 - data.wall_inset

	var floor := StaticBody2D.new()
	floor.collision_layer = Constants.LAYER_WORLD
	floor.collision_mask = 0
	var floor_shape := CollisionShape2D.new()
	var floor_rect := RectangleShape2D.new()
	floor_rect.size = Vector2(display_w + 400.0, 80.0)
	floor_shape.shape = floor_rect
	floor_shape.position = Vector2(0, 40)
	floor.position = Vector2(0, floor_y)
	floor.add_child(floor_shape)
	add_child(floor)
	_add_wall(left_wall - 20.0)
	_add_wall(right_wall + 20.0)


func _add_wall(x: float) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = Constants.LAYER_WORLD
	body.collision_mask = 0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(40, 900)
	shape.shape = rect
	body.position = Vector2(x, floor_y - 450.0)
	body.add_child(shape)
	add_child(body)
