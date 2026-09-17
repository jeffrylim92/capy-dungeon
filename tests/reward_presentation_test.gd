extends SceneTree

const RewardPresentationClass := preload("res://scripts/ui/RewardPresentation.gd")
const RewardItemCardClass := preload("res://scripts/ui/RewardItemCard.gd")
const InventoryCardStyleClass := preload("res://scripts/ui/InventoryCardStyle.gd")

var _failures: Array[String] = []

func _initialize() -> void:
	_test_rarity_language()
	_test_tradeoff_visibility()
	_test_ring_and_merge_formatting()
	_test_card_states_and_static_runtime()
	_test_story_loadout_card_variant()
	_test_icon_cache()
	if _failures.is_empty():
		print("REWARD_PRESENTATION_TEST: PASS")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		print("REWARD_PRESENTATION_TEST: FAIL (%d)" % _failures.size())
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _test_rarity_language() -> void:
	var labels: Dictionary = {}
	for rarity in ["common", "rare", "epic", "legendary"]:
		var label := RewardPresentationClass.rarity_label(rarity)
		_expect(label.contains(rarity.to_upper()), "Rarity label must include text: %s" % rarity)
		labels[label.left(1)] = true
	_expect(labels.size() == 4, "Every rarity must have a distinct non-colour marker")
	_expect(RewardPresentationClass.frame_border_width("legendary") > RewardPresentationClass.frame_border_width("common"), "Legendary border must differ from Common")
	_expect(RewardPresentationClass.frame_corner_radius("epic", "ring") != RewardPresentationClass.frame_corner_radius("epic", "artifact"), "Ring and Artifact silhouettes must differ")

func _test_tradeoff_visibility() -> void:
	var artifact := {
		"id":"artifact_dual_potion_test",
		"name":"Dual Potion",
		"rarity":"rare",
		"effects":{"healing_efficiency":0.24, "enemy_hp_mul":0.12},
	}
	var lines := RewardPresentationClass.item_effect_lines("artifact", artifact, 2)
	_expect(lines.size() == 2, "Trade-off Artifact must show two primary effects")
	_expect(lines[0].begins_with("↑") or lines[1].begins_with("↑"), "Trade-off Artifact must label its benefit")
	_expect(lines[0].begins_with("↓") or lines[1].begins_with("↓"), "Trade-off Artifact must label its drawback")
	_expect("Enemy Health" in " ".join(lines), "Artifact drawback must not be hidden")

func _test_ring_and_merge_formatting() -> void:
	var ring := {"name":"Storm Ring", "rarity":"epic", "tier":2, "attr":"aoe_radius", "value":0.18}
	var lines := RewardPresentationClass.item_effect_lines("ring", ring, 2)
	_expect(lines.size() == 1 and "+18%" in lines[0], "Ring primary effect must be concise and formatted")
	_expect(RewardPresentationClass.merge_progress(2) == "●●○  2 / 3", "Merge progress must be visual and numeric")
	_expect(RewardPresentationClass.merge_progress(5) == "●●●  3 / 3", "Merge progress must clamp to its requirement")
	_expect(RewardPresentationClass.item_name({}, "ring") == "Unknown Ring", "Unknown item definitions must fail gracefully")

func _test_card_states_and_static_runtime() -> void:
	var card := RewardItemCardClass.new()
	card.configure("ring", {"name":"Storm Ring", "rarity":"epic", "tier":2, "attr":"aoe_radius", "value":0.18}, {"new":true, "duplicate":true, "merge_ready":true, "equipped":true}, 3, 3, true, true)
	_expect(card.get_child_count() == 1, "Reusable reward card must build one static content tree")
	SettingsStore.apply_ui_scale(card, 0.8)
	var low_scale_height := card.custom_minimum_size.y
	SettingsStore.apply_ui_scale(card, 1.2)
	_expect(card.custom_minimum_size.y > low_scale_height, "Reward card must respond to 80%-120% UI Scale")
	var method_names: Array[String] = []
	for method in card.get_script().get_script_method_list():
		method_names.append(str((method as Dictionary).get("name", "")))
	_expect("_process" not in method_names, "Reward cards must not run a continuous animation loop")
	card.free()

func _test_story_loadout_card_variant() -> void:
	var card := RewardItemCardClass.new()
	card.configure("ring", {"name":"Amplifier Ring With A Long Name", "rarity":"epic", "tier":4, "attr":"skill_dmg", "value":0.2}, {"duplicate":true, "merge_ready":true}, 99, 99, true, false, "story_loadout")
	var actual := card.get_theme_stylebox("normal") as StyleBoxFlat
	var story_reference := InventoryCardStyleClass.card_style()
	_expect(actual.bg_color == story_reference.bg_color and actual.border_color == story_reference.border_color, "Accessory cards must reuse the Story Loadout frame treatment")
	_expect(actual.corner_radius_top_left == story_reference.corner_radius_top_left, "Accessory cards must reuse Story Loadout card proportions")
	var quantity := card.find_child("CardQuantity", true, false) as Label
	var tier := card.find_child("CardTier", true, false) as Label
	var progress := card.find_child("CardMergeProgress", true, false) as Label
	var status := card.find_child("CardStatus", true, false) as Label
	_expect(quantity != null and quantity.text == "×99", "Accessory quantity must remain distinct and support two digits")
	_expect(tier != null and tier.text == "T4", "Accessory tier must keep a dedicated card region")
	_expect(progress != null and "3 / 3" in progress.text, "Accessory merge progress must remain separate from quantity")
	_expect(status != null and status.text == "⇧ MERGE READY", "Merge-ready state must use the shared status region")
	card.free()

func _test_icon_cache() -> void:
	RewardPresentationClass.clear_icon_cache()
	var path := "res://assets/camp/resources/camp_coin.png"
	var first := RewardPresentationClass.cached_icon(path)
	var second := RewardPresentationClass.cached_icon(path)
	_expect(first != null and first == second, "Reward icons must reuse their cached Texture2D")
	_expect(RewardPresentationClass.icon_cache_size() == 1, "Repeated icon lookup must not grow the cache")
