class_name HitboxSystem
extends RefCounted

static func blocked(defender, move: MoveData) -> bool:
	if defender == null or move == null:
		return false
	if not defender.is_on_floor():
		return false
	if not defender.holding_back():
		return false
	if move.is_throw or move.is_command_grab:
		return false
	if move.height == MoveData.Height.UNBLOCKABLE:
		return false
	var crouching: bool = defender.holding_down() or defender.machine.state_name() == "Crouch" or defender.machine.state_name() == "Block" and defender.crouch_block
	if move.height == MoveData.Height.LOW and not crouching:
		return false
	if move.height == MoveData.Height.HIGH and crouching:
		return false
	return true
