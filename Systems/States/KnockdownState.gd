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
	fighter.anim_rotation = 1.4
	fighter.anim_scale = Vector2(1.12, 0.82)
	fighter.anim_offset = Vector2(0, 10)
	fighter.velocity.x = move_toward(fighter.velocity.x, 0.0, 700.0 * delta)
	if frames >= 40 and fighter.is_on_floor():
		fighter.machine.change_state("Getup")


func exit(_next: String = "") -> void:
	fighter.anim_rotation = 0.0
