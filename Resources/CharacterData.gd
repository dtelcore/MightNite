class_name CharacterData
extends Resource

@export var character_name: String = ""
@export var max_health: int = 1000
@export var walk_speed: float = 260.0
@export var dash_speed: float = 520.0
@export var jump_force: float = 820.0
@export var body_height: float = 300.0
@export var body_width: float = 70.0
@export var portrait: Texture2D
@export var sprite: Texture2D
@export var moves: Array[MoveData] = []
@export var specials: Array[MoveData] = []
@export var supers: Array[MoveData] = []


func all_moves() -> Array[MoveData]:
	var out: Array[MoveData] = []
	out.append_array(moves)
	out.append_array(specials)
	out.append_array(supers)
	return out


func get_move(id: String) -> MoveData:
	for move in all_moves():
		if move.move_name == id or move.input == id:
			return move
	return null
