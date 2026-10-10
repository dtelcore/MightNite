class_name HealthSystem
extends Node

var current: int = 1000
var maximum: int = 1000


func setup(max_hp: int) -> void:
	maximum = max_hp
	current = max_hp


func apply(amount: int, allow_ko: bool = true) -> int:
	var next := current - amount
	if not allow_ko:
		next = maxi(next, 1)
	current = clampi(next, 0, maximum)
	return current
