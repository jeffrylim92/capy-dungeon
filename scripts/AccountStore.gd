class_name AccountStore
extends RefCounted

## Local-only account store. Persists to user://accounts.json with SHA-256
## hashed passwords. This is a prototype — not a substitute for real auth.

const ACCOUNTS_PATH := "user://accounts.json"
const MIN_USERNAME_LEN := 3
const MIN_PASSWORD_LEN := 4

## Dev account credentials — grants all IAP without payment
const DEV_USERNAME := "devadmin"
const DEV_PASSWORD := "dev12345"

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
	var u := username.strip_edges()
	var key := u.to_lower()
	if key.is_empty():
		return null
	# Check for hardcoded dev account
	if key == DEV_USERNAME.to_lower() and password == DEV_PASSWORD:
		return {
			"username": DEV_USERNAME,
			"display_name": "Dev Admin",
			"favorite_capy": "",
			"is_dev": true,
			"created_at": Time.get_datetime_string_from_system(true),
		}
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

	var email: String = String(profile.get("email", "")).strip_edges().to_lower()
	var display: String = String(profile.get("display_name", "Capy Player")).strip_edges()
	if display.is_empty():
		display = "Capy Player"

	# Stable account key derived from the provider identity
	var social_key: String = ("social_" + provider + "_" + provider_id).to_lower()
	var accounts := _load_all()
	var canonical_key: String = _canonical_social_account_key(accounts, social_key, email)

	if accounts.has(social_key):
		if not canonical_key.is_empty() and canonical_key != social_key:
			_merge_social_accounts(accounts, social_key, canonical_key, provider, provider_id, email, display)
			if not _save_all(accounts):
				return null
			return accounts.get(canonical_key, null)
		var existing: Dictionary = accounts[social_key] as Dictionary
		_touch_social_account(existing, provider, provider_id, email, display)
		accounts[social_key] = existing
		if not _save_all(accounts):
			return null
		return existing

	if not canonical_key.is_empty() and accounts.has(canonical_key):
		var canonical: Dictionary = accounts[canonical_key] as Dictionary
		_touch_social_account(canonical, provider, provider_id, email, display)
		accounts[canonical_key] = canonical
		if not _save_all(accounts):
			return null
		return canonical

	# New user — auto-create an account
	var acc: Dictionary = {
		"username":     social_key,
		"display_name": display,
		"favorite_capy": "",
		"social_provider": provider,
		"social_provider_id": provider_id,
		"social_email":  email,
		"social_links": {provider: provider_id},
		# No password fields — social accounts can't be used with the manual form
		"created_at": Time.get_datetime_string_from_system(true),
	}
	accounts[social_key] = acc
	if not _save_all(accounts):
		return null
	return acc

static func _canonical_social_account_key(accounts: Dictionary, social_key: String, email: String) -> String:
	if not email.is_empty():
		var best_key: String = ""
		var best_score: int = -1
		for key_variant in accounts.keys():
			var key: String = String(key_variant)
			var acc: Dictionary = accounts.get(key, {}) as Dictionary
			var acc_email: String = String(acc.get("social_email", "")).strip_edges().to_lower()
			if acc_email != email:
				continue
			var score: int = _account_merge_score(key)
			if score > best_score or (score == best_score and (best_key.is_empty() or key < best_key)):
				best_score = score
				best_key = key
		if not best_key.is_empty():
			return best_key
	if accounts.has(social_key):
		return social_key
	return ""

static func _account_merge_score(username: String) -> int:
	var score: int = 0
	var stats: Dictionary = StatsStore.get_all_for_user(username)
	score += stats.size() * 1000
	for char_id_variant in stats.keys():
		var entry: Dictionary = stats.get(char_id_variant, {}) as Dictionary
		score += int(entry.get("total_kills", 0))
		score += int(round(float(entry.get("best_survive_seconds", 0.0))))
	score += StatsStore.get_recent_match_records(username, 200).size() * 20
	return score

static func _touch_social_account(acc: Dictionary, provider: String, provider_id: String, email: String, display: String) -> void:
	acc["social_provider"] = provider
	acc["social_provider_id"] = provider_id
	if not email.is_empty():
		acc["social_email"] = email
	if not display.is_empty():
		acc["display_name"] = display
	var links: Dictionary = acc.get("social_links", {}) as Dictionary
	links[provider] = provider_id
	acc["social_links"] = links

static func _merge_social_accounts(accounts: Dictionary, from_key: String, into_key: String, provider: String, provider_id: String, email: String, display: String) -> void:
	if not accounts.has(into_key):
		return
	var into_acc: Dictionary = accounts[into_key] as Dictionary
	_touch_social_account(into_acc, provider, provider_id, email, display)
	accounts[into_key] = into_acc
	StatsStore.merge_user_local_data(into_key, from_key)
	accounts.erase(from_key)

