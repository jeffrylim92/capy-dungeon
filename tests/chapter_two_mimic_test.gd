extends SceneTree

const ChapterTwoStageControllerClass = preload("res://scripts/story/ChapterTwoStageController.gd")

func _init() -> void:
	for seed_value in 500:
		var layout: Dictionary = ChapterTwoStageControllerClass.build_mimic_layout(seed_value)
		if not ChapterTwoStageControllerClass.validate_mimic_layout(layout):
			printerr("Invalid Mimic Treasury layout: seed=%d" % seed_value)
			quit(1)
			return
	print("ChapterTwo Mimic Treasury validation passed: 500 configurations")
	quit(0)
