extends FighterState

var back := false
var frames := 0


func enter(data: Dictionary = {}) -> void:
	back = data.get("back", false)
	frames = 0
	fighter.set_crouching(false)
	fighter.motion_locked = false
	fighter.invulnerable = back


func physics_update(_delta: float) -> void:
	frames += 1
	var speed: float = fighter.data.dash_speed
	var dir: int = -fighter.facing if back else fighter.facing
	fighter.velocity.x = dir * speed
	fighter.pose_dash(back)
	if back and frames > 8:
		fighter.invulnerable = false
	if not back and frames > 3 and not fighter.locked and fighter.try_offense():
		return
	var limit := 18 if back else 13
	if frames >= limit:
		fighter.machine.change_state("Idle")


func exit(_next: String = "") -> void:
	fighter.invulnerable = false
