extends SceneTree

const ChapterFive = preload("res://scripts/story/ChapterFiveStageController.gd")

const ORDERS: Array[Array] = [
	["dominion", "ruin", "reflection"],
	["dominion", "reflection", "ruin"],
	["ruin", "dominion", "reflection"],
	["ruin", "reflection", "dominion"],
	["reflection", "dominion", "ruin"],
	["reflection", "ruin", "dominion"],
]

func _init() -> void:
	for order in ORDERS:
		var controller = ChapterFive.new()
		controller.reset(5)
		for step in order.size():
			var anchor_type: String = str(order[step])
			var ability: String = str(ChapterFive.ANCHOR_ABILITIES[anchor_type])
			if not controller.boss_ability_enabled(ability):
				printerr("Ability disabled before anchor destruction: %s" % ability)
				quit(1)
				return
			var destroyed: int = controller.record_anchor_destroyed(anchor_type)
			if destroyed != step + 1 or controller.boss_ability_enabled(ability):
				printerr("Invalid anchor transition: %s" % anchor_type)
				quit(1)
				return
			if controller.record_anchor_destroyed(anchor_type) != destroyed:
				printerr("Anchor counted twice: %s" % anchor_type)
				quit(1)
				return
		if controller.count("anchors_destroyed") != 3:
			printerr("Anchor order did not resolve: %s" % str(order))
			quit(1)
			return
	print("ChapterFive anchor-order validation passed: 6 permutations")
	quit(0)
