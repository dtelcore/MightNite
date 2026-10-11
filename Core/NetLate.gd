extends Node

func _ready() -> void:
	process_physics_priority = 80


func _physics_process(_delta: float) -> void:
	Net.after_step()
