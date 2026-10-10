class_name StateMachine
extends Node

const STATE_SCRIPTS := {
	"Idle": preload("res://Systems/States/IdleState.gd"),
	"Walk": preload("res://Systems/States/WalkState.gd"),
	"Crouch": preload("res://Systems/States/CrouchState.gd"),
	"Jump": preload("res://Systems/States/JumpState.gd"),
	"Dash": preload("res://Systems/States/DashState.gd"),
	"Attack": preload("res://Systems/States/AttackState.gd"),
	"Block": preload("res://Systems/States/BlockState.gd"),
	"Hitstun": preload("res://Systems/States/HitstunState.gd"),
	"Knockdown": preload("res://Systems/States/KnockdownState.gd"),
	"Getup": preload("res://Systems/States/GetupState.gd"),
	"Throw": preload("res://Systems/States/ThrowState.gd"),
	"Thrown": preload("res://Systems/States/ThrownState.gd"),
}

var current: Node
var states := {}
var fighter


func setup(owner_fighter) -> void:
	fighter = owner_fighter
	for state_name in STATE_SCRIPTS.keys():
		var node = STATE_SCRIPTS[state_name].new()
		node.name = state_name
		node.fighter = fighter
		add_child(node)
		states[state_name] = node
	change_state("Idle")


func change_state(state_name: String, data: Dictionary = {}) -> void:
	if not states.has(state_name):
		push_error("Missing state %s" % state_name)
		return
	if current:
		current.exit(state_name)
	current = states[state_name]
	current.enter(data)


func physics_update(delta: float) -> void:
	if current:
		current.physics_update(delta)


func state_name() -> String:
	if current == null:
		return ""
	return String(current.name)
