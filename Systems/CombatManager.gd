class_name CombatManager
extends Node

var camera: Camera2D
var shake := 0.0


func _ready() -> void:
	add_to_group("combat")


func on_contact(world_pos: Vector2, facing: int, blocked: bool, move: MoveData) -> void:
	var sparks := CPUParticles2D.new()
	sparks.one_shot = true
	sparks.explosiveness = 0.95
	sparks.amount = 10 if blocked else 18
	sparks.lifetime = 0.28
	sparks.emitting = false
	sparks.direction = Vector2(float(facing), -0.35)
	sparks.spread = 38.0
	sparks.initial_velocity_min = 80.0 * Constants.WORLD_SCALE
	sparks.initial_velocity_max = 240.0 * Constants.WORLD_SCALE
	sparks.gravity = Vector2(0, 460.0 * Constants.WORLD_SCALE)
	sparks.scale_amount_min = 2.5
	sparks.scale_amount_max = 6.0
	var heavy := move != null and (move.damage >= 80 or move.launch_force > 0.0)
	var super_move := move != null and move.input == "236236P"
	if blocked:
		sparks.color = Color(0.62, 0.86, 1.0)
		shake = maxf(shake, 3.5 * Constants.WORLD_SCALE)
		GameManager.play_sfx("block")
	else:
		sparks.color = Color(1.0, 0.38, 0.14) if heavy else Color(1.0, 0.78, 0.32)
		shake = maxf(shake, (18.0 if super_move else (9.0 if heavy else 5.0)) * Constants.WORLD_SCALE)
		GameManager.play_sfx("hit" if not super_move else "super")
	sparks.global_position = world_pos
	sparks.z_index = 8
	add_child(sparks)
	sparks.emitting = true
	var timer := get_tree().create_timer(0.45)
	timer.timeout.connect(func() -> void:
		if is_instance_valid(sparks):
			sparks.queue_free()
	)
	if super_move:
		_flash()


func _flash() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 30
	var rect := ColorRect.new()
	rect.color = Color(1, 1, 1, 0.72)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(rect)
	add_child(layer)
	var tween := create_tween()
	tween.tween_property(rect, "color:a", 0.0, 0.22)
	tween.finished.connect(layer.queue_free)


func _process(delta: float) -> void:
	if camera == null:
		return
	if shake > 0.15:
		camera.offset = Vector2(randf_range(-shake, shake), randf_range(-shake, shake))
		shake = move_toward(shake, 0.0, delta * 60.0)
	else:
		shake = 0.0
		camera.offset = Vector2.ZERO
