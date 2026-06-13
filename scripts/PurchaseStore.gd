class_name PurchaseStore
extends RefCounted

## Tracks in-app purchased job characters.
## In a production build, hook purchase() into the platform billing SDK
## (Google Play Billing / Apple StoreKit / etc.) and only call _grant()
## after receiving a verified receipt. For now grants immediately (demo mode).

const PATH := "user://purchases.json"

const PURCHASABLE: Array[String] = ["capy_wizard", "capy_archer", "capy_assassin"]

const PRICES: Dictionary = {
	"capy_wizard":   "$2.99",
	"capy_archer":   "$2.99",
	"capy_assassin": "$2.99",
}

static func _load() -> Array:
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

static func _save(purchased: Array) -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(purchased))
	f.close()

static func is_purchased(character_id: String) -> bool:
	if not PURCHASABLE.has(character_id):
		return true  # non-purchasable = always available
	# Admin accounts bypass IAP
	if AdminStore.is_admin(_current_username):
		return true
	return _load().has(character_id)

## Must be set by Main.gd before CharacterSelect is shown (same way
## account_username is passed to CharacterSelect / StatsStore).
static var _current_username: String = ""

static func set_username(username: String) -> void:
	_current_username = username

static func purchase(character_id: String) -> void:
	## TODO (production): launch platform billing flow here.
	## Only call _grant() after receipt verification.
	_grant(character_id)

static func _grant(character_id: String) -> void:
	var purchased := _load()
	if not purchased.has(character_id):
		purchased.append(character_id)
		_save(purchased)
