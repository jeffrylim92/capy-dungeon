extends Node

## Tracks in-app purchases and drives the Google Play Billing flow.
## Registered as the "PurchaseStore" autoload so all scripts access it as a global.
##
## Uses the GodotGooglePlayBilling v3.x addon (Godot 4.x):
##   addons/GodotGooglePlayBilling/BillingClient.gd
## Enable the addon in Project → Project Settings → Plugins.

const PATH := "user://purchases.json"

const CHARACTER_PRODUCTS: Array[String] = ["capy_wizard", "capy_archer", "capy_assassin"]

const RING_PRODUCTS: Dictionary = {
	"ring_warlords_crest": {
		"name": "Warlord's Crest",
		"attr": "skill_dmg",
		"value": 0.15,
		"rarity": "rare",
		"tier": 1,
		"desc": "Increases all skill damage/DPS. Store purchase only.",
	},
	"ring_haste_coil": {
		"name": "Haste Coil",
		"attr": "skill_cd",
		"value": 0.12,
		"rarity": "rare",
		"tier": 1,
		"desc": "Reduces skill cooldowns. Store purchase only.",
	},
	"ring_second_chance": {
		"name": "Second Chance Ring",
		"attr": "revive_once",
		"value": 1.0,
		"rarity": "legendary",
		"tier": 1,
		"desc": "Revives once per gameplay when equipped. Store purchase only.",
	},
	"ring_guardian_pulse": {
		"name": "Guardian Pulse Ring",
		"attr": "timed_shield",
		"value": 1.0,
		"rarity": "legendary",
		"tier": 1,
		"desc": "Creates a shield for 1 second every 10 seconds. Store purchase only.",
	},
}

const KEY_PRODUCTS: Dictionary = {
	"key_pack_1": {
		"name": "Door Key x1",
		"keys": 1,
		"bonus_keys": 0,
	},
	"key_pack_3": {
		"name": "Door Key x3",
		"keys": 3,
		"bonus_keys": 0,
	},
	"key_pack_5": {
		"name": "Door Key x5 (+1 free)",
		"keys": 5,
		"bonus_keys": 1,
	},
	"key_pack_10": {
		"name": "Door Key x10 (+2 free)",
		"keys": 10,
		"bonus_keys": 2,
	},
}

const KEY_DROP_COOLDOWN_SEC: int = 6 * 60 * 60

const PURCHASABLE: Array[String] = [
	"capy_wizard", "capy_archer", "capy_assassin",
	"ring_warlords_crest", "ring_haste_coil", "ring_second_chance", "ring_guardian_pulse",
	"key_pack_1", "key_pack_3", "key_pack_5", "key_pack_10",
]

const PRICES: Dictionary = {
	"capy_wizard":   "$2.99",
	"capy_archer":   "$2.99",
	"capy_assassin": "$2.99",
	"ring_warlords_crest": "$0.99",
	"ring_haste_coil": "$0.99",
	"ring_second_chance": "$1.99",
	"ring_guardian_pulse": "$1.99",
	"key_pack_1": "$0.99",
	"key_pack_3": "$2.99",
	"key_pack_5": "$4.99",
	"key_pack_10": "$9.99",
}

# Product-specific purchase option IDs (Play Console). Leave empty for default.
const PURCHASE_OPTION_IDS: Dictionary = {
	"capy_wizard": "capywizard",
	"capy_archer": "capyarcher",
	"capy_assassin": "capyassassin",
	"ring_warlords_crest": "warlordscrest",
	"ring_haste_coil": "ringhastecoil",
	"ring_second_chance": "ringsecondchance",
	"ring_guardian_pulse": "ringguardianpulse",
	"key_pack_1": "keypack1",
	"key_pack_3": "keypack3",
	"key_pack_5": "keypack5",
	"key_pack_10": "keypack10",
}

## Emitted after a successful purchase + acknowledgement.
signal purchase_success(character_id: String)
## Emitted when the billing flow fails or the user cancels.
signal purchase_failed(character_id: String, message: String)

var _current_username: String = ""
var _pending_id: String = ""
var _billing: BillingClient = null
var _billing_ready: bool = false
var _known_products: Dictionary = {}
var _known_purchase_option_ids: Dictionary = {}
var _recent_requested_at: Dictionary = {}

const RECENT_REQUEST_TTL_SEC: int = 10 * 60

# ── Lifecycle ──────────────────────────────────────────────────────────────────

