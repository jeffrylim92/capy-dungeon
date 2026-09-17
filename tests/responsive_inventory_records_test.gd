extends SceneTree

var _failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _run() -> void:
	var cases := [
		{"size":Vector2i(1080, 1920), "scale":1.0, "name":"normal"},
		{"size":Vector2i(900, 1600), "scale":1.0, "name":"narrow"},
		{"size":Vector2i(1080, 2160), "scale":1.0, "name":"tall"},
		{"size":Vector2i(900, 1600), "scale":1.2, "name":"narrow_120"},
	]
	for case_variant in cases:
		var case := case_variant as Dictionary
		await _test_inventory(case.size as Vector2i, float(case.scale), str(case.name))
		await _test_records(case.size as Vector2i, float(case.scale), str(case.name))
	if _failures.is_empty():
		print("RESPONSIVE_INVENTORY_RECORDS_TEST: PASS · normal/narrow/tall · UI 100%/120%")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		print("RESPONSIVE_INVENTORY_RECORDS_TEST: FAIL (%d)" % _failures.size())
		quit(1)

func _viewport(size: Vector2i) -> SubViewport:
	var viewport := SubViewport.new()
	viewport.size = size
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	root.add_child(viewport)
	return viewport

func _test_inventory(size: Vector2i, ui_scale: float, label: String) -> void:
	var viewport := _viewport(size)
	var inventory_scene := load("res://scenes/Inventory.tscn") as PackedScene
	_expect(inventory_scene != null, "%s Inventory scene did not load" % label)
	if inventory_scene == null:
		viewport.queue_free()
		return
	var inventory := inventory_scene.instantiate()
	inventory.account_username = "__responsive_layout_test__"
	inventory.selected_character = CharacterLoader.load_all()[0]
	inventory.accessory_edit_mode = true
	viewport.add_child(inventory)
	await process_frame
	var long_ring := {"id":"layout_ring_equipped_a", "name":"Legendary Guardian's Impossible Horizon", "attr":"max_hp_pct", "value":0.18, "rarity":"legendary", "tier":3}
	var epic_ring := {"id":"layout_ring_equipped_b", "name":"Capy's Mystery Amplifier Ring", "attr":"skill_dmg", "value":0.16, "rarity":"epic", "tier":2}
	var rare_artifact := {"id":"artifact_dimensional_compass", "name":"Dimensional Compass Across Worlds", "rarity":"rare", "effects":{"blink_dist":150.0}}
	var epic_artifact := {"id":"artifact_assassins_contract", "name":"Assassin's Extremely Long Contract", "rarity":"epic", "effects":{"crit_dmg":0.2}}
	inventory._rings_equipped = {"slot_0":long_ring, "slot_1":epic_ring}
	inventory._artifacts_equipped = {"slot_0":rare_artifact, "slot_1":epic_artifact}
	inventory._rings = _large_ring_stash()
	inventory._artifacts = _large_artifact_stash()
	inventory._refresh_slots()
	inventory._rebuild_stash()
	inventory.apply_accessibility_settings({"ui_scale":ui_scale})
	await process_frame
	await process_frame

	var panel := inventory.find_child("EquippedPanel", true, false) as Control
	var row := inventory.find_child("EquippedRow", true, false) as Control
	var scroll := inventory.find_child("InventoryScroll", true, false) as ScrollContainer
	var action := inventory.find_child("InventoryActionBar", true, false) as Control
	var content := inventory.find_child("InventoryContent", true, false) as Control
	var screen := inventory.find_child("InventoryScreen", true, false) as Control
	_expect(panel != null and row != null and scroll != null and action != null and content != null, "%s Inventory structural regions missing" % label)
	if screen != null:
		_expect(_contains(Rect2(Vector2.ZERO, Vector2(size)), screen.get_global_rect()), "%s Inventory screen escaped viewport: %s" % [label, str(screen.get_global_rect())])
	if panel != null and row != null:
		_expect(_contains(panel.get_global_rect(), row.get_global_rect()), "%s equipped row escaped panel" % label)
		for slot in inventory._ring_slot_btns + inventory._artifact_slot_btns:
			_expect(_contains(panel.get_global_rect(), (slot as Control).get_global_rect()), "%s equipped card escaped panel" % label)
			_expect(_children_inside(slot as Control), "%s equipped card content overflow: %s" % [label, _overflow_details(slot as Control)])
	if scroll != null and action != null:
		_expect(scroll.get_global_rect().end.y <= action.get_global_rect().position.y + 1.0, "%s inventory scroll overlaps action bar" % label)
	if content != null and action != null:
		_expect(content.get_global_rect().end.y <= action.get_global_rect().position.y + 1.0, "%s inventory content overlaps action bar" % label)
	if action != null:
		for child in action.get_children():
			if child is Control and (child as Control).visible:
				_expect(_contains(action.get_global_rect(), (child as Control).get_global_rect()), "%s action button escaped footer" % label)

	var cards: Array = inventory._stash_grid.get_children()
	if scroll != null:
		var grid_rect: Rect2 = inventory._stash_grid.get_global_rect()
		var scroll_rect: Rect2 = scroll.get_global_rect()
		_expect(grid_rect.position.x >= scroll_rect.position.x - 2.0 and grid_rect.end.x <= scroll_rect.end.x + 2.0, "%s stash grid escaped horizontally" % label)
	_expect(cards.size() >= 12, "%s large stash did not create enough scroll cards" % label)
	var cards_by_quantity: Dictionary = {}
	for card in cards:
		if card is Button:
			_expect(_children_inside(card as Control), "%s stash card content overflow: %s" % [label, _overflow_details(card as Control)])
			if card.get("item_count") != null:
				cards_by_quantity[int(card.get("item_count"))] = card
	for expected_quantity in [2, 9, 99]:
		var quantity_card := cards_by_quantity.get(expected_quantity, null) as Control
		_expect(quantity_card != null, "%s ×%d duplicates were not grouped into one card" % [label, expected_quantity])
		if quantity_card != null:
			var quantity_label := quantity_card.find_child("CardQuantity", true, false) as Label
			_expect(quantity_label != null and quantity_label.text == "×%d" % expected_quantity, "%s ×%d quantity label missing" % [label, expected_quantity])
	var merge_card := cards_by_quantity.get(99, null) as Control
	if merge_card != null:
		var tier_label := merge_card.find_child("CardTier", true, false) as Label
		var progress_label := merge_card.find_child("CardMergeProgress", true, false) as Label
		_expect(tier_label != null and tier_label.text == "T4", "%s T4 accessory tier missing" % label)
		_expect(progress_label != null and "3 / 3" in progress_label.text, "%s merge progress collided with quantity" % label)
	if scroll != null and not cards.is_empty():
		scroll.scroll_vertical = roundi(scroll.get_v_scroll_bar().max_value)
		await process_frame
		var final_card := cards[cards.size() - 1] as Control
		_expect(final_card.get_global_rect().end.y <= scroll.get_global_rect().end.y + 2.0, "%s final stash row is obstructed" % label)

	inventory._rings = []
	inventory._artifacts = []
	inventory._rebuild_stash()
	await process_frame
	await process_frame
	_expect(inventory._stash_grid.find_children("*", "Button", false, false).is_empty(), "%s empty stash retained item cards" % label)
	viewport.queue_free()
	await process_frame
	await process_frame

