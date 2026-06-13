class_name AccountStore
extends RefCounted

## Local-only account store. Persists to user://accounts.json with SHA-256
## hashed passwords. This is a prototype — not a substitute for real auth.

const ACCOUNTS_PATH := "user://accounts.json"
const MIN_USERNAME_LEN := 3
const MIN_PASSWORD_LEN := 4

static func _hash(password: String, salt: String) -> String:
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update((salt + ":" + password).to_utf8_buffer())
	return ctx.finish().hex_encode()

static func _load_all() -> Dictionary:
	if not FileAccess.file_exists(ACCOUNTS_PATH):
		return {}
	var f := FileAccess.open(ACCOUNTS_PATH, FileAccess.READ)
	if f == null:
		return {}
	var text := f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed

static func _save_all(data: Dictionary) -> bool:
	var f := FileAccess.open(ACCOUNTS_PATH, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(data, "\t"))
	f.close()
	return true

static func exists(username: String) -> bool:
	return _load_all().has(username.to_lower())

## Returns an error message, or empty string on success.
static func register(username: String, password: String, confirm: String, display_name: String, favorite_capy: String) -> String:
	var u := username.strip_edges()
	var d := display_name.strip_edges()
	if u.length() < MIN_USERNAME_LEN:
		return "Username must be at least %d characters." % MIN_USERNAME_LEN
	if not u.is_valid_identifier() and not _is_simple_handle(u):
		return "Username may only contain letters, numbers and underscore."
	if password.length() < MIN_PASSWORD_LEN:
		return "Password must be at least %d characters." % MIN_PASSWORD_LEN
	if password != confirm:
		return "Passwords do not match."
	if d.is_empty():
		return "Display name is required."
	var key := u.to_lower()
	var accounts := _load_all()
	if accounts.has(key):
		return "That username is already taken."
	var salt := "%d-%d" % [Time.get_ticks_usec(), randi()]
	accounts[key] = {
		"username": u,
		"display_name": d,
		"favorite_capy": favorite_capy,
		"password_salt": salt,
		"password_hash": _hash(password, salt),
		"created_at": Time.get_datetime_string_from_system(true),
	}
	if not _save_all(accounts):
		return "Could not save account file."
	return ""

## Returns the account dictionary on success, or null on failure.
static func login(username: String, password: String) -> Variant:
	var key := username.strip_edges().to_lower()
	if key.is_empty():
		return null
	var accounts := _load_all()
	if not accounts.has(key):
		return null
	var acc: Dictionary = accounts[key]
	var expected: String = acc.get("password_hash", "")
	var salt: String = acc.get("password_salt", "")
	if _hash(password, salt) != expected:
		return null
	return acc

static func _is_simple_handle(s: String) -> bool:
	for c in s:
		if not (c.is_valid_int() or (c >= "a" and c <= "z") or (c >= "A" and c <= "Z") or c == "_"):
			return false
	return true

## Social login: find or create an account tied to a social provider.
## `profile` is the dict emitted by SocialAuth.auth_success.
## Returns the account Dictionary on success, or null if something went wrong.
static func login_or_register_social(profile: Dictionary) -> Variant:
	var provider:    String = String(profile.get("provider", ""))
	var provider_id: String = String(profile.get("provider_id", ""))
	if provider.is_empty() or provider_id.is_empty():
		return null

	# Stable account key derived from the provider identity
	var social_key: String = ("social_" + provider + "_" + provider_id).to_lower()
	var accounts := _load_all()

	if accounts.has(social_key):
		# Existing social account — return it directly (no password check needed)
		return accounts[social_key]

	# New user — auto-create an account
	var display: String = String(profile.get("display_name", "Capy Player")).strip_edges()
	if display.is_empty():
		display = "Capy Player"
	# Append a short suffix so the display name is unique enough
	var now_suffix: String = str(Time.get_ticks_msec() % 10000)
	var acc: Dictionary = {
		"username":     social_key,
		"display_name": display,
		"favorite_capy": "",
		"social_provider": provider,
		"social_provider_id": provider_id,
		"social_email":  String(profile.get("email", "")),
		# No password fields — social accounts can't be used with the manual form
		"created_at": Time.get_datetime_string_from_system(true),
	}
	accounts[social_key] = acc
	if not _save_all(accounts):
		return null
	return acc

