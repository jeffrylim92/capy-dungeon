extends Node

## Tracks in-app purchased job characters and drives the Google Play Billing flow.
## Registered as the "PurchaseStore" autoload so all scripts access it as a global.
##
## Uses the GodotGooglePlayBilling v3.x addon (Godot 4.x):
##   addons/GodotGooglePlayBilling/BillingClient.gd
## Enable the addon in Project → Project Settings → Plugins.

const PATH := "user://purchases.json"

const PURCHASABLE: Array[String] = ["capy_wizard", "capy_archer", "capy_assassin"]

const PRICES: Dictionary = {
	"capy_wizard":   "$2.99",
	"capy_archer":   "$2.99",
	"capy_assassin": "$2.99",
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

func is_purchased(character_id: String) -> bool:
	if not PURCHASABLE.has(character_id):
		return true
	if AdminStore.is_admin(_current_username):
		return true
	return _load().has(character_id)

## Launch the billing flow. Listen to purchase_success / purchase_failed signals for the result.
## On PC/editor (no plugin) grants immediately so the UI can be tested.
func purchase(character_id: String) -> void:
	if _billing == null:
		DebugLog.log("[PurchaseStore] Dev mode — granting '%s' directly" % character_id)
		_grant(character_id)
		purchase_success.emit(character_id)
		return
	if not _pending_id.is_empty():
		DebugLog.log("[PurchaseStore] Purchase already in progress for '%s'" % _pending_id)
		return
	_pending_id = character_id
	_billing.purchase(character_id)

# ── Storage helpers ────────────────────────────────────────────────────────────

func _grant(character_id: String) -> void:
	var purchased := _load()
	if not purchased.has(character_id):
		purchased.append(character_id)
		_save(purchased)
		DebugLog.log("[PurchaseStore] Granted '%s'" % character_id)

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
