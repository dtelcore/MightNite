extends FighterState


func enter(_data: Dictionary = {}) -> void:
	fighter.reset_pose()
	fighter.set_crouching(false)
	fighter.motion_locked = false


func physics_update(delta: float) -> void:
	fighter.face_opponent()
	fighter.pose_idle()
	if fighter.locked:
		fighter.velocity.x = move_toward(fighter.velocity.x, 0.0, 2200.0 * Constants.WORLD_SCALE * delta)
		return
	if fighter.try_offense():
		return
	var rel: Vector2i = fighter.buffer.relative_held()
	if fighter.buffer.dash_tapped(true):
		fighter.machine.change_state("Dash", {"back": false})
		return
	if fighter.buffer.dash_tapped(false):
		fighter.machine.change_state("Dash", {"back": true})
		return
	if rel.y < 0:
		fighter.machine.change_state("Jump", {})
		return
	if rel.x < 0:
		fighter.machine.change_state("Block")
		return
	if rel.y > 0:
		fighter.machine.change_state("Crouch")
		return
	if rel.x != 0:
		fighter.machine.change_state("Walk", {"back": rel.x < 0})
		return
	fighter.velocity.x = move_toward(fighter.velocity.x, 0.0, 2200.0 * Constants.WORLD_SCALE * delta)