func _ready() -> void:
	if not _ensure_billing_client():
		DebugLog.log("[PurchaseStore] No GodotGooglePlayBilling plugin yet — will retry on purchase")

func _ensure_billing_client() -> bool:
	if _billing != null:
		return true
	if not Engine.has_singleton("GodotGooglePlayBilling"):
		return false
	_billing = BillingClient.new()
	add_child(_billing)
	_billing.connected.connect(_on_billing_connected)
	_billing.disconnected.connect(_on_billing_disconnected)
	_billing.connect_error.connect(_on_billing_connect_error)
	_billing.query_product_details_response.connect(_on_query_product_details_response)
	_billing.query_purchases_response.connect(_on_query_purchases_response)
	_billing.on_purchase_updated.connect(_on_purchase_updated)
	_billing.acknowledge_purchase_response.connect(_on_acknowledge_response)
	_billing.start_connection()
	DebugLog.log("[PurchaseStore] BillingClient created — start_connection called")
	return true

# ── Billing callbacks ──────────────────────────────────────────────────────────

func _on_billing_connected() -> void:
	_billing_ready = true
	DebugLog.log("[PurchaseStore] Billing connected — querying product details + existing purchases")
	_billing.query_product_details(PackedStringArray(PURCHASABLE), BillingClient.ProductType.INAPP)
	_billing.query_purchases(BillingClient.ProductType.INAPP)

func _on_billing_disconnected() -> void:
	_billing_ready = false
	DebugLog.log("[PurchaseStore] Billing disconnected")
	if _billing != null:
		# Auto-reconnect so purchase restore/query works after app resumes.
		get_tree().create_timer(1.5).timeout.connect(func() -> void:
			if _billing != null and not _billing_ready:
				_billing.start_connection()
		, CONNECT_ONE_SHOT)
	if not _pending_id.is_empty():
		var pending := _pending_id
		_pending_id = ""
		purchase_failed.emit(pending, "Billing disconnected")

func _on_billing_connect_error(response_code: int, debug_message: String) -> void:
	_billing_ready = false
	DebugLog.log("[PurchaseStore] Billing connect_error %d: %s" % [response_code, debug_message])
	if not _pending_id.is_empty():
		var pending := _pending_id
		_pending_id = ""
		purchase_failed.emit(pending, "Billing connect error (%d)" % response_code)

func _on_query_product_details_response(response: Dictionary) -> void:
	var status: Dictionary = response.get("status", {}) as Dictionary
	var code: int = int(status.get("responseCode", -1))
	if code != BillingClient.BillingResponseCode.OK:
		DebugLog.log("[PurchaseStore] query_product_details_response error code=%d" % code)
		return

	_known_products.clear()
	_known_purchase_option_ids.clear()

	var details: Array = []
	if response.get("productDetails", null) is Array:
		details = response.get("productDetails", []) as Array
	elif response.get("product_details", null) is Array:
		details = response.get("product_details", []) as Array
	elif response.get("products", null) is Array:
		details = response.get("products", []) as Array

	for raw in details:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var pd: Dictionary = raw as Dictionary
		var pid: String = str(pd.get("productId", pd.get("product_id", "")))
		if pid.is_empty():
			continue
		_known_products[pid] = true

		var option_ids: Array[String] = []
		for key in ["purchaseOptions", "purchase_options", "offerDetails", "offer_details"]:
			var v: Variant = pd.get(key, null)
			if v is Array:
				for opt in (v as Array):
					if typeof(opt) != TYPE_DICTIONARY:
						continue
					var od: Dictionary = opt as Dictionary
					for id_key in ["id", "offerId", "offer_id", "purchaseOptionId", "purchase_option_id", "offerToken", "offer_token"]:
						var id_val: String = str(od.get(id_key, ""))
						if not id_val.is_empty() and not option_ids.has(id_val):
							option_ids.append(id_val)

		_known_purchase_option_ids[pid] = option_ids

	DebugLog.log("[PurchaseStore] Product details fetched: %d/%d products visible to Play account" % [_known_products.size(), PURCHASABLE.size()])
	if _known_products.has("capy_archer"):
		DebugLog.log("[PurchaseStore] capy_archer is visible. option_ids=%s" % str(_known_purchase_option_ids.get("capy_archer", [])))
	else:
		DebugLog.log("[PurchaseStore] capy_archer NOT returned by Play product details")

