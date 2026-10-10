class_name HitstopController
extends Node

var frames := 0


func _ready() -> void:
	add_to_group("hitstop")
	process_physics_priority = -128


func trigger(count: int) -> void:
	frames = maxi(frames, count)


func _physics_process(_delta: float) -> void:
	if frames > 0:
		frames -= 1
