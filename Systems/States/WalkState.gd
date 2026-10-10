extends FighterState

var back := false


func enter(data: Dictionary = {}) -> void:
	back = data.get("back", false)
	fighter.set_crouching(false)
	fighter.motion_locked = false


func physics_update(delta: float) -> void:
	fighter.face_opponent()
	back = fighter.buffer.relative_held().x < 0
	fighter.pose_walk(back)
	if fighter.locked:
		fighter.machine.change_state("Idle")
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
	if rel.y > 0:
		fighter.machine.change_state("Crouch")
		return
	if rel.y < 0:
		fighter.machine.change_state("Jump", {})
		return
	if rel.x == 0:
		fighter.machine.change_state("Idle")
		return
	var speed: float = fighter.data.walk_speed * (0.78 if back else 1.0)
	fighter.velocity.x = -fighter.facing * speed if back else fighter.facing * speed
