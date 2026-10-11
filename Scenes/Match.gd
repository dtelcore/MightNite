extends Node2D

var p1
var p2
var camera: Camera2D
var stage
var hud


func _ready() -> void:
	var stage_data: StageData = GameManager.stage
	if stage_data == null:
		stage_data = load("res://Stages/dojo.tres")
	stage = preload("res://Stages/Stage.tscn").instantiate()
	stage.name = "Stage"
	add_child(stage)
	stage.setup(stage_data)

	camera = Camera2D.new()
	camera.name = "Camera"
	add_child(camera)
	camera.make_current()
	camera.zoom = Vector2.ONE / Constants.WORLD_SCALE
	camera.global_position = Vector2(0, stage.floor_y - 170.0 * Constants.WORLD_SCALE)

	var p1_data: CharacterData = GameManager.p1_data if GameManager.p1_data else load("res://Characters/MartialHero/MartialHero.tres")
	var p2_data: CharacterData = GameManager.p2_data if GameManager.p2_data else load("res://Characters/HeavyBandit/HeavyBandit.tres")
	p1 = _spawn(p1_data, 0, -280.0 * Constants.WORLD_SCALE)
	p2 = _spawn(p2_data, 1, 280.0 * Constants.WORLD_SCALE)
	p1.opponent = p2
	p2.opponent = p1
	p1.facing = 1
	p2.facing = -1

	var combat := CombatManager.new()
	combat.name = "CombatManager"
	combat.camera = camera
	add_child(combat)

	var hitstop := HitstopController.new()
	hitstop.name = "HitstopController"
	add_child(hitstop)

	hud = MatchHUD.new()
	hud.name = "HUD"
	add_child(hud)
	hud.setup(p1, p2)

	var manager := MatchManager.new()
	manager.name = "MatchManager"
	add_child(manager)
	manager.setup(self)
	Net.attach_match(p1, p2)


func _spawn(data: CharacterData, index: int, x: float):
	var fighter = load("res://Characters/CharacterBase.tscn").instantiate()
	fighter.name = "P1" if index == 0 else "P2"
	fighter.player_index = index
	fighter.data = data
	fighter.position = Vector2(x, stage.floor_y)
	add_child(fighter)
	return fighter


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Net.leave()


func _physics_process(_delta: float) -> void:
	if p1 == null or p2 == null or camera == null:
		return
	var dist: float = absf(p1.global_position.x - p2.global_position.x)
	var fit := 1.0 / Constants.WORLD_SCALE
	var zoom_value := clampf(remap(dist, 280.0 * Constants.WORLD_SCALE, 1000.0 * Constants.WORLD_SCALE, 1.08 * fit, 0.76 * fit), 0.72 * fit, 1.12 * fit)
	if not GameManager.is_frozen():
		camera.zoom = camera.zoom.lerp(Vector2(zoom_value, zoom_value), 0.08)
		var mid_x: float = (p1.global_position.x + p2.global_position.x) * 0.5
		mid_x = clampf(mid_x, stage.left_wall + 180.0 * Constants.WORLD_SCALE, stage.right_wall - 180.0 * Constants.WORLD_SCALE)
		var target := Vector2(mid_x, stage.floor_y - 170.0 * Constants.WORLD_SCALE)
		camera.global_position = camera.global_position.lerp(target, 0.12)
