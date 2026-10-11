class_name CharacterBase
extends CharacterBody2D

signal health_changed(current: int, maximum: int)

@export var data: CharacterData
@export var player_index: int = 0

var facing := 1
var opponent = null
var locked := false
var invulnerable := false
var armor_active := false
var armor_hits_left := 0
var crouch_block := false
var air_action_used := false
var motion_locked := false
var combo_count := 0
var was_blocked := false
var attack_move: MoveData
var attack_frame := 0
var hit_connected := false
var anim_offset := Vector2.ZERO
var anim_rotation := 0.0
var anim_scale := Vector2.ONE
var flash := 0
var walk_phase := 0.0
var forced_sample: Dictionary = {}

var hp: HealthSystem
var buffer: InputBuffer
var machine: StateMachine
var anim: SpritePlayer
var hurtbox: Area2D
var hitbox: Area2D
var hit_shape: CollisionShape2D
var hurt_shape: CollisionShape2D
var _crouch_hurt := false


func _ready() -> void:
	add_to_group("fighter")
	motion_mode = MOTION_MODE_GROUNDED
	floor_snap_length = 10.0
	floor_max_angle = deg_to_rad(45.0)
	collision_layer = 0
	collision_mask = Constants.LAYER_WORLD
	if data == null:
		push_error("Fighter is missing CharacterData")
		return
	_ensure_moves()
	hp = HealthSystem.new()
	hp.name = "Health"
	add_child(hp)
	hp.setup(data.max_health)

	anim = SpritePlayer.new()
	anim.name = "Anim"
	add_child(anim)
	anim.setup(data)

	var body_shape := CollisionShape2D.new()
	var body := RectangleShape2D.new()
	body.size = Vector2(data.body_width * 0.45, data.body_height * 0.9)
	body_shape.shape = body
	body_shape.position = Vector2(0, -body.size.y * 0.5)
	add_child(body_shape)

	hurtbox = Area2D.new()
	hurtbox.name = "Hurtbox"
	hurtbox.monitoring = false
	hurtbox.monitorable = true
	add_child(hurtbox)
	hurt_shape = CollisionShape2D.new()
	hurtbox.add_child(hurt_shape)
	set_crouching(false)

	hitbox = Area2D.new()
	hitbox.name = "Hitbox"
	hitbox.monitoring = true
	hitbox.monitorable = false
	add_child(hitbox)
	hit_shape = CollisionShape2D.new()
	hit_shape.disabled = true
	hitbox.add_child(hit_shape)
	hitbox.area_entered.connect(_on_hitbox_area_entered)
	_apply_layers()

	buffer = InputBuffer.new()
	buffer.name = "InputBuffer"
	add_child(buffer)

	machine = StateMachine.new()
	machine.name = "StateMachine"
	add_child(machine)
	machine.setup(self)
	health_changed.emit(hp.current, hp.maximum)
	queue_redraw()


func _ensure_moves() -> void:
	if data == null or not data.all_moves().is_empty():
		return
	var folder := "res://Characters/%s/moves" % data.character_name
	var dir := DirAccess.open(folder)
	if dir == null:
		return
	var files := dir.get_files()
	files.sort()
	for file in files:
		if not file.ends_with(".tres"):
			continue
		var move = load("%s/%s" % [folder, file])
		if not (move is MoveData):
			continue
		if move.input == "236236P":
			data.supers.append(move)
		elif move.input in ["236P", "623P", "360P", "throw"]:
			data.specials.append(move)
		else:
			data.moves.append(move)


func _apply_layers() -> void:
	if player_index == 0:
		hurtbox.collision_layer = Constants.LAYER_P1_HURT
		hurtbox.collision_mask = 0
		hitbox.collision_layer = Constants.LAYER_P1_HIT
		hitbox.collision_mask = Constants.LAYER_P2_HURT
	else:
		hurtbox.collision_layer = Constants.LAYER_P2_HURT
		hurtbox.collision_mask = 0
		hitbox.collision_layer = Constants.LAYER_P2_HIT
		hitbox.collision_mask = Constants.LAYER_P1_HURT


func _physics_process(delta: float) -> void:
	if GameManager.is_frozen():
		_update_visual()
		queue_redraw()
		return
	if buffer != null:
		buffer.facing = facing
		var sample: Dictionary = forced_sample if not forced_sample.is_empty() else InputManager.sample(player_index)
		buffer.capture(sample)
	if machine:
		machine.physics_update(delta)
	_integrate(delta)
	if anim:
		anim.tick(delta)
	_update_visual()
	queue_redraw()


