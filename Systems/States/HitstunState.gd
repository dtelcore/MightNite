extends FighterState

var move: MoveData
var attacker
var frames := 0
var launched := false


func enter(data: Dictionary = {}) -> void:
	move = data.get("move")
	attacker = data.get("attacker")
	launched = data.get("launched", false)
	frames = 0
	fighter.motion_locked = false
	fighter.disable_hitbox()
	fighter.set_crouching(false)
	var push := 460.0
	if move != null:
		push = move.knockback.x * Constants.WORLD_SCALE
	var dir: int = attacker.facing if attacker != null else -fighter.facing
	fighter.velocity.x = dir * push
	if move != null and move.launch_force > 0.0:
		fighter.velocity.y = -move.launch_force * Constants.WORLD_SCALE
		launched = true
	elif not fighter.on_floor():
		fighter.velocity.y = minf(fighter.velocity.y, -300.0 * Constants.WORLD_SCALE)
		launched = true


func physics_update(delta: float) -> void:
	frames += 1
	fighter.pose_hit()
	fighter.velocity.x = move_toward(fighter.velocity.x, 0.0, 420.0 * Constants.WORLD_SCALE * delta)
	var stun := move.hitstun if move != null else 12
	if launched and frames > 5 and fighter.on_floor() and fighter.velocity.y >= 0.0:
		fighter.machine.change_state("Knockdown")
		return
	if frames >= stun and fighter.on_floor() and not launched:
		fighter.machine.change_state("Idle")


func exit(next: String = "") -> void:
	if next != "Hitstun" and fighter.opponent != null:
		fighter.opponent.combo_count = 0
