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

const PURCHASABLE: Array[String] = [
	"capy_wizard", "capy_archer", "capy_assassin",
	"ring_warlords_crest", "ring_haste_coil", "ring_second_chance", "ring_guardian_pulse",
]

const PRICES: Dictionary = {
	"capy_wizard":   "$2.99",
	"capy_archer":   "$2.99",
	"capy_assassin": "$2.99",
	"ring_warlords_crest": "$0.99",
	"ring_haste_coil": "$0.99",
	"ring_second_chance": "$1.99",
	"ring_guardian_pulse": "$1.99",
}

## Emitted after a successful purchase + acknowledgement.
signal purchase_success(character_id: String)
## Emitted when the billing flow fails or the user cancels.
signal purchase_failed(character_id: String, message: String)

var _current_username: String = ""
var _pending_id: String = ""
var _billing: BillingClient = null

# ── Lifecycle ──────────────────────────────────────────────────────────────────

func _ready() -> void:
	if Engine.has_singleton("GodotGooglePlayBilling"):
		_billing = BillingClient.new()
		add_child(_billing)
		_billing.connected.connect(_on_billing_connected)
		_billing.disconnected.connect(_on_billing_disconnected)
		_billing.connect_error.connect(_on_billing_connect_error)
		_billing.query_purchases_response.connect(_on_query_purchases_response)
		_billing.on_purchase_updated.connect(_on_purchase_updated)
		_billing.acknowledge_purchase_response.connect(_on_acknowledge_response)
		_billing.start_connection()
		DebugLog.log("[PurchaseStore] BillingClient created — start_connection called")
	else:
		DebugLog.log("[PurchaseStore] No GodotGooglePlayBilling plugin — dev mode (grants directly)")

# ── Billing callbacks ──────────────────────────────────────────────────────────

func _on_billing_connected() -> void:
	DebugLog.log("[PurchaseStore] Billing connected — querying existing purchases")
	_billing.query_purchases(BillingClient.ProductType.INAPP)

func _on_billing_disconnected() -> void:
	DebugLog.log("[PurchaseStore] Billing disconnected")

func _on_billing_connect_error(response_code: int, debug_message: String) -> void:
	DebugLog.log("[PurchaseStore] Billing connect_error %d: %s" % [response_code, debug_message])

## Fired after query_purchases() — restores previously purchased items on launch.
func _on_query_purchases_response(response: Dictionary) -> void:
	var status: Dictionary = response.get("status", {}) as Dictionary
	var code: int = int(status.get("responseCode", -1))
	if code != BillingClient.BillingResponseCode.OK:
		DebugLog.log("[PurchaseStore] query_purchases_response error code=%d" % code)
		return
	var purchases: Array = response.get("purchases", []) as Array
	for p in purchases:
		var ids: Array = p.get("productIds", []) as Array
		var token: String = p.get("purchaseToken", "") as String
		var state: int = int(p.get("purchaseState", 0))
		if state != BillingClient.PurchaseState.PURCHASED:
			continue
		for cid in ids:
			if PURCHASABLE.has(cid as String):
				_grant(cid as String)
		if not (p.get("isAcknowledged", false) as bool) and not token.is_empty():
			_billing.acknowledge_purchase(token)
	DebugLog.log("[PurchaseStore] Restored %d purchase(s)" % purchases.size())

## Fired after the billing sheet closes (buy, cancel, or error).
func _on_purchase_updated(response: Dictionary) -> void:
	var status: Dictionary = response.get("status", {}) as Dictionary
	var code: int = int(status.get("responseCode", -1))
	DebugLog.log("[PurchaseStore] on_purchase_updated code=%d" % code)
	if code != BillingClient.BillingResponseCode.OK:
		var msg := "Cancelled" if code == BillingClient.BillingResponseCode.USER_CANCELED \
			else ("Item already owned" if code == BillingClient.BillingResponseCode.ITEM_ALREADY_OWNED \
			else ("Billing error (%d)" % code))
		# ITEM_ALREADY_OWNED means they paid before — grant and treat as success
		if code == BillingClient.BillingResponseCode.ITEM_ALREADY_OWNED and not _pending_id.is_empty():
			_grant(_pending_id)
			var cid := _pending_id
			_pending_id = ""
			purchase_success.emit(cid)
			return
		if not _pending_id.is_empty():
			purchase_failed.emit(_pending_id, msg)
			_pending_id = ""
		return

	var purchases: Array = response.get("purchases", []) as Array
	for p in purchases:
		var ids: Array = p.get("productIds", []) as Array
		var token: String = p.get("purchaseToken", "") as String
		var state: int = int(p.get("purchaseState", 0))
		if state != BillingClient.PurchaseState.PURCHASED:
			continue
		for cid in ids:
			_grant(cid as String)
			if not (p.get("isAcknowledged", false) as bool) and not token.is_empty():
				_billing.acknowledge_purchase(token)
			if (cid as String) == _pending_id:
				var granted_id := _pending_id
				_pending_id = ""
				purchase_success.emit(granted_id)
				return

	if not _pending_id.is_empty():
		purchase_failed.emit(_pending_id, "Purchase not confirmed")
		_pending_id = ""

func _on_acknowledge_response(response: Dictionary) -> void:
	var code: int = int(response.get("responseCode", -1))
	DebugLog.log("[PurchaseStore] acknowledge_purchase_response code=%d" % code)

# ── Public API ─────────────────────────────────────────────────────────────────

func set_username(username: String) -> void:
	_current_username = username
	RingStore.sync_equipped_to_shared_stash(username)
	_sync_purchased_rings_to_stash()

func is_purchased(product_id: String) -> bool:
	if not PURCHASABLE.has(product_id):
		return true
	if CHARACTER_PRODUCTS.has(product_id) and AdminStore.is_admin(_current_username):
		return true
	return _load().has(product_id)

## Launch the billing flow. Listen to purchase_success / purchase_failed signals for the result.
## On PC/editor (no plugin) grants immediately so the UI can be tested.
func purchase(product_id: String) -> void:
	if _billing == null:
		DebugLog.log("[PurchaseStore] Dev mode — granting '%s' directly" % product_id)
		_grant(product_id)
		purchase_success.emit(product_id)
		return
	if not _pending_id.is_empty():
		DebugLog.log("[PurchaseStore] Purchase already in progress for '%s'" % _pending_id)
		return
	_pending_id = product_id
	_billing.purchase(product_id)

func is_ring_product(product_id: String) -> bool:
	return RING_PRODUCTS.has(product_id)

func ring_product_to_ring(product_id: String) -> Dictionary:
	if not RING_PRODUCTS.has(product_id):
		return {}
	var ring: Dictionary = (RING_PRODUCTS[product_id] as Dictionary).duplicate(true)
	ring["id"] = product_id
	ring["store_only"] = true
	return RingStore.normalize_ring(ring)

# ── Storage helpers ────────────────────────────────────────────────────────────

func _grant(product_id: String) -> void:
	var purchased := _load()
	if not purchased.has(product_id):
		purchased.append(product_id)
		_save(purchased)
		DebugLog.log("[PurchaseStore] Granted '%s'" % product_id)
	if is_ring_product(product_id) and not _current_username.is_empty():
		RingStore.ensure_ring_in_stash(_current_username, ring_product_to_ring(product_id))

func _sync_purchased_rings_to_stash() -> void:
	if _current_username.is_empty():
		return
	var purchased: Array = _load()
	for product in purchased:
		var product_id: String = product as String
		if is_ring_product(product_id):
			RingStore.ensure_ring_in_stash(_current_username, ring_product_to_ring(product_id))

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