func _integrate(delta: float) -> void:
	if motion_locked:
		velocity = Vector2.ZERO
		return
	if not is_on_floor():
		velocity.y += Constants.GRAVITY * delta
	elif velocity.y > 0.0:
		velocity.y = 30.0
	move_and_slide()
	_separate()
	_clamp_stage()


func _separate() -> void:
	if opponent == null or player_index != 0 or data == null or opponent.data == null:
		return
	if absf(global_position.y - opponent.global_position.y) > 100.0:
		return
	var min_dist: float = (data.body_width + opponent.data.body_width) * 0.42
	var dx: float = global_position.x - opponent.global_position.x
	if absf(dx) >= min_dist:
		return
	var push: float = (min_dist - absf(dx)) * 0.5
	var dir := 1.0 if dx >= 0.0 else -1.0
	global_position.x += dir * push
	opponent.global_position.x -= dir * push


func _clamp_stage() -> void:
	var stages := get_tree().get_nodes_in_group("stage")
	if stages.is_empty():
		return
	var stage = stages[0]
	global_position.x = clampf(global_position.x, stage.left_wall + 40.0, stage.right_wall - 40.0)


func _update_visual() -> void:
	if anim == null:
		return
	anim.apply_facing(facing)
	if flash > 0:
		anim.modulate = Color(1.6, 0.7, 0.7)
		flash -= 1
	else:
		anim.modulate = Color.WHITE


func _draw() -> void:
	if data == null:
		return
	var shadow := PackedVector2Array()
	for i in 14:
		var angle := TAU * float(i) / 14.0
		shadow.append(Vector2(cos(angle) * data.body_width * 0.55, sin(angle) * 8.0 - 2.0))
	draw_colored_polygon(shadow, Color(0, 0, 0, 0.38))
	if not GameManager.debug or hurt_shape == null or hurt_shape.shape == null:
		return
	var sz: Vector2 = hurt_shape.shape.size
	draw_rect(Rect2(hurt_shape.position - sz * 0.5, sz), Color(0.2, 1, 0.35, 0.28), false, 2.0)
	if hit_shape and hit_shape.shape and not hit_shape.disabled:
		var hsz: Vector2 = hit_shape.shape.size
		draw_rect(Rect2(hit_shape.position - hsz * 0.5, hsz), Color(1, 0.15, 0.15, 0.45), true)
	draw_string(ThemeDB.fallback_font, Vector2(-50, -data.body_height - 18), machine.state_name() if machine else "", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)


func set_crouching(on: bool) -> void:
	if data == null or hurt_shape == null:
		return
	_crouch_hurt = on
	if Engine.is_in_physics_frame():
		call_deferred("_apply_hurtbox")
	else:
		_apply_hurtbox()


func _apply_hurtbox() -> void:
	if data == null or hurt_shape == null:
		return
	var height := data.body_height * (0.6 if _crouch_hurt else 1.0)
	var shape := RectangleShape2D.new()
	shape.size = Vector2(data.body_width * 0.72, height)
	hurt_shape.shape = shape
	hurt_shape.position = Vector2(0, -height * 0.5)


func face_opponent() -> void:
	if opponent == null:
		return
	var dx: float = opponent.global_position.x - global_position.x
	if absf(dx) > 1.0:
		facing = 1 if dx > 0.0 else -1


func holding_back() -> bool:
	return buffer != null and buffer.held_dir.x * facing < 0


func holding_down() -> bool:
	return buffer != null and buffer.held_dir.y > 0


func reset_pose() -> void:
	anim_offset = Vector2.ZERO
	anim_rotation = 0.0
	anim_scale = Vector2.ONE
	walk_phase = 0.0
	if anim:
		anim.set_crouch(0.0)
		anim.play("idle", true, 8.0)


func desired_move() -> String:
	if locked or data == null:
		return ""
	var punch := buffer.pressed_within(["lp", "mp", "hp"])
	if is_on_floor() and punch:
		if data.get_move("236236P") and (buffer.matches([2, 3, 6, 2, 3, 6], 24) or buffer.matches([2, 6, 2, 6], 24)):
			return "236236P"
		if data.get_move("360P") and buffer.has_360():
			return "360P"
		if data.get_move("623P") and (buffer.matches([6, 2, 3]) or buffer.matches([6, 2, 6])):
			return "623P"
		if data.get_move("236P") and (buffer.matches([2, 3, 6]) or buffer.matches([2, 6])):
			return "236P"
	if is_on_floor() and buffer.pressed_within(["lp"]) and buffer.pressed_within(["lk"]) and data.get_move("throw"):
		return "throw"
	return _normal_id()


