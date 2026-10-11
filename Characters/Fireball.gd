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
	monitoring = true
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
	area_entered.connect(_on_area_entered)


func _physics_process(_delta: float) -> void:
	if GameManager.is_frozen():
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


func _on_area_entered(area: Area2D) -> void:
	var victim = area.get_parent()
	if victim == owner_fighter or victim == null:
		return
	if victim.has_method("receive_hit") and victim.receive_hit(owner_fighter, move):
		queue_free()


func _draw() -> void:
	var s := Constants.WORLD_SCALE
	draw_circle(Vector2.ZERO, 20.0 * s, Color(1.0, 0.38, 0.1, 0.95))
	draw_circle(Vector2(-10.0 * s * float(facing), 0), 11.0 * s, Color(1.0, 0.86, 0.45, 0.95))
