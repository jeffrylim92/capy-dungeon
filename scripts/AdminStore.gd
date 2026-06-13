class_name AdminStore
extends RefCounted

## Admin / developer bypass.
## Any account whose username matches ADMIN_USERNAMES (case-insensitive) is
## treated as an admin: all IAP characters are unlocked and the Brown Capy
## unlock requirement is bypassed.
##
## To add or remove admin accounts, edit the ADMIN_USERNAMES array below.

const ADMIN_USERNAMES: Array[String] = [
	"admin",
	"dev",
]

static func is_admin(username: String) -> bool:
	return ADMIN_USERNAMES.has(username.strip_edges().to_lower())
