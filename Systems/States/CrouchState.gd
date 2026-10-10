extends FighterState


func enter(_data: Dictionary = {}) -> void:
	fighter.set_crouching(true)
	fighter.pose_crouch()
	fighter.motion_locked = false
	fighter.velocity.x = move_toward(fighter.velocity.x, 0.0, 400.0)


func physics_update(delta: float) -> void:
	fighter.face_opponent()
	fighter.pose_crouch()
	fighter.velocity.x = move_toward(fighter.velocity.x, 0.0, 1800.0 * delta)
	if fighter.locked:
		return
	if fighter.try_offense():
		return
	var rel: Vector2i = fighter.buffer.relative_held()
	if rel.y < 0:
		fighter.machine.change_state("Jump", {})
		return
	if rel.y <= 0:
		fighter.machine.change_state("Idle")
