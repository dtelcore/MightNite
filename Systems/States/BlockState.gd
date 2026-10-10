extends FighterState

var move: MoveData
var frames := 0


func enter(data: Dictionary = {}) -> void:
	move = data.get("move")
	var attacker = data.get("attacker")
	frames = 0
	fighter.crouch_block = fighter.holding_down() or (move != null and move.height == MoveData.Height.LOW)
	fighter.set_crouching(fighter.crouch_block)
	if fighter.crouch_block:
		fighter.pose_crouch()
	else:
		fighter.anim_offset = Vector2(-12, 0)
		fighter.anim_rotation = 0.1
		fighter.anim_scale = Vector2(0.96, 1.0)
	if attacker != null and move != null:
		fighter.velocity.x = attacker.facing * move.knockback.x * 0.42
	fighter.disable_hitbox()


func physics_update(delta: float) -> void:
	frames += 1
	fighter.velocity.x = move_toward(fighter.velocity.x, 0.0, 900.0 * delta)
	var stun := move.blockstun if move != null else 8
	if frames >= stun:
		if fighter.holding_down():
			fighter.machine.change_state("Crouch")
		else:
			fighter.machine.change_state("Idle")


func exit(_next: String = "") -> void:
	fighter.crouch_block = false
	fighter.set_crouching(false)
