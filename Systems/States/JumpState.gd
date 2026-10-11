extends FighterState

var lockout := 0
var launched := false
var squat_frames := 0
var landing := 0


func enter(data: Dictionary = {}) -> void:
	fighter.set_crouching(false)
	fighter.motion_locked = false
	landing = 0
	lockout = 8
	if data.get("no_impulse", false):
		launched = true
		squat_frames = 6
	else:
		launched = false
		squat_frames = 0
		fighter.velocity.y = 0.0
		fighter.air_action_used = false


func physics_update(delta: float) -> void:
	if not launched:
		squat_frames += 1
		fighter.pose_squat(clampf(float(squat_frames) / 6.0, 0.0, 1.0))
		fighter.velocity.y = 0.0
		if not fighter.locked and fighter.try_offense():
			return
		if squat_frames >= 6:
			launched = true
			fighter.velocity.y = -fighter.data.jump_force
		return
	if lockout > 0:
		lockout -= 1
	if not fighter.locked and fighter.try_offense():
		return
	var rel: Vector2i = fighter.buffer.relative_held()
	var steer: float = fighter.data.walk_speed * 0.9
	if rel.x != 0 and not fighter.locked:
		fighter.velocity.x = fighter.facing * float(rel.x) * steer
	else:
		fighter.velocity.x = move_toward(fighter.velocity.x, 0.0, 500.0 * Constants.WORLD_SCALE * delta)
	if lockout <= 0 and fighter.is_on_floor() and fighter.velocity.y >= 0.0:
		landing += 1
		fighter.pose_squat(1.0 - clampf(float(landing) / 6.0, 0.0, 1.0))
		if landing >= 6:
			fighter.machine.change_state("Idle")
		return
	if fighter.velocity.y < -80.0:
		fighter.pose_jump(1.0)
	elif fighter.velocity.y > 120.0:
		fighter.pose_jump(0.4)
	else:
		fighter.pose_jump(0.75)