func _normal_id() -> String:
	var button := buffer.first_pressed(["hp", "mp", "lp", "hk", "mk", "lk"])
	if button == "":
		return ""
	var strength: String = {"lp": "LP", "mp": "MP", "hp": "HP", "lk": "LK", "mk": "MK", "hk": "HK"}[button]
	if not is_on_floor():
		if air_action_used:
			return ""
		return "j" + strength
	var rel := buffer.relative_held()
	if rel.y > 0 or (machine != null and machine.state_name() == "Crouch"):
		return "2" + strength
	if button == "hk" and rel.x > 0 and data.get_move("6HK"):
		return "6HK"
	return "5" + strength


func try_offense() -> bool:
	var id := desired_move()
	if id == "":
		return false
	if start_move(id):
		if not is_on_floor():
			air_action_used = true
		buffer.consume_buttons()
		return true
	return false


func try_cancel(current: MoveData) -> bool:
	var id := desired_move()
	if id == "" or current == null or id == current.move_name:
		return false
	if current.cancel_into.find(id) < 0:
		return false
	if start_move(id):
		buffer.consume_buttons()
		return true
	return false


func start_move(id: String) -> bool:
	if data == null:
		return false
	var move := data.get_move(id)
	if move == null:
		return false
	machine.change_state("Attack", {"move": move})
	return true


func enable_hitbox(rect: Rect2) -> void:
	var scaled := Rect2(rect.position * Constants.WORLD_SCALE, rect.size * Constants.WORLD_SCALE)
	var shape := RectangleShape2D.new()
	shape.size = scaled.size
	hit_shape.shape = shape
	hit_shape.position = Vector2((scaled.position.x + scaled.size.x * 0.5) * facing, scaled.position.y + scaled.size.y * 0.5)
	hit_shape.disabled = false
	hit_connected = false


func disable_hitbox() -> void:
	if hit_shape == null:
		return
	if Engine.is_in_physics_frame():
		hit_shape.set_deferred("disabled", true)
	else:
		hit_shape.disabled = true


func poll_hitbox() -> void:
	if hit_connected or hit_shape == null or hit_shape.disabled:
		return
	for area in hitbox.get_overlapping_areas():
		_on_hitbox_area_entered(area)
		if hit_connected:
			return


func _on_hitbox_area_entered(area: Area2D) -> void:
	if hit_connected or hit_shape == null or hit_shape.disabled:
		return
	var victim = area.get_parent()
	if victim == self or not victim.has_method("receive_hit"):
		return
	if victim.receive_hit(self, attack_move):
		hit_connected = true


func receive_hit(attacker, move: MoveData) -> bool:
	if invulnerable or locked or move == null:
		return false
	var state := machine.state_name() if machine else ""
	if state in ["Throw", "Thrown", "Getup"]:
		return false
	if move.is_throw or move.is_command_grab:
		_begin_throw(attacker, move)
		return true
	if HitboxSystem.blocked(self, move):
		was_blocked = true
		if move.chip_damage > 0:
			hp.apply(move.chip_damage, false)
			health_changed.emit(hp.current, hp.maximum)
		if attacker != null:
			attacker.combo_count = 0
		machine.change_state("Block", {"move": move, "attacker": attacker})
		GameManager.trigger_hitstop(maxi(2, move.hitstop_frames - 2))
		_contact_fx(attacker, move, true)
		return true
	if armor_active and armor_hits_left > 0:
		armor_hits_left -= 1
		if armor_hits_left <= 0:
			armor_active = false
		hp.apply(maxi(1, int(move.damage * 0.5)))
		flash = 4
		health_changed.emit(hp.current, hp.maximum)
		GameManager.trigger_hitstop(3)
		_contact_fx(attacker, move, false)
		return true
	var hits_before := 0
	if attacker != null:
		hits_before = attacker.combo_count
	var scale := move.scaling
	if hits_before >= 3:
		scale *= pow(0.9, float(hits_before - 2))
	hp.apply(maxi(1, int(round(float(move.damage) * scale))))
	if attacker != null:
		attacker.combo_count = hits_before + 1
	flash = 6
	health_changed.emit(hp.current, hp.maximum)
	GameManager.trigger_hitstop(move.hitstop_frames)
	var launched := move.launch_force > 0.0 or not is_on_floor()
	machine.change_state("Hitstun", {"move": move, "attacker": attacker, "launched": launched})
	_contact_fx(attacker, move, false)
	return true


