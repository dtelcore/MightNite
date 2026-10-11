extends FighterState

var victim
var move: MoveData
var frames := 0


func enter(data: Dictionary = {}) -> void:
	victim = data.get("victim")
	move = data.get("move")
	frames = 0
	fighter.motion_locked = true
	fighter.velocity = Vector2.ZERO
	fighter.disable_hitbox()


func physics_update(_delta: float) -> void:
	frames += 1
	var heavy: bool = move != null and move.is_command_grab
	fighter.pose_throw(heavy)
	if frames == 20 and victim != null and is_instance_valid(victim):
		victim.motion_locked = false
		victim.invulnerable = false
		victim.velocity = Vector2(fighter.facing * 520.0, -640.0)
		victim.machine.change_state("Knockdown")
	if frames >= 32:
		fighter.machine.change_state("Idle")


func exit(_next: String = "") -> void:
	fighter.motion_locked = false