func _test_records(size: Vector2i, ui_scale: float, label: String) -> void:
	var viewport := _viewport(size)
	var history_scene := load("res://scenes/History.tscn") as PackedScene
	_expect(history_scene != null, "%s Records scene did not load" % label)
	if history_scene == null:
		viewport.queue_free()
		return
	var history := history_scene.instantiate()
	history.account = {"username":"__responsive_layout_test__", "display_name":"SpringMapleWithAnExceptionallyLongPlayerName"}
	history.adventure_entries_override = []
	viewport.add_child(history)
	await process_frame
	var list := history.find_child("AdventureList", true, false) as VBoxContainer
	_expect(list != null, "%s Adventure list missing" % label)
	if list == null:
		viewport.queue_free()
		return
	history._populate_adventure_list(list, [])
	await process_frame
	_expect(history.find_child("AdventureEmptyState", true, false) != null, "%s zero-record state missing" % label)
	history._populate_adventure_list(list, [_adventure_entry(1)])
	history.apply_accessibility_settings({"ui_scale":ui_scale})
	await process_frame
	await process_frame
	_expect(history.find_children("AdventureRecord_*", "PanelContainer", true, false).size() == 1, "%s one-record state incorrect" % label)
	history._populate_adventure_list(list, _many_adventure_entries())
	history.apply_accessibility_settings({"ui_scale":ui_scale})
	await process_frame
	await process_frame

	var frame := history.find_child("RecordsContentFrame", true, false) as Control
	var adventure_panel := history.find_child("AdventurePanel", true, false) as Control
	var footer := history.find_child("RecordsFooter", true, false) as Control
	var back := history.find_child("RecordsBackButton", true, false) as Button
	var scroll := history.find_child("AdventureScroll", true, false) as ScrollContainer
	_expect(frame != null and footer != null and back != null and scroll != null, "%s Records structural regions missing" % label)
	if frame != null:
		_expect(_contains(Rect2(Vector2.ZERO, Vector2(size)), frame.get_global_rect()), "%s Records frame escaped viewport: %s" % [label, str(frame.get_global_rect())])
	if frame != null and adventure_panel != null:
		_expect(_contains(frame.get_global_rect(), adventure_panel.get_global_rect()), "%s Adventure panel escaped Records frame" % label)
	if frame != null and footer != null:
		_expect(frame.get_global_rect().end.y <= footer.get_global_rect().position.y + 1.0, "%s Records frame overlaps footer" % label)
	if footer != null and back != null:
		_expect(_contains(footer.get_global_rect(), back.get_global_rect()), "%s Back button escaped footer" % label)
	var cards: Array = history.find_children("AdventureRecord_*", "PanelContainer", true, false)
	_expect(cards.size() == 18, "%s many-record state incorrect" % label)
	for card_variant in cards:
		var card := card_variant as Control
		_expect(_children_inside(card), "%s Adventure card content overflow" % label)
		var detail_button := card.find_child("AdventureDetailButton", true, false) as Button
		_expect(detail_button != null and _contains(card.get_global_rect(), detail_button.get_global_rect()), "%s Adventure detail button escaped card" % label)
	if scroll != null and not cards.is_empty():
		scroll.scroll_vertical = roundi(scroll.get_v_scroll_bar().max_value)
		await process_frame
		_expect((cards[cards.size() - 1] as Control).get_global_rect().end.y <= scroll.get_global_rect().end.y + 2.0, "%s final Adventure card is obstructed" % label)

	history._switch_tab(1)
	_expect(history._tab_panels[1].visible, "%s Survival tab did not activate" % label)
	history._switch_tab(2)
	_expect(history._tab_panels[2].visible, "%s Rankings tab did not activate" % label)
	var global_entry := {"rank":1, "display_name":"SpringMapleWithAnExceptionallyLongPlayerName", "character":"capy_zoomer", "value":9876}
	history._global_kills_done = true
	history._global_kills_entries = [global_entry]
	history._global_kill_user_entry = global_entry
	history._refresh_global_view()
	history.apply_accessibility_settings({"ui_scale":ui_scale})
	await process_frame
	await process_frame
	var global_row := history.find_child("GlobalRankRow_1", true, false) as Control
	var global_scroll := history.find_child("GlobalListScroll", true, false) as ScrollContainer
	_expect(global_row != null and global_scroll != null, "%s global ranking row missing" % label)
	if global_row != null and global_scroll != null:
		_expect(global_row.get_global_rect().position.x >= global_scroll.get_global_rect().position.x - 2.0 and global_row.get_global_rect().end.x <= global_scroll.get_global_rect().end.x + 2.0, "%s global ranking row escaped horizontally" % label)
		_expect(_children_inside(global_row), "%s global ranking row content overflow" % label)
	history._switch_tab(0)
	_expect(history._tab_panels[0].visible, "%s Adventure tab did not reactivate" % label)
	history._show_adventure_detail(_adventure_entry(1))
	await process_frame
	await process_frame
	var detail_panel := history.find_child("AdventureDetailPanel", true, false) as Control
	var detail_close := history.find_child("AdventureDetailClose", true, false) as Button
	_expect(detail_panel != null and detail_close != null, "%s Adventure detail modal missing" % label)
	if detail_panel != null:
		_expect(_contains(Rect2(Vector2.ZERO, Vector2(size)), detail_panel.get_global_rect()), "%s Adventure detail panel escaped viewport" % label)
	if detail_panel != null and detail_close != null:
		_expect(_contains(detail_panel.get_global_rect(), detail_close.get_global_rect()), "%s Adventure detail close escaped modal" % label)
	history._show_match_detail_modal({
		"character":"capy_zoomer",
		"display_name":"SpringMapleWithAnExceptionallyLongPlayerName",
		"rank":1,
		"kills":9876,
		"survive_seconds":1234.0,
		"rings":{"slot_0":{"id":"layout_detail_ring", "name":"Legendary Guardian's Impossible Horizon", "attr":"max_hp_pct", "value":0.18, "rarity":"legendary", "tier":3}},
		"artifacts":{"slot_0":{"id":"artifact_dimensional_compass", "name":"Dimensional Compass Across Worlds", "rarity":"rare", "effects":{"blink_dist":150.0}}},
	})
	history.apply_accessibility_settings({"ui_scale":ui_scale})
	await process_frame
	await process_frame
	var match_detail_panel := history.find_child("MatchDetailPanel", true, false) as Control
	var match_detail_scroll := history.find_child("MatchDetailScroll", true, false) as ScrollContainer
	_expect(match_detail_panel != null and match_detail_scroll != null, "%s match detail modal missing" % label)
	if match_detail_panel != null:
		_expect(_contains(Rect2(Vector2.ZERO, Vector2(size)), match_detail_panel.get_global_rect()), "%s match detail panel escaped viewport" % label)
	if match_detail_panel != null and match_detail_scroll != null:
		_expect(_contains(match_detail_panel.get_global_rect(), match_detail_scroll.get_global_rect()), "%s match detail scroll escaped modal" % label)
	var back_state := {"count":0}
	history.back_requested.connect(func() -> void: back_state.count = int(back_state.count) + 1)
	if back != null:
		back.pressed.emit()
	_expect(int(back_state.count) == 1, "%s Back button did not emit once" % label)
	viewport.queue_free()
	await process_frame
	await process_frame

