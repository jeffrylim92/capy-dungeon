extends SceneTree

const ChapterFiveStageControllerClass = preload("res://scripts/story/ChapterFiveStageController.gd")

func _init() -> void:
	var history: Array[String] = ["SUN", "MOON", "STAR"]
	for seed_value in 250:
		for room_index in 4:
			var room: Dictionary = ChapterFiveStageControllerClass.build_mirror_room(room_index, seed_value, history)
			if not ChapterFiveStageControllerClass.validate_mirror_room(room):
				printerr("Invalid mirror configuration: seed=%d room=%d" % [seed_value, room_index])
				quit(1)
				return
	print("ChapterFive mirror validation passed: 1000 configurations")
	quit(0)
