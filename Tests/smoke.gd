extends SceneTree


func _initialize() -> void:
	_run()


func _run() -> void:
	var errors: Array[String] = []
	await process_frame
	var ryuji: CharacterData = load("res://Characters/Ryuji/Ryuji.tres")
	var titan: CharacterData = load("res://Characters/Titan/Titan.tres")
	if ryuji == null or ryuji.get_move("5LP") == null:
		errors.append("Ryuji 5LP missing")
	if ryuji == null or ryuji.get_move("236P") == null or not ryuji.get_move("236P").is_projectile:
		errors.append("Ryuji fireball missing")
	if titan == null or titan.get_move("360P") == null or not titan.get_move("360P").is_command_grab:
		errors.append("Titan command grab missing")
	if titan == null or titan.get_move("5HP") == null or not titan.get_move("5HP").armor:
		errors.append("Titan armor missing")
	for path in ["res://assets/processed/Ryuji.png", "res://assets/processed/Titan.png"]:
		var tex: Texture2D = load(path)
		var img := tex.get_image()
		if img.get_pixel(2, 2).a > 0.08:
			errors.append("checkerboard remains on %s" % path)
	for stage_path in ["res://Stages/dojo.tres", "res://Stages/shrine.tres", "res://Stages/neon.tres", "res://Stages/dock.tres", "res://Stages/pit.tres"]:
		var stage = load(stage_path)
		if stage == null or stage.texture == null:
			errors.append("stage missing %s" % stage_path)
	var menu = load("res://Scenes/MainMenu.tscn").instantiate()
	root.add_child(menu)
	await process_frame
	menu.queue_free()
	var select = load("res://Scenes/CharacterSelect.tscn").instantiate()
	root.add_child(select)
	await process_frame
	select.queue_free()

	var gm := root.get_node("GameManager")
	gm.set("p1_data", ryuji)
	gm.set("p2_data", titan)
	gm.set("stage", load("res://Stages/dojo.tres"))
	var match = load("res://Scenes/Match.tscn").instantiate()
	root.add_child(match)
	for _i in 40:
		await physics_frame
	var p1 = match.get_node_or_null("P1")
	var p2 = match.get_node_or_null("P2")
	if p1 == null or p2 == null:
		errors.append("fighters did not spawn")
		_finish(errors)
		return
	if not p1.is_on_floor() or not p2.is_on_floor():
		errors.append("fighters not grounded p1=%s p2=%s" % [p1.global_position, p2.global_position])
	p1.locked = false
	p2.locked = false
	var floor_y: float = match.stage.floor_y
	p1.full_reset(-20, floor_y)
	p2.full_reset(55, floor_y)
	p1.facing = 1
	p2.facing = -1
	var before: int = p2.hp.current
	if not p1.start_move("5LP"):
		errors.append("could not start 5LP")
	for _i in 35:
		await physics_frame
	if p2.hp.current >= before:
		errors.append("5LP dealt no damage hp=%s state=%s" % [p2.hp.current, p2.machine.state_name()])

	p1.full_reset(-10, floor_y)
	p2.full_reset(58, floor_y)
	p1.facing = 1
	p2.facing = -1
	p1.locked = false
	p2.locked = false
	p2.was_blocked = false
	p2.forced_sample = {"dir": Vector2i(1, 0), "pressed": {"lp": false, "mp": false, "hp": false, "lk": false, "mk": false, "hk": false}}
	var blocked_hp: int = p2.hp.current
	p1.start_move("5LP")
	var saw_block := false
	for _i in 30:
		await physics_frame
		if p2.was_blocked or p2.machine.state_name() == "Block":
			saw_block = true
	if not saw_block:
		errors.append("block did not trigger, state=%s" % p2.machine.state_name())
	if p2.hp.current != blocked_hp:
		errors.append("blocked normal changed health %s -> %s" % [blocked_hp, p2.hp.current])
	p2.forced_sample = {}

	p1.full_reset(-240, floor_y)
	p2.full_reset(260, floor_y)
	p1.facing = 1
	p1.locked = false
	p1.start_move("236P")
	var spawned := false
	for _i in 40:
		await physics_frame
		if not get_nodes_in_group("projectile").is_empty():
			spawned = true
	if not spawned:
		errors.append("fireball did not spawn")

	_check_rig(p1, "Ryuji", errors)
	_check_rig(p2, "Titan", errors)
	_finish(errors)