func _begin_throw(attacker, move: MoveData) -> void:
	var hits_before: int = attacker.combo_count if attacker != null else 0
	hp.apply(move.damage)
	if attacker != null:
		attacker.combo_count = hits_before + 1
	health_changed.emit(hp.current, hp.maximum)
	GameManager.trigger_hitstop(move.hitstop_frames)
	if attacker != null:
		attacker.machine.change_state("Throw", {"victim": self, "move": move})
	machine.change_state("Thrown", {"attacker": attacker, "move": move})
	_contact_fx(attacker, move, false)


func _contact_fx(attacker, move: MoveData, blocked: bool) -> void:
	var nodes := get_tree().get_nodes_in_group("combat")
	if nodes.is_empty():
		return
	var pos := global_position + Vector2(float(facing) * 30.0 * Constants.WORLD_SCALE, -data.body_height * 0.55)
	var facing_dir: int = attacker.facing if attacker != null else facing
	nodes[0].on_contact(pos, facing_dir, blocked, move)


func spawn_fireball(move: MoveData) -> void:
	var fb = preload("res://Characters/Fireball.gd").new()
	fb.setup(self, move)
	get_parent().add_child(fb)
	fb.global_position = global_position + Vector2(float(facing) * 78.0 * Constants.WORLD_SCALE, -data.body_height * 0.45)


func pose_idle() -> void:
	reset_pose()


func pose_walk(_phase: float, back: bool) -> void:
	if anim == null:
		return
	anim.set_crouch(0.0)
	anim.play("run", true, 9.0 if back else 12.0)


func pose_crouch() -> void:
	pose_squat(1.0)


func pose_squat(amount: float) -> void:
	if anim == null:
		return
	anim.play("idle", true, 8.0)
	anim.set_crouch(amount)


func pose_jump(amount: float) -> void:
	if anim == null:
		return
	anim.set_crouch(0.0)
	if amount < 0.6 and anim.has_clip("fall"):
		anim.play("fall", true, 6.0)
	else:
		anim.play("jump", false, 8.0)


func pose_attack(move: MoveData, frame: int) -> void:
	if move == null or anim == null:
		return
	var total := maxi(move.startup + move.active + move.recovery, 1)
	var low := move.move_name.begins_with("2") and move.move_name.length() <= 3
	anim.set_crouch(1.0 if low else 0.0)
	anim.play_ratio(_attack_clip(move.move_name), clampf(float(frame) / float(total), 0.0, 1.0))


func pose_hit() -> void:
	if anim:
		anim.set_crouch(0.0)
		anim.play("hurt", false, 10.0)


func pose_block() -> void:
	if anim:
		anim.set_crouch(0.0)
		anim.play("idle", true, 8.0)


func pose_knockdown() -> void:
	if anim:
		anim.set_crouch(0.0)
		anim.play("death", false, 10.0)


func pose_getup(t: float) -> void:
	if anim == null:
		return
	anim.set_crouch(0.0)
	if anim.has_clip("recover"):
		anim.play_ratio("recover", t)
	else:
		anim.play("idle", true, 8.0)


func pose_dash(back: bool) -> void:
	if anim == null:
		return
	anim.set_crouch(0.0)
	anim.play("run", true, 10.0 if back else 16.0)


func pose_throw(heavy: bool) -> void:
	if anim == null:
		return
	anim.set_crouch(0.0)
	anim.play_ratio(_attack_clip("236236P" if heavy else "throw"), 1.0)


func pose_thrown(_wobble: float) -> void:
	if anim:
		anim.set_crouch(0.0)
		anim.play("hurt", false, 10.0)


func _attack_clip(move_name: String) -> String:
	var heavy := move_name in ["236P", "623P", "360P", "throw", "236236P", "6HK"]
	if not heavy and move_name.length() > 2:
		var tail := move_name.substr(1)
		if tail in ["HP", "HK"]:
			heavy = true
	if heavy and anim.has_clip("attack_heavy"):
		return "attack_heavy"
	if anim.has_clip("attack_light"):
		return "attack_light"
	return "attack"


func full_reset(x: float, floor_y: float) -> void:
	hp.setup(data.max_health)
	health_changed.emit(hp.current, hp.maximum)
	global_position = Vector2(x, floor_y)
	velocity = Vector2.ZERO
	invulnerable = false
	armor_active = false
	locked = false
	combo_count = 0
	air_action_used = false
	motion_locked = false
	was_blocked = false
	flash = 0
	disable_hitbox()
	reset_pose()
	set_crouching(false)
	if machine:
		machine.change_state("Idle")
