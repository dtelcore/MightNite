extends FighterState

var lockout := 0


func enter(data: Dictionary = {}) -> void:
	lockout = 8
	fighter.set_crouching(false)
	fighter.motion_locked = false
	if not data.get("no_impulse", false):
		fighter.velocity.y = -fighter.data.jump_force
		fighter.air_action_used = false
	fighter.anim_scale = Vector2(0.92, 1.1)


func physics_update(delta: float) -> void:
	if lockout > 0:
		lockout -= 1
	if not fighter.locked and fighter.try_offense():
		return
	var rel: Vector2i = fighter.buffer.relative_held()
	var steer: float = fighter.data.walk_speed * 0.9
	if rel.x != 0 and not fighter.locked:
		fighter.velocity.x = fighter.facing * float(rel.x) * steer
	else:
		fighter.velocity.x = move_toward(fighter.velocity.x, 0.0, 500.0 * delta)
	if fighter.velocity.y < -100.0:
		fighter.anim_scale = Vector2(0.9, 1.12)
		fighter.anim_offset = Vector2(0, -6)
	elif fighter.velocity.y > 100.0:
		fighter.anim_scale = Vector2(1.05, 0.9)
		fighter.anim_offset = Vector2(0, 4)
	else:
		fighter.anim_scale = Vector2.ONE
		fighter.anim_offset = Vector2.ZERO
	if lockout <= 0 and fighter.is_on_floor() and fighter.velocity.y >= 0.0:
		fighter.machine.change_state("Idle")
