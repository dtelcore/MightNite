class_name AudioBank
extends Node

static func play(host: Node, sound_name: String) -> void:
	if host == null:
		return
	var path := "res://assets/sfx/%s.ogg" % sound_name
	if not ResourceLoader.exists(path):
		path = "res://assets/sfx/%s.wav" % sound_name
	if not ResourceLoader.exists(path):
		return
	var player := AudioStreamPlayer.new()
	host.add_child(player)
	player.stream = load(path)
	player.finished.connect(player.queue_free)
	player.play()
