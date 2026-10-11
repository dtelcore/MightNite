extends FighterState

var move: MoveData
var frame := 0
var released := false


func enter(data: Dictionary = {}) -> void:
	move = data.get("move")
	frame = 0
	released = false
	fighter.attack_move = move
	fighter.attack_frame = 0
	fighter.hit_connected = false
	fighter.armor_hits_left = 1 if move.armor else 0
	fighter.armor_active = false
	fighter.motion_locked = false
	fighter.disable_hitbox()
	var lunge := (70.0 + float(move.damage) * 0.35) * Constants.WORLD_SCALE
	if move.is_projectile:
		lunge = 20.0 * Constants.WORLD_SCALE
	fighter.velocity.x = fighter.facing * lunge


func physics_update(_delta: float) -> void:
	frame += 1
	fighter.attack_frame = frame
	var active_start := move.startup
	var active_end := move.startup + move.active
	if move.is_projectile and frame == active_start and not released:
		released = true
		fighter.spawn_fireball(move)
	if move.active > 0 and frame == active_start:
		fighter.enable_hitbox(move.hitbox)
	if frame == active_end:
		fighter.disable_hitbox()
	fighter.armor_active = move.armor and fighter.armor_hits_left > 0 and frame <= active_end
	if frame >= active_start and frame < active_end:
		fighter.poll_hitbox()
	if fighter.machine.state_name() != "Attack":
		return
	fighter.pose_attack(move, frame)
	fighter.velocity.x = move_toward(fighter.velocity.x, 0.0, 18.0 * Constants.WORLD_SCALE)
	if frame > active_end and fighter.try_cancel(move):
		return
	if frame >= move.startup + move.active + move.recovery:
		fighter.disable_hitbox()
		fighter.armor_active = false
		if fighter.is_on_floor():
			fighter.machine.change_state("Idle")
		else:
			fighter.machine.change_state("Jump", {"no_impulse": true})


func exit(_next: String = "") -> void:
	fighter.disable_hitbox()
	fighter.armor_active = false
