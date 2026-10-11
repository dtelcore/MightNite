extends FighterState

var move: MoveData
var frames := 0
var stun_left := 0


func enter(data: Dictionary = {}) -> void:
	move = data.get("move")
	var attacker = data.get("attacker")
	frames = 0
	stun_left = move.blockstun if move != null else 0
	fighter.crouch_block = fighter.holding_down() or (move != null and move.height == MoveData.Height.LOW)
	fighter.set_crouching(fighter.crouch_block)
	fighter.pose_block(stun_left > 0, 0)
	fighter.disable_hitbox()
	if attacker != null and move != null:
		fighter.velocity.x = attacker.facing * move.knockback.x * 0.42 * Constants.WORLD_SCALE


func physics_update(delta: float) -> void:
	frames += 1
	fighter.face_opponent()
	fighter.velocity.x = move_toward(fighter.velocity.x, 0.0, 900.0 * Constants.WORLD_SCALE * delta)
	if stun_left > 0:
		stun_left -= 1
		fighter.pose_block(true, frames)
		return
	if _try_break() :
		return
	if not fighter.holding_back():
		if fighter.holding_down():
			fighter.machine.change_state("Crouch")
		else:
			fighter.machine.change_state("Idle")
		return
	fighter.crouch_block = fighter.holding_down()
	fighter.pose_block(false, frames)


func _try_break() -> bool:
	if fighter.locked:
		return false
	if fighter.try_offense():
		return true
	if fighter.buffer.dash_tapped(true):
		fighter.machine.change_state("Dash", {"back": false})
		return true
	if fighter.buffer.dash_tapped(false):
		fighter.machine.change_state("Dash", {"back": true})
		return true
	if fighter.buffer.relative_held().y < 0 and fighter.on_floor():
		fighter.machine.change_state("Jump", {})
		return true
	return false


func exit(_next: String = "") -> void:
	fighter.crouch_block = false
	fighter.set_crouching(false)
	fighter.anim_offset = Vector2.ZERO
	fighter.anim_rotation = 0.0