func _large_ring_stash() -> Array:
	var stash: Array = []
	var quantity_cases := [
		{"count":2, "data":{"id":"layout_quantity_2", "name":"Twin Echo Ring", "attr":"layout_quantity_two", "value":0.12, "rarity":"rare", "tier":1}},
		{"count":9, "data":{"id":"layout_quantity_9", "name":"Ninefold Expedition Amplifier", "attr":"layout_quantity_nine", "value":0.19, "rarity":"epic", "tier":3}},
		{"count":99, "data":{"id":"layout_quantity_99", "name":"Legendary Length Merge Progress Test Ring", "attr":"layout_quantity_ninetynine", "value":0.24, "rarity":"rare", "tier":4}},
	]
	for quantity_case_variant in quantity_cases:
		var quantity_case := quantity_case_variant as Dictionary
		for _copy_index in int(quantity_case.get("count", 1)):
			stash.append((quantity_case.get("data", {}) as Dictionary).duplicate(true))
	var attrs := ["skill_dmg", "max_hp_pct", "crit_chance", "xp_bonus", "projectile_spd", "luck"]
	var rarities := ["common", "rare", "epic"]
	for index in 18:
		var ring := {"id":"layout_ring_%d" % index, "name":"Capy's Very Long Expedition Ring Number %d" % index, "attr":attrs[index % attrs.size()], "value":0.05 + index * 0.01, "rarity":rarities[index % rarities.size()], "tier":index % 3 + 1}
		stash.append(ring)
		if index % 4 == 0:
			stash.append(ring.duplicate(true))
			stash.append(ring.duplicate(true))
	return stash