## Fired after query_purchases() — restores previously purchased items on launch.
func _on_query_purchases_response(response: Dictionary) -> void:
	var status: Dictionary = response.get("status", {}) as Dictionary
	var code: int = int(status.get("responseCode", -1))
	if code != BillingClient.BillingResponseCode.OK:
		DebugLog.log("[PurchaseStore] query_purchases_response error code=%d" % code)
		return
	_prune_recent_requests()
	var purchases: Array = _extract_purchases(response)
	var active_non_consumables: Dictionary = {}
	for p in purchases:
		if typeof(p) != TYPE_DICTIONARY:
			continue
		var pd: Dictionary = p as Dictionary
		var ids: Array[String] = _extract_purchase_product_ids(pd)
		var token: String = _extract_purchase_token(pd)
		var state: int = _extract_purchase_state(pd)
		if state != BillingClient.PurchaseState.PURCHASED:
			continue
		for cid in ids:
			var product_id: String = String(cid)
			if PURCHASABLE.has(product_id):
				_grant(product_id)
				if _is_non_consumable_product(product_id):
					active_non_consumables[product_id] = true
				if _recent_requested_at.has(product_id):
					_recent_requested_at.erase(product_id)
					purchase_success.emit(product_id)
		if not _extract_purchase_acknowledged(pd) and not token.is_empty():
			_billing.acknowledge_purchase(token)
	_reconcile_non_consumable_entitlements(active_non_consumables)
	DebugLog.log("[PurchaseStore] Restored %d purchase(s)" % purchases.size())

## Fired after the billing sheet closes (buy, cancel, or error).
func _on_purchase_updated(response: Dictionary) -> void:
	var status: Dictionary = response.get("status", {}) as Dictionary
	var code: int = int(status.get("responseCode", -1))
	DebugLog.log("[PurchaseStore] on_purchase_updated code=%d" % code)
	_prune_recent_requests()
	if code != BillingClient.BillingResponseCode.OK:
		var msg := "Cancelled" if code == BillingClient.BillingResponseCode.USER_CANCELED \
			else ("Item already owned" if code == BillingClient.BillingResponseCode.ITEM_ALREADY_OWNED \
			else ("Billing error (%d)" % code))
		if code == BillingClient.BillingResponseCode.ITEM_ALREADY_OWNED and _billing != null:
			# Do not blindly grant — refunded items can temporarily report as owned.
			# Always reconcile against current Play purchases.
			_billing.query_purchases(BillingClient.ProductType.INAPP)
			msg = "Item already owned. Syncing with Play…"
		if not _pending_id.is_empty():
			purchase_failed.emit(_pending_id, msg)
			_pending_id = ""
		return

	var purchases: Array = _extract_purchases(response)
	for p in purchases:
		if typeof(p) != TYPE_DICTIONARY:
			continue
		var pd: Dictionary = p as Dictionary
		var ids: Array[String] = _extract_purchase_product_ids(pd)
		var token: String = _extract_purchase_token(pd)
		var state: int = _extract_purchase_state(pd)
		if state != BillingClient.PurchaseState.PURCHASED:
			continue
		for cid in ids:
			var product_id: String = String(cid)
			_grant(product_id)
			if not _extract_purchase_acknowledged(pd) and not token.is_empty():
				_billing.acknowledge_purchase(token)
			if product_id == _pending_id:
				var granted_id := _pending_id
				_pending_id = ""
				_recent_requested_at.erase(granted_id)
				purchase_success.emit(granted_id)
				return
			if _recent_requested_at.has(product_id):
				_recent_requested_at.erase(product_id)
				purchase_success.emit(product_id)
				return

	if not _pending_id.is_empty():
		purchase_failed.emit(_pending_id, "Purchase not confirmed")
		_pending_id = ""

func _on_acknowledge_response(response: Dictionary) -> void:
	var code: int = int(response.get("responseCode", -1))
	DebugLog.log("[PurchaseStore] acknowledge_purchase_response code=%d" % code)

func _extract_purchases(response: Dictionary) -> Array:
	for key in ["purchases", "purchaseList", "purchase_list", "items"]:
		var v: Variant = response.get(key, null)
		if v is Array:
			return v as Array
	return []

func _extract_purchase_product_ids(p: Dictionary) -> Array[String]:
	var out: Array[String] = []
	for key in ["productIds", "product_ids", "products", "productId", "product_id"]:
		var v: Variant = p.get(key, null)
		if v is Array:
			for item in (v as Array):
				var pid: String = String(item)
				if not pid.is_empty() and not out.has(pid):
					out.append(pid)
		elif v != null:
			var single: String = String(v)
			if not single.is_empty() and not out.has(single):
				out.append(single)
	return out

