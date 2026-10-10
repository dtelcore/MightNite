extends FighterState

var frames := 0


func enter(_data: Dictionary = {}) -> void:
	frames = 0
	fighter.invulnerable = true
	fighter.velocity = Vector2.ZERO
	fighter.motion_locked = false


func physics_update(_delta: float) -> void:
	frames += 1
	var t := clampf(float(frames) / 16.0, 0.0, 1.0)
	fighter.anim_rotation = lerpf(1.15, 0.0, t)
	fighter.anim_scale = Vector2(lerpf(1.08, 1.0, t), lerpf(0.84, 1.0, t))
	if frames >= 16:
		fighter.machine.change_state("Idle")


func exit(_next: String = "") -> void:
	fighter.invulnerable = false
	fighter.reset_pose()
