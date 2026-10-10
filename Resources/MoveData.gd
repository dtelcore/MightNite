class_name MoveData
extends Resource

enum Height { LOW, MID, HIGH, UNBLOCKABLE }

@export var move_name: String = ""
@export var input: String = ""
@export var startup: int = 4
@export var active: int = 3
@export var recovery: int = 8
@export var damage: int = 30
@export var chip_damage: int = 0
@export var hitstun: int = 12
@export var blockstun: int = 8
@export var knockback: Vector2 = Vector2(360, 0)
@export var launch_force: float = 0.0
@export var is_projectile: bool = false
@export var is_throw: bool = false
@export var is_command_grab: bool = false
@export var armor: bool = false
@export var hitbox: Rect2 = Rect2(36, -140, 70, 40)
@export var animation: String = ""
@export var cancel_into: Array[String] = []
@export var scaling: float = 1.0
@export var height: Height = Height.MID
@export var sprite_offset: Vector2 = Vector2.ZERO
@export var sprite_rotation: float = 0.0
@export var hitstop_frames: int = 4