func _extract_purchase_token(p: Dictionary) -> String:
	for key in ["purchaseToken", "purchase_token", "token"]:
		var v: Variant = p.get(key, null)
		if v != null:
			var s: String = String(v)
			if not s.is_empty():
				return s
	return ""

func _extract_purchase_state(p: Dictionary) -> int:
	for key in ["purchaseState", "purchase_state", "state"]:
		if p.has(key):
			return int(p.get(key, 0))
	return 0

func _extract_purchase_acknowledged(p: Dictionary) -> bool:
	for key in ["isAcknowledged", "is_acknowledged", "acknowledged"]:
		if p.has(key):
			return bool(p.get(key, false))
	return false

func _is_non_consumable_product(product_id: String) -> bool:
	return CHARACTER_PRODUCTS.has(product_id) or is_ring_product(product_id)

func _reconcile_non_consumable_entitlements(active: Dictionary) -> void:
	var purchased: Array = _load()
	if purchased.is_empty():
		return
	var changed: bool = false
	for i in range(purchased.size() - 1, -1, -1):
		var product_id: String = String(purchased[i])
		if not _is_non_consumable_product(product_id):
			continue
		if not active.has(product_id):
			purchased.remove_at(i)
			changed = true
			DebugLog.log("[PurchaseStore] Revoked local entitlement '%s' (not active in Play purchases)" % product_id)
	if changed:
		_save(purchased)

# ── Public API ─────────────────────────────────────────────────────────────────

func set_username(username: String) -> void:
	_current_username = username
	RingStore.sync_equipped_to_shared_stash(username)
	_sync_purchased_rings_to_stash()
	if _is_dev_account():
		var d: Dictionary = _load_key_data(username)
		d["keys"] = 99
		_save_key_data(username, d)

func is_purchased(product_id: String) -> bool:
	if not PURCHASABLE.has(product_id):
		return true
	# Dev account gets all purchases
	if _is_dev_account():
		return true
	return _load().has(product_id)

## Launch the billing flow. Listen to purchase_success / purchase_failed signals for the result.
func purchase(product_id: String) -> void:
	if _billing == null and not _ensure_billing_client():
		DebugLog.log("[PurchaseStore] GodotGooglePlayBilling singleton not found at purchase time")
		purchase_failed.emit(product_id, "Billing not available in this build")
		return
	if is_key_product(product_id) and not can_buy_key_product_this_week(product_id):
		purchase_failed.emit(product_id, "This key pack can only be purchased once per week.")
		return
	if _billing == null:
		DebugLog.log("[PurchaseStore] No GodotGooglePlayBilling plugin — purchases disabled")
		purchase_failed.emit(product_id, "Billing not available")
		return
	if not _billing_ready and not _billing.is_ready():
		purchase_failed.emit(product_id, "Billing not ready yet. Please try again.")
		return
	if not _known_products.is_empty() and not _known_products.has(product_id):
		purchase_failed.emit(product_id, "Product '%s' was not returned by Google Play. Check Play Console activation/tester account." % product_id)
		return
	if not _pending_id.is_empty():
		DebugLog.log("[PurchaseStore] Purchase already in progress for '%s'" % _pending_id)
		purchase_failed.emit(product_id, "Another purchase is still processing.")
		return
	_pending_id = product_id
	_recent_requested_at[product_id] = int(Time.get_unix_time_from_system())
	var purchase_option_id: String = PURCHASE_OPTION_IDS.get(product_id, "") as String
	var known_option_ids: Array = _known_purchase_option_ids.get(product_id, []) as Array
	if not purchase_option_id.is_empty() and not known_option_ids.is_empty() and not known_option_ids.has(purchase_option_id):
		DebugLog.log("[PurchaseStore] purchase_option_id '%s' not found for '%s'; falling back to default" % [purchase_option_id, product_id])
		purchase_option_id = ""
	DebugLog.log(
		"[PurchaseStore] Requesting purchase: product_id=%s purchase_option_id=%s _billing_ready=%s" %
		[product_id, purchase_option_id if not purchase_option_id.is_empty() else "<default>", str(_billing_ready)]
	)
	var start_result: Dictionary = _billing.purchase(product_id, purchase_option_id)
	if not start_result.is_empty():
		var status: Dictionary = start_result.get("status", {}) as Dictionary
		var code: int = int(status.get("responseCode", BillingClient.BillingResponseCode.OK))
		if code != BillingClient.BillingResponseCode.OK:
			var pending := _pending_id
			_pending_id = ""
			purchase_failed.emit(pending, _billing_error_text(code))
			return

	# Safety net: if Google Play never calls back, release UI from "Processing...".
	var expected_id := product_id
	get_tree().create_timer(30.0).timeout.connect(func() -> void:
		if _pending_id == expected_id:
			_pending_id = ""
			DebugLog.log("[PurchaseStore] Purchase timeout for product_id=%s — likely not set up in Play Console" % expected_id)
			if _billing != null:
				# Reconcile late/foreground-resume purchase confirmations from Play.
				_billing.query_purchases(BillingClient.ProductType.INAPP)
			purchase_failed.emit(expected_id, "Purchase timed out. Waiting for Play confirmation…")
	, CONNECT_ONE_SHOT)