func _check_rig(fighter, who: String, errors: Array[String]) -> void:
	var rig = fighter.rig
	if rig == null or rig.lead_shoulder == null or rig.lead_knee == null:
		errors.append("%s rig missing" % who)
		return
	if rig.get_child_count() < 3:
		errors.append("%s rig has no parts" % who)
		return
	fighter.pose_walk(0.15, false)
	if fighter.rig.lead_knee.rotation < 0.4:
		errors.append("%s walk did not lift the lead knee" % who)
	if fighter.rig.lead_shoulder.rotation > -0.05 or fighter.rig.rear_hip.rotation > -0.05:
		errors.append("%s walk did not swing the opposite limbs" % who)
	fighter.pose_squat(1.0)
	if fighter.rig.lead_knee.rotation < 0.5 or fighter.rig.rear_knee.rotation > -0.5:
		errors.append("%s squat did not bend both knees" % who)
	fighter.pose_jump(1.0)
	if fighter.rig.lead_knee.rotation >= 0.0 or fighter.rig.rear_knee.rotation <= 0.0:
		errors.append("%s jump did not straighten the legs" % who)
	fighter.pose_attack(fighter.data.get_move("5LP"), 8)
	if fighter.rig.lead_shoulder.rotation >= -0.3:
		errors.append("%s punch did not extend the lead arm" % who)
	fighter.pose_attack(fighter.data.get_move("5HP"), 12)
	if fighter.rig.rear_shoulder.rotation >= -0.3:
		errors.append("%s heavy punch did not swing the rear arm" % who)
	fighter.pose_attack(fighter.data.get_move("5LK"), 2)
	if fighter.rig.lead_knee.rotation < 0.15:
		errors.append("%s kick did not bend the lead knee" % who)
	fighter.pose_attack(fighter.data.get_move("5LK"), 14)
	if fighter.rig.lead_hip.rotation >= -0.2:
		errors.append("%s kick did not swing the lead leg" % who)
	fighter.rig.pose_attack("2LP", 1.0)
	if fighter.rig.rear_knee.rotation > -0.4 or fighter.rig.lead_shoulder.rotation >= -0.3:
		errors.append("%s crouch punch did not keep the squat and swing the lead arm" % who)
	fighter.rig.pose_attack("jLK", 1.0)
	if fighter.rig.rear_knee.rotation <= 0.0 or fighter.rig.lead_hip.rotation >= -0.2:
		errors.append("%s air kick did not keep one leg straight and extend the other" % who)
	fighter.rig.pose_attack("236P", 1.0)
	if fighter.rig.lead_shoulder.rotation >= -0.5 or fighter.rig.rear_knee.rotation < -0.2:
		errors.append("%s fireball crouched or did not thrust the lead arm" % who)
	fighter.rig.pose_attack("623P", 1.0)
	if fighter.rig.lead_shoulder.rotation >= -0.8:
		errors.append("%s uppercut did not raise the lead arm" % who)
	fighter.rig.pose_attack("6HK", 0.5)
	if fighter.rig.rear_hip.rotation >= -0.4:
		errors.append("%s heavy kick did not swing the rear leg" % who)
	fighter.rig.pose_attack("throw", 1.0)
	if fighter.rig.lead_shoulder.rotation >= -0.4 or fighter.rig.rear_shoulder.rotation >= -0.3:
		errors.append("%s throw did not reach with both arms" % who)
	fighter.pose_idle()


func _finish(errors: Array[String]) -> void:
	if errors.is_empty():
		print("SMOKE_OK")
		quit(0)
	else:
		for err in errors:
			push_error(err)
			print("SMOKE_FAIL ", err)
		quit(1)