func _large_artifact_stash() -> Array:
	var stash: Array = []
	for index in 12:
		stash.append({"id":"layout_artifact_%d_unique" % index, "name":"Artifact With A Very Long Historic Name %d" % index, "rarity":"legendary" if index % 4 == 0 else ("epic" if index % 3 == 0 else "rare"), "effects":{"skill_dmg":0.1}})
	return stash

func _adventure_entry(rank: int) -> Dictionary:
	return {"rank":rank, "display_name":"SpringMapleWithAnExceptionallyLongPlayerName_%d" % rank, "story_stage":987654 + rank, "coin_depth":765432 + rank, "forge_depth":543210 + rank, "character":"capy_zoomer", "equipment":{"weapon":"ember_ladle"}, "rings":{}, "artifacts":{}}

func _many_adventure_entries() -> Array:
	var entries: Array = []
	for rank in range(1, 19):
		entries.append(_adventure_entry(rank))
	return entries

func _contains(outer: Rect2, inner: Rect2, tolerance: float = 1.5) -> bool:
	return inner.position.x >= outer.position.x - tolerance and inner.position.y >= outer.position.y - tolerance and inner.end.x <= outer.end.x + tolerance and inner.end.y <= outer.end.y + tolerance

func _children_inside(parent: Control) -> bool:
	var bounds := parent.get_global_rect()
	for child in parent.get_children():
		if child is Control and (child as Control).visible:
			var child_rect := (child as Control).get_global_rect()
			if not _contains(bounds, child_rect, 2.0):
				return false
	return true

func _overflow_details(parent: Control) -> String:
	var bounds := parent.get_global_rect()
	for child in parent.get_children():
		if child is Control and (child as Control).visible:
			var child_rect := (child as Control).get_global_rect()
			if not _contains(bounds, child_rect, 2.0):
				return "parent=%s child=%s" % [str(bounds), str(child_rect)]
	return "none"
