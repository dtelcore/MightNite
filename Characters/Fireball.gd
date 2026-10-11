extends Area2D

var owner_fighter
var move: MoveData
var facing := 1
var life := 110


func setup(fighter, fired_move: MoveData) -> void:
	owner_fighter = fighter
	move = fired_move
	facing = fighter.facing
	add_to_group("projectile")
	monitoring = false
	monitorable = false
	z_index = 6
	if fighter.player_index == 0:
		collision_layer = Constants.LAYER_P1_HIT
		collision_mask = Constants.LAYER_P2_HURT
	else:
		collision_layer = Constants.LAYER_P2_HIT
		collision_mask = Constants.LAYER_P1_HURT
	var shape_node := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 22.0 * Constants.WORLD_SCALE
	shape_node.shape = shape
	add_child(shape_node)


func _physics_process(_delta: float) -> void:
	if not Net.should_step() or GameManager.is_frozen():
		return
	position.x += 13.5 * Constants.WORLD_SCALE * float(facing)
	life -= 1
	queue_redraw()
	var stages := get_tree().get_nodes_in_group("stage")
	if not stages.is_empty():
		var stage = stages[0]
		if global_position.x < stage.left_wall or global_position.x > stage.right_wall:
			queue_free()
			return
	if life <= 0:
		queue_free()
		return
	_try_hit()


func _try_hit() -> void:
	if owner_fighter == null or owner_fighter.opponent == null:
		return
	var victim = owner_fighter.opponent
	if not victim.has_method("hurt_world_rect") or not victim.has_method("receive_hit"):
		return
	var rect: Rect2 = victim.hurt_world_rect()
	if rect.size == Vector2.ZERO:
		return
	var radius := 22.0 * Constants.WORLD_SCALE
	if not _circle_hits(global_position, radius, rect):
		return
	if victim.receive_hit(owner_fighter, move):
		queue_free()


func _circle_hits(center: Vector2, radius: float, rect: Rect2) -> bool:
	var closest := Vector2(
		clampf(center.x, rect.position.x, rect.position.x + rect.size.x),
		clampf(center.y, rect.position.y, rect.position.y + rect.size.y)
	)
	return center.distance_squared_to(closest) <= radius * radius


func _draw() -> void:
	var s := Constants.WORLD_SCALE
	draw_circle(Vector2.ZERO, 20.0 * s, Color(1.0, 0.38, 0.1, 0.95))
	draw_circle(Vector2(-10.0 * s * float(facing), 0), 11.0 * s, Color(1.0, 0.86, 0.45, 0.95))
	if GameManager.debug:
		draw_arc(Vector2.ZERO, 22.0 * s, 0.0, TAU, 24, Color(1, 0.35, 0.2, 1), 2.0)
