class_name MatchManager
extends Node

enum Phase { INTRO, FIGHT, ROUND_END, MATCH_END }

var match_node
var p1
var p2
var hud
var phase := Phase.INTRO
var timer := 0
var round_number := 1
var clock := 99 * 60


func setup(match_root) -> void:
	match_node = match_root
	p1 = match_root.p1
	p2 = match_root.p2
	hud = match_root.hud
	process_physics_priority = 40
	_begin_intro()


func _physics_process(_delta: float) -> void:
	if p1 == null or p2 == null:
		return
	if phase == Phase.INTRO:
		timer += 1
		if timer == 75:
			hud.announce("FIGHT")
		elif timer >= 110:
			hud.announce("")
			_set_locked(false)
			phase = Phase.FIGHT
			timer = 0
	elif phase == Phase.FIGHT:
		if not GameManager.is_frozen():
			clock = maxi(clock - 1, 0)
		hud.set_time(maxi(0, ceili(float(clock) / 60.0)))
		if _check_ko():
			return
		if clock <= 0:
			_time_up()
	elif phase == Phase.ROUND_END:
		timer += 1
		if timer > 150:
			if GameManager.p1_rounds >= 2 or GameManager.p2_rounds >= 2:
				phase = Phase.MATCH_END
				timer = 0
				var winner: String = p1.data.character_name if GameManager.p1_rounds >= 2 else p2.data.character_name
				hud.announce("%s WINS" % winner.to_upper())
			else:
				_next_round()
	elif phase == Phase.MATCH_END:
		timer += 1
		if timer > 160:
			GameManager.p1_rounds = 0
			GameManager.p2_rounds = 0
			get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")
	if hud:
		hud.refresh_rounds()


func _begin_intro() -> void:
	phase = Phase.INTRO
	timer = 0
	clock = 99 * 60
	_set_locked(true)
	if hud:
		hud.announce("ROUND %d" % round_number)
		hud.set_time(99)


func _set_locked(on: bool) -> void:
	p1.locked = on
	p2.locked = on
	if on:
		p1.disable_hitbox()
		p2.disable_hitbox()


func _check_ko() -> bool:
	if p1.hp.current > 0 and p2.hp.current > 0:
		return false
	phase = Phase.ROUND_END
	timer = 0
	_set_locked(true)
	GameManager.play_sfx("ko")
	if p1.hp.current <= 0 and p2.hp.current <= 0:
		hud.announce("DOUBLE KO")
		return true
	if p2.hp.current <= 0:
		GameManager.p1_rounds += 1
		hud.announce("PERFECT" if p1.hp.current >= p1.hp.maximum else "KO")
	else:
		GameManager.p2_rounds += 1
		hud.announce("PERFECT" if p2.hp.current >= p2.hp.maximum else "KO")
	return true


func _time_up() -> void:
	phase = Phase.ROUND_END
	timer = 0
	_set_locked(true)
	GameManager.play_sfx("ko")
	if p1.hp.current > p2.hp.current:
		GameManager.p1_rounds += 1
		hud.announce("TIME'S UP")
	elif p2.hp.current > p1.hp.current:
		GameManager.p2_rounds += 1
		hud.announce("TIME'S UP")
	else:
		hud.announce("DRAW")


func _next_round() -> void:
	round_number += 1
	for node in get_tree().get_nodes_in_group("projectile"):
		node.queue_free()
	var floor_y: float = match_node.stage.floor_y
	p1.full_reset(-280.0, floor_y)
	p2.full_reset(280.0, floor_y)
	p1.opponent = p2
	p2.opponent = p1
	p1.facing = 1
	p2.facing = -1
	_begin_intro()
