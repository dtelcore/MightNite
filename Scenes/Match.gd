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
	camera.global_position = Vector2(0, stage.floor_y - 170)

	var p1_data: CharacterData = GameManager.p1_data if GameManager.p1_data else load("res://Characters/Ryuji/Ryuji.tres")
	var p2_data: CharacterData = GameManager.p2_data if GameManager.p2_data else load("res://Characters/Titan/Titan.tres")
	p1 = _spawn(p1_data, 0, -280.0)
	p2 = _spawn(p2_data, 1, 280.0)
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


func _spawn(data: CharacterData, index: int, x: float):
	var scene_path := "res://Characters/Titan/Titan.tscn" if data.character_name == "Titan" else "res://Characters/Ryuji/Ryuji.tscn"
	var fighter = load(scene_path).instantiate()
	fighter.name = "P1" if index == 0 else "P2"
	fighter.player_index = index
	fighter.data = data
	fighter.position = Vector2(x, stage.floor_y)
	add_child(fighter)
	return fighter


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		GameManager.p1_rounds = 0
		GameManager.p2_rounds = 0
		get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")


func _physics_process(_delta: float) -> void:
	if p1 == null or p2 == null or camera == null:
		return
	var dist: float = absf(p1.global_position.x - p2.global_position.x)
	var zoom_value := clampf(remap(dist, 280.0, 1000.0, 1.08, 0.76), 0.72, 1.12)
	if not GameManager.is_frozen():
		camera.zoom = camera.zoom.lerp(Vector2(zoom_value, zoom_value), 0.08)
		var mid_x: float = (p1.global_position.x + p2.global_position.x) * 0.5
		mid_x = clampf(mid_x, stage.left_wall + 180.0, stage.right_wall - 180.0)
		var target := Vector2(mid_x, stage.floor_y - 170.0)
		camera.global_position = camera.global_position.lerp(target, 0.12)