func _notification(what: int) -> void:
	if OS.get_name() != "Android":
		return
	if what == NOTIFICATION_APPLICATION_FOCUS_IN or what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		if _billing != null and _billing_ready:
			_billing.query_purchases(BillingClient.ProductType.INAPP)

func _prune_recent_requests() -> void:
	var now: int = int(Time.get_unix_time_from_system())
	var stale: Array = []
	for pid in _recent_requested_at.keys():
		var ts: int = int(_recent_requested_at[pid])
		if now - ts > RECENT_REQUEST_TTL_SEC:
			stale.append(pid)
	for pid in stale:
		_recent_requested_at.erase(pid)

func _billing_error_text(code: int) -> String:
	match code:
		BillingClient.BillingResponseCode.USER_CANCELED:
			return "Cancelled"
		BillingClient.BillingResponseCode.ITEM_ALREADY_OWNED:
			return "Item already owned"
		BillingClient.BillingResponseCode.BILLING_UNAVAILABLE:
			return "Billing unavailable on this device/account"
		BillingClient.BillingResponseCode.SERVICE_UNAVAILABLE, BillingClient.BillingResponseCode.NETWORK_ERROR:
			return "Network unavailable. Please try again."
		BillingClient.BillingResponseCode.ITEM_UNAVAILABLE:
			return "Item unavailable in this region/account"
		_:
			return "Billing error (%d)" % code

func is_ring_product(product_id: String) -> bool:
	return RING_PRODUCTS.has(product_id)

func is_key_product(product_id: String) -> bool:
	return KEY_PRODUCTS.has(product_id)

func ring_product_to_ring(product_id: String) -> Dictionary:
	if not RING_PRODUCTS.has(product_id):
		return {}
	var ring: Dictionary = (RING_PRODUCTS[product_id] as Dictionary).duplicate(true)
	ring["id"] = product_id
	ring["store_only"] = true
	return RingStore.normalize_ring(ring)

func key_product_total_keys(product_id: String) -> int:
	if not KEY_PRODUCTS.has(product_id):
		return 0
	var d: Dictionary = KEY_PRODUCTS[product_id] as Dictionary
	return int(d.get("keys", 0)) + int(d.get("bonus_keys", 0))

func can_buy_key_product_this_week(product_id: String) -> bool:
	if not is_key_product(product_id):
		return true
	if _is_dev_account():
		return true
	if _current_username.is_empty():
		return false
	var data: Dictionary = _load_key_data(_current_username)
	var weekly: Dictionary = data.get("weekly", {}) as Dictionary
	var stamp: int = _week_stamp_now()
	return int(weekly.get(product_id, -1)) != stamp

func get_key_count(username: String = "") -> int:
	var u: String = username if not username.is_empty() else _current_username
	if u.is_empty():
		return 0
	if u.to_lower() == AccountStore.DEV_USERNAME.to_lower():
		return 99
	var data: Dictionary = _load_key_data(u)
	return int(data.get("keys", 0))

func add_keys(username: String, amount: int) -> void:
	if username.is_empty() or amount <= 0:
		return
	if username.to_lower() == AccountStore.DEV_USERNAME.to_lower():
		return
	var data: Dictionary = _load_key_data(username)
	data["keys"] = int(data.get("keys", 0)) + amount
	_save_key_data(username, data)

