extends FighterState

var frames := 0


func enter(_data: Dictionary = {}) -> void:
	frames = 0
	fighter.motion_locked = false
	fighter.disable_hitbox()
	fighter.velocity.x *= 0.55
	fighter.set_crouching(false)


func physics_update(delta: float) -> void:
	frames += 1
	fighter.pose_knockdown()
	fighter.velocity.x = move_toward(fighter.velocity.x, 0.0, 700.0 * Constants.WORLD_SCALE * delta)
	if frames >= 40 and fighter.is_on_floor():
		fighter.machine.change_state("Getup")


