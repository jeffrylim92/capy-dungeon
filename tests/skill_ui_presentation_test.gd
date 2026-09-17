extends SceneTree

const SkillChoiceCardClass := preload("res://scripts/ui/SkillChoiceCard.gd")
const SkillUIPresentationClass := preload("res://scripts/ui/SkillUIPresentation.gd")

func _init() -> void:
	_test_choice_states()
	_test_actual_primary_changes()
	_test_details_and_tags()
	_test_static_card_component()
	_test_repeated_card_rebuild()
	print("Skill UI presentation tests passed: states, benefits, disclosure, static cards")
	quit()

func _test_choice_states() -> void:
	_assert_equal(SkillUIPresentationClass.choice_state({"type":"new"}), "new", "new state")
	_assert_equal(SkillUIPresentationClass.choice_state({"type":"upgrade"}), "upgrade", "upgrade state")
	_assert_equal(SkillUIPresentationClass.choice_state({"type":"evolution", "evolution":"ascendant"}), "evolved", "evolved state")
	_assert_equal(SkillUIPresentationClass.choice_state({"type":"combo", "is_combo":true}), "combo", "combo state")
	_assert_equal(SkillUIPresentationClass.choice_state({"type":"new", "is_ulti":true}), "ultimate", "ultimate state")

func _test_actual_primary_changes() -> void:
	var orb_levels := [
		{"orbs":3, "dmg":30.0, "note":"3 orbiting balls"},
		{"orbs":3, "dmg":44.0, "note":"+damage"},
		{"orbs":4, "dmg":62.0, "note":"4 balls"},
	]
	_assert_equal(SkillUIPresentationClass.primary_change(orb_levels, 2, "upgrade"), "+47% DAMAGE", "damage delta")
	_assert_equal(SkillUIPresentationClass.primary_change(orb_levels, 3, "upgrade"), "+1 ORB", "count delta priority")
	var cooldown_levels := [{"cd":6.5, "r":380.0}, {"cd":6.0, "r":380.0}]
	_assert_equal(SkillUIPresentationClass.primary_change(cooldown_levels, 2, "upgrade"), "-0.5s COOLDOWN", "cooldown delta")
	_assert_equal(SkillUIPresentationClass.primary_change(orb_levels, 1, "new"), "3 ORBS", "new skill value")

func _test_details_and_tags() -> void:
	var lines := SkillUIPresentationClass.detail_lines([{"n":2, "dmg":44.0, "cd":0.95, "spd":840.0}], 1)
	_assert_true(lines.has("Projectile  2"), "projectile detail")
	_assert_true(lines.has("Damage  44"), "damage detail")
	_assert_true(lines.has("Cooldown  0.9s"), "cooldown detail")
	var tags := SkillUIPresentationClass.tag_labels(["fire", "projectile", "aoe", "crit"], 3)
	_assert_equal(tags.size(), 3, "tag limit")
	_assert_equal(tags[0], "🔥 FIRE", "tag label")

func _test_static_card_component() -> void:
	var card := SkillChoiceCardClass.new()
	card.size = Vector2(656.0, 220.0)
	card.configure({
		"state":"evolved",
		"title":"ASCENDANT FIREBALL",
		"level":"◆ EVOLVED ◆",
		"primary":"+55% DAMAGE",
		"tags":["🔥 FIRE", "◎ AOE"],
		"accent":Color.ORANGE,
		"abbreviation":"AF",
	})
	_assert_true(card.get_node_or_null("DetailsButton") != null, "details button")
	var title := card.get_node_or_null("SkillTitle") as Label
	_assert_true(title != null and title.max_lines_visible == 2, "long title fallback")
	var base_font := title.get_theme_font_size("font_size")
	SettingsStore.apply_ui_scale(card, 1.2)
	_assert_equal(title.get_theme_font_size("font_size"), roundi(float(base_font) * 1.2), "120 percent UI scale")
	SettingsStore.apply_ui_scale(card, 0.8)
	_assert_equal(title.get_theme_font_size("font_size"), roundi(float(base_font) * 0.8), "80 percent UI scale")
	var has_process := false
	for method in (card.get_script() as Script).get_script_method_list():
		if str(method.get("name", "")) == "_process":
			has_process = true
	_assert_true(not has_process, "card has no per-frame process")
	_assert_true(card.try_lock_selection(), "first selection locks")
	_assert_true(not card.try_lock_selection(), "rapid duplicate selection rejected")
	card.free()

func _test_repeated_card_rebuild() -> void:
	var baseline := root.get_child_count()
	for cycle in 20:
		var holder := Control.new()
		root.add_child(holder)
		for index in 3:
			var card := SkillChoiceCardClass.new()
			card.size = Vector2(656.0, 220.0)
			card.configure({"state":"upgrade", "title":"SKILL %d" % index, "level":"Lv.2 → Lv.3", "primary":"+20% DAMAGE", "tags":["◎ AOE"], "accent":Color.CORNFLOWER_BLUE})
			holder.add_child(card)
		holder.free()
	_assert_equal(root.get_child_count(), baseline, "20 card rebuild cleanup")

func _assert_equal(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		push_error("%s: expected %s, got %s" % [label, str(expected), str(actual)])
		quit(1)

func _assert_true(value: bool, label: String) -> void:
	if not value:
		push_error("%s: expected true" % label)
		quit(1)