func consume_key(username: String) -> bool:
	if username.is_empty():
		return false
	if username.to_lower() == AccountStore.DEV_USERNAME.to_lower():
		return true
	var data: Dictionary = _load_key_data(username)
	var count: int = int(data.get("keys", 0))
	if count <= 0:
		return false
	data["keys"] = count - 1
	_save_key_data(username, data)
	return true

func is_key_drop_available(username: String) -> bool:
	return get_key_drop_remaining_seconds(username) <= 0

func start_key_drop_cooldown(username: String, seconds: int = KEY_DROP_COOLDOWN_SEC) -> void:
	if username.is_empty() or username.to_lower() == AccountStore.DEV_USERNAME.to_lower():
		return
	var data: Dictionary = _load_key_data(username)
	data["drop_cooldown_until"] = int(Time.get_unix_time_from_system()) + max(seconds, 0)
	_save_key_data(username, data)

func get_key_drop_remaining_seconds(username: String = "") -> int:
	var u: String = username if not username.is_empty() else _current_username
	if u.is_empty() or u.to_lower() == AccountStore.DEV_USERNAME.to_lower():
		return 0
	var data: Dictionary = _load_key_data(u)
	var until: int = int(data.get("drop_cooldown_until", 0))
	return max(until - int(Time.get_unix_time_from_system()), 0)

func get_key_drop_remaining_text(username: String = "") -> String:
	var remaining: int = get_key_drop_remaining_seconds(username)
	if remaining <= 0:
		return "00:00"
	var h: int = int(remaining / 3600.0)
	var m: int = int((remaining - h * 3600) / 60.0)
	return "%02d:%02d" % [h, m]

# ── Storage helpers ────────────────────────────────────────────────────────────

func _grant(product_id: String) -> void:
	var purchased := _load()
	if not purchased.has(product_id):
		purchased.append(product_id)
		_save(purchased)
		DebugLog.log("[PurchaseStore] Granted '%s'" % product_id)
	if is_ring_product(product_id) and not _current_username.is_empty():
		RingStore.ensure_ring_in_stash(_current_username, ring_product_to_ring(product_id))
	if is_key_product(product_id) and not _current_username.is_empty():
		add_keys(_current_username, key_product_total_keys(product_id))
		_mark_key_product_purchase_this_week(_current_username, product_id)

func _sync_purchased_rings_to_stash() -> void:
	if _current_username.is_empty():
		return
	if _is_dev_account():
		for product_id in RING_PRODUCTS.keys():
			var ring: Dictionary = ring_product_to_ring(product_id as String)
			RingStore.ensure_ring_in_stash(_current_username, ring)
		return
	var purchased: Array = _load()
	for product in purchased:
		var product_id: String = product as String
		if is_ring_product(product_id):
			RingStore.ensure_ring_in_stash(_current_username, ring_product_to_ring(product_id))

func _is_dev_account() -> bool:
	return _current_username.to_lower() == AccountStore.DEV_USERNAME.to_lower()

func _key_path(username: String) -> String:
	return "user://keys_%s.json" % username.strip_edges().to_lower()

func _blank_key_data() -> Dictionary:
	return {
		"keys": 0,
		"drop_cooldown_until": 0,
		"weekly": {},
	}

func _load_key_data(username: String) -> Dictionary:
	var path: String = _key_path(username)
	if not FileAccess.file_exists(path):
		return _blank_key_data()
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return _blank_key_data()
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return _blank_key_data()
	var out: Dictionary = parsed as Dictionary
	for k in _blank_key_data().keys():
		if not out.has(k):
			out[k] = _blank_key_data()[k]
	return out

func _save_key_data(username: String, data: Dictionary) -> void:
	var f := FileAccess.open(_key_path(username), FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(data))
	f.close()

func _week_stamp_now() -> int:
	return int(floor(Time.get_unix_time_from_system() / 604800.0))

func _mark_key_product_purchase_this_week(username: String, product_id: String) -> void:
	if username.is_empty() or username.to_lower() == AccountStore.DEV_USERNAME.to_lower():
		return
	var data: Dictionary = _load_key_data(username)
	var weekly: Dictionary = data.get("weekly", {}) as Dictionary
	weekly[product_id] = _week_stamp_now()
	data["weekly"] = weekly
	_save_key_data(username, data)

func _load() -> Array:
	if not FileAccess.file_exists(PATH):
		return []
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return []
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_ARRAY:
		return []
	return parsed as Array

func _save(purchased: Array) -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(purchased))
	f.close()
