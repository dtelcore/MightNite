extends SceneTree


func _initialize() -> void:
	_run()


func _run() -> void:
	var errors: Array[String] = []
	await process_frame
	var hero: CharacterData = load("res://Characters/MartialHero/MartialHero.tres")
	var light: CharacterData = load("res://Characters/LightBandit/LightBandit.tres")
	var heavy: CharacterData = load("res://Characters/HeavyBandit/HeavyBandit.tres")
	if hero == null or hero.get_move("5LP") == null:
		errors.append("Martial Hero 5LP missing")
	if hero == null or hero.get_move("236P") == null or not hero.get_move("236P").is_projectile:
		errors.append("Martial Hero fireball missing")
	if heavy == null or heavy.get_move("360P") == null or not heavy.get_move("360P").is_command_grab:
		errors.append("Heavy Bandit command grab missing")
	if heavy == null or heavy.get_move("5HP") == null or not heavy.get_move("5HP").armor:
		errors.append("Heavy Bandit armor missing")
	if light == null or light.get_move("5LP") == null:
		errors.append("Light Bandit 5LP missing")
	if light != null and light.get_move("236P") != null:
		errors.append("Light Bandit should not have a fireball")
	if light != null and light.get_move("5HP") != null and light.get_move("5HP").armor:
		errors.append("Light Bandit should not have armor")
	for path in ["res://assets/fighters/martial_hero/idle.png", "res://assets/fighters/light_bandit/idle.png", "res://assets/fighters/heavy_bandit/idle.png"]:
		var tex: Texture2D = load(path)
		var img := tex.get_image()
		if img.get_pixel(1, 1).a > 0.08:
			errors.append("sprite sheet corner is opaque on %s" % path)
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
	gm.set("p1_data", hero)
	gm.set("p2_data", heavy)
	gm.set("stage", load("res://Stages/dojo.tres"))
	var fight = load("res://Scenes/Match.tscn").instantiate()
	root.add_child(fight)
	for _i in 40:
		await physics_frame
	var p1 = fight.get_node_or_null("P1")
	var p2 = fight.get_node_or_null("P2")
	if p1 == null or p2 == null:
		errors.append("fighters did not spawn")
		_finish(errors)
		return
	if not p1.is_on_floor() or not p2.is_on_floor():
		errors.append("fighters not grounded p1=%s p2=%s" % [p1.global_position, p2.global_position])
	p1.anim.apply_facing(1)
	p2.anim.apply_facing(-1)
	if p1.anim.get_node("Frames").flip_h or p2.anim.get_node("Frames").flip_h:
		errors.append("fighters are not facing each other")
	p1.anim.apply_facing(-1)
	p2.anim.apply_facing(1)
	if not p1.anim.get_node("Frames").flip_h or not p2.anim.get_node("Frames").flip_h:
		errors.append("fighters did not turn around")
	if p1.buffer.dash_tapped(true) or p2.buffer.dash_tapped(true) or p1.buffer.dash_tapped(false) or p2.buffer.dash_tapped(false):
		errors.append("dash triggered with no input")
	p1.locked = false
	p2.locked = false
	var floor_y: float = fight.stage.floor_y
	var scale := Constants.WORLD_SCALE
	p1.full_reset(-20.0 * scale, floor_y)
	p2.full_reset(55.0 * scale, floor_y)
	p1.facing = 1
	p2.facing = -1
	var before: int = p2.hp.current
	if not p1.start_move("5LP"):
		errors.append("could not start 5LP")
	for _i in 35:
		await physics_frame
	if p2.hp.current >= before:
		errors.append("5LP dealt no damage hp=%s state=%s" % [p2.hp.current, p2.machine.state_name()])

	p1.full_reset(-10.0 * scale, floor_y)
	p2.full_reset(58.0 * scale, floor_y)
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

	p1.full_reset(-240.0 * scale, floor_y)
	p2.full_reset(260.0 * scale, floor_y)
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

	_check_clips(p1, "Martial Hero", errors)
	_check_clips(p2, "Heavy Bandit", errors)
	var light_fighter = load("res://Characters/CharacterBase.tscn").instantiate()
	light_fighter.data = light
	light_fighter.position = Vector2(0, floor_y)
	fight.add_child(light_fighter)
	await physics_frame
	_check_clips(light_fighter, "Light Bandit", errors)
	_finish(errors)


func _check_clips(fighter, who: String, errors: Array[String]) -> void:
	var anim = fighter.anim
	if anim == null:
		errors.append("%s sprite player missing" % who)
		return
	fighter.pose_idle()
	anim.apply_facing(1)
	if anim.clip_name != "idle":
		errors.append("%s idle clip is %s" % [who, anim.clip_name])
	var frames = anim.get_node("Frames")
	var standing_y: float = frames.position.y
	fighter.pose_walk(0.2, false)
	if anim.clip_name != "run":
		errors.append("%s walk clip is %s" % [who, anim.clip_name])
	fighter.pose_jump(1.0)
	if anim.clip_name != "jump":
		errors.append("%s jump clip is %s" % [who, anim.clip_name])
	fighter.pose_jump(0.4)
	var fall_clip := "fall" if anim.has_clip("fall") else "jump"
	if anim.clip_name != fall_clip:
		errors.append("%s fall clip is %s" % [who, anim.clip_name])
	fighter.pose_attack(fighter.data.get_move("5LP"), 4)
	var light_clip := "attack_light" if anim.has_clip("attack_light") else "attack"
	if anim.clip_name != light_clip:
		errors.append("%s light attack clip is %s" % [who, anim.clip_name])
	fighter.pose_attack(fighter.data.get_move("5HP"), 8)
	var heavy_clip := "attack_heavy" if anim.has_clip("attack_heavy") else "attack"
	if anim.clip_name != heavy_clip:
		errors.append("%s heavy attack clip is %s" % [who, anim.clip_name])
	fighter.pose_attack(fighter.data.get_move("2LP"), 4)
	anim.apply_facing(1)
	if frames.position.y <= standing_y + 4.0:
		errors.append("%s crouch did not lower the sprite" % who)
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
