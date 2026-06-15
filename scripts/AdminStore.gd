class_name AdminStore
extends RefCounted

const ADMIN_USERNAMES: Array[String] = []

static func is_admin(username: String) -> bool:
	return ADMIN_USERNAMES.has(username.strip_edges().to_lower())
