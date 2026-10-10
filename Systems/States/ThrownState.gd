extends FighterState

var attacker
var frames := 0


func enter(data: Dictionary = {}) -> void:
	attacker = data.get("attacker")
	frames = 0
	fighter.motion_locked = true
	fighter.invulnerable = true
	fighter.velocity = Vector2.ZERO
	fighter.disable_hitbox()


func physics_update(_delta: float) -> void:
	frames += 1
	if attacker != null and is_instance_valid(attacker):
		fighter.global_position = attacker.global_position + Vector2(attacker.facing * 52.0, 0.0)
		fighter.facing = -attacker.facing
	fighter.anim_rotation = sin(float(frames) * 0.45) * 0.35
	fighter.anim_scale = Vector2(1.06, 0.9)


func exit(_next: String = "") -> void:
	fighter.motion_locked = false
	fighter.invulnerable = false
