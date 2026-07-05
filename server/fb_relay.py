#!/usr/bin/env python3
"""Capy Dungeon — OAuth relay server (Facebook + Google mobile).

Flow (both providers)
---------------------
1. Mobile app opens browser at provider auth URL with redirect_uri = RELAY_BASE/<provider>/callback
2. Provider redirects here with ?code=...&state=...
3. Relay exchanges code -> access token -> user profile (server-side, secrets never leave server)
4. Relay redirects to:
     capydungeon://auth/callback?provider=<p>&id=...&name=...&email=...&picture=...&state=...
5. The OS reopens Capy Dungeon; Main.gd calls SocialAuth.handle_deep_link(url)

Environment variables (set in Render dashboard):
    FB_APP_ID            = 1572914337762590
    FB_APP_SECRET        = <facebook app secret>
    GOOGLE_CLIENT_ID     = <web application client ID>
    GOOGLE_CLIENT_SECRET = <web application client secret>
    RELAY_BASE_URL       = https://capy-dungeon.onrender.com
"""

import asyncio
import json as _json
import logging
import os
import sqlite3
import threading
import time
import urllib.parse
from datetime import datetime, timezone
from pathlib import Path

import httpx
from fastapi import FastAPI, Query
from fastapi.responses import HTMLResponse
from pydantic import BaseModel

app = FastAPI()
logger = logging.getLogger("capy-relay")
_ROOT_DIR = Path(__file__).resolve().parent.parent
_DOCS_DIR = _ROOT_DIR / "docs"

# ── Database layer ─────────────────────────────────────────────────────────────
# Set DATABASE_URL (PostgreSQL) in Render env vars for persistent storage.
# Without it, falls back to SQLite in /tmp (resets on redeploy).
_DATABASE_URL = os.environ.get("DATABASE_URL", "")
_USE_PG = bool(_DATABASE_URL)
_DB_PATH = os.environ.get("LEADERBOARD_DB", "/tmp/capy_leaderboard.db")
_db_lock = threading.Lock()

# Placeholder token differs between drivers
_PH = "%s" if _USE_PG else "?"


def _db_connect():
    if _USE_PG:
        import psycopg
        from psycopg.rows import dict_row
        conn = psycopg.connect(_DATABASE_URL, row_factory=dict_row)
        return conn
    conn = sqlite3.connect(_DB_PATH, check_same_thread=False)
    conn.row_factory = sqlite3.Row
    return conn


def _rollback_if_needed(conn) -> None:
    try:
        conn.rollback()
    except Exception:
        pass


def _column_exists(conn, table: str, column: str) -> bool:
    if _USE_PG:
        row = _fetchone(
            conn,
            "SELECT 1 FROM information_schema.columns WHERE table_name = %s AND column_name = %s",
            (table, column),
        )
        return bool(row)
    row = _fetchone(conn, f"PRAGMA table_info({table})")
    rows = _fetchall(conn, f"PRAGMA table_info({table})")
    for info in rows:
        name = info[1] if not isinstance(info, dict) else info.get("name", "")
        if str(name) == column:
            return True
    return False


def _table_exists(conn, table: str) -> bool:
    if _USE_PG:
        row = _fetchone(
            conn,
            "SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name = %s",
            (table,),
        )
        return bool(row)
    row = _fetchone(conn, "SELECT 1 FROM sqlite_master WHERE type='table' AND name=?", (table,))
    return bool(row)


def _ensure_column(conn, table: str, column: str, column_sql: str) -> None:
    if _column_exists(conn, table, column):
        return
    try:
        _execute(conn, f"ALTER TABLE {table} ADD COLUMN {column} {column_sql}")
        conn.commit()
    except Exception:
        _rollback_if_needed(conn)
        raise


def _execute(conn, sql: str, params: tuple = ()):
    """Run a statement, handling the cursor difference between psycopg2 and sqlite3."""
    if _USE_PG:
        cur = conn.cursor()
        cur.execute(sql, params)
        return cur
    return conn.execute(sql, params)


def _fetchone(conn, sql: str, params: tuple = ()):
    if _USE_PG:
        cur = conn.cursor()
        cur.execute(sql, params)
        return cur.fetchone()
    return conn.execute(sql, params).fetchone()


def _fetchall(conn, sql: str, params: tuple = ()):
    if _USE_PG:
        cur = conn.cursor()
        cur.execute(sql, params)
        return cur.fetchall()
    return conn.execute(sql, params).fetchall()


def _normalize_limit(limit: int, max_limit: int = 5000) -> int:
    """Return 0 for 'all rows', else clamp to a safe positive max."""
    if limit <= 0:
        return 0
    return min(max(limit, 1), max_limit)


def _db_init() -> None:
    with _db_lock:
        conn = _db_connect()
        _execute(conn, """
            CREATE TABLE IF NOT EXISTS leaderboard (
                username          TEXT PRIMARY KEY,
                display_name      TEXT NOT NULL,
                total_kills       INTEGER DEFAULT 0,
                best_survive_sec  REAL    DEFAULT 0.0,
                best_kill_char    TEXT    DEFAULT '',
                best_survive_char TEXT    DEFAULT '',
                stats_json        TEXT    DEFAULT '{}',
                rings_json        TEXT    DEFAULT '{}',
                ring_stash_json   TEXT    DEFAULT '[]',
                artifact_stash_json TEXT  DEFAULT '[]',
                artifact_equipped_json TEXT DEFAULT '{}',
                updated_at        TEXT    DEFAULT ''
            )
        """)
        _execute(conn, """
            CREATE TABLE IF NOT EXISTS leaderboard_runs (
                username         TEXT NOT NULL,
                display_name     TEXT NOT NULL,
                character        TEXT DEFAULT '',
                kills            INTEGER DEFAULT 0,
                survive_sec      REAL DEFAULT 0.0,
                match_ts         INTEGER DEFAULT 0,
                rings_json       TEXT DEFAULT '{}',
                artifacts_json   TEXT DEFAULT '{}',
                created_at       TEXT DEFAULT '',
                PRIMARY KEY (username, match_ts, character, kills, survive_sec)
            )
        """)
        _execute(conn, "CREATE INDEX IF NOT EXISTS idx_runs_kills ON leaderboard_runs(kills DESC)")
        _execute(conn, "CREATE INDEX IF NOT EXISTS idx_runs_survive ON leaderboard_runs(survive_sec DESC)")
        _execute(conn, "CREATE INDEX IF NOT EXISTS idx_runs_user ON leaderboard_runs(username)")
        _execute(conn, "CREATE INDEX IF NOT EXISTS idx_runs_character ON leaderboard_runs(character)")
        # Migrate older tables missing newer leaderboard columns.
        # Important for PostgreSQL: a failed ALTER aborts the transaction, so we
        # must detect column existence first or rollback between attempts.
        _ensure_column(conn, "leaderboard", "stats_json", "TEXT DEFAULT '{}'")
        _ensure_column(conn, "leaderboard", "best_kill_char", "TEXT DEFAULT ''")
        _ensure_column(conn, "leaderboard", "best_survive_char", "TEXT DEFAULT ''")
        _ensure_column(conn, "leaderboard", "rings_json", "TEXT DEFAULT '{}'")
        _ensure_column(conn, "leaderboard", "ring_stash_json", "TEXT DEFAULT '[]'")
        _ensure_column(conn, "leaderboard", "artifact_stash_json", "TEXT DEFAULT '[]'")
        _ensure_column(conn, "leaderboard", "artifact_equipped_json", "TEXT DEFAULT '{}'")
        conn.commit()
        conn.close()


_db_init()


class ClientErrorPayload(BaseModel):
    events: list = []
    game: str = ""
    version: str = ""


@app.post("/client-errors")
async def client_errors(payload: ClientErrorPayload) -> dict:
    # Accept client telemetry payloads so mobile clients don't spam 404 retries.
    try:
        count = len(payload.events) if isinstance(payload.events, list) else 0
        if count > 0:
            logger.warning("client-errors accepted: game=%s version=%s events=%d", payload.game, payload.version, count)
    except Exception:
        # Never fail this endpoint for logging payload shape issues.
        pass
    return {"ok": True}


class StatsSubmit(BaseModel):
    username: str
    display_name: str
    total_kills: int = 0
    best_survive_seconds: float = 0.0
    best_kill_character: str = ""
    best_survive_character: str = ""
    stats_json: dict = {}  # full per-character stats for cloud backup
    rings_json: dict = {}  # full per-character equipped ring slots for leaderboard display
    ring_stash_json: list = []
    artifact_stash_json: list = []
    artifact_equipped_json: dict = {}
    latest_match: dict = {}


class AccountDeleteRequest(BaseModel):
    username: str
    social_email: str = ""


def _best_kill_from_stats(stats: dict, fallback_kills: int = 0, fallback_char: str = "") -> tuple[int, str]:
    if not isinstance(stats, dict):
        return int(fallback_kills or 0), fallback_char or ""
    best_kills = 0
    best_char = ""
    for char_id, raw_entry in stats.items():
        if not isinstance(raw_entry, dict):
            continue
        kills = int(raw_entry.get("total_kills", 0) or 0)
        if kills > best_kills:
            best_kills = kills
            best_char = str(char_id)
    if best_kills <= 0 and not best_char:
        return int(fallback_kills or 0), fallback_char or ""
    return best_kills, best_char


def _row_best_kill(row) -> tuple[int, str]:
    stats = {}
    try:
        if row["stats_json"]:
            stats = _json.loads(row["stats_json"])
    except Exception:
        stats = {}
    return _best_kill_from_stats(stats, int(row["total_kills"] or 0), row["best_kill_char"] or "")


def _row_char_entry(stats: dict, char_id: str) -> dict:
    if not isinstance(stats, dict):
        return {}
    raw = stats.get(char_id, {})
    return raw if isinstance(raw, dict) else {}


def _row_kill_for_char(row, char_id: str) -> int:
    if not char_id:
        kills, _ = _row_best_kill(row)
        return kills
    stats = {}
    try:
        if row["stats_json"]:
            stats = _json.loads(row["stats_json"])
    except Exception:
        stats = {}
    entry = _row_char_entry(stats, char_id)
    return int(entry.get("total_kills", 0) or 0)


def _row_survive_for_char(row, char_id: str) -> float:
    if not char_id:
        return float(row["best_survive_sec"] or 0.0)
    stats = {}
    try:
        if row["stats_json"]:
            stats = _json.loads(row["stats_json"])
    except Exception:
        stats = {}
    entry = _row_char_entry(stats, char_id)
    return float(entry.get("best_survive_seconds", 0.0) or 0.0)


def _rings_for_character(row, char_id: str) -> dict:
    if not char_id:
        return {}
    try:
        rings_blob = row["rings_json"] if row["rings_json"] else "{}"
        all_rings = _json.loads(rings_blob)
    except Exception:
        all_rings = {}
    if not isinstance(all_rings, dict):
        return {}
    rings = all_rings.get(char_id, {})
    return rings if isinstance(rings, dict) else {}


def _json_blob(value: object, fallback: object):
    if isinstance(value, (dict, list)):
        return value
    if not value:
        return fallback
    try:
        parsed = _json.loads(value)
        if isinstance(fallback, dict):
            return parsed if isinstance(parsed, dict) else fallback
        if isinstance(fallback, list):
            return parsed if isinstance(parsed, list) else fallback
        return parsed
    except Exception:
        return fallback


def _run_entry_from_row(row, metric: str) -> dict:
    value = float(row["survive_sec"] or 0.0) if metric == "survive" else int(row["kills"] or 0)
    return {
        "username": row["username"],
        "display_name": row["display_name"],
        "value": value,
        "character": row["character"] or "",
        "rings": _json_blob(row.get("rings_json") if isinstance(row, dict) else row["rings_json"], {}),
        "artifacts": _json_blob(row.get("artifacts_json") if isinstance(row, dict) else row["artifacts_json"], {}),
        "match_ts": int(row.get("match_ts", 0) if isinstance(row, dict) else row["match_ts"]),
    }


@app.post("/stats/submit")
async def stats_submit(body: StatsSubmit) -> dict:
    username = body.username.strip().lower()
    if not username:
        return {"ok": False, "error": "missing username"}
    now = datetime.now(timezone.utc).isoformat()
    stats_blob = _json.dumps(body.stats_json, ensure_ascii=False)
    rings_blob = _json.dumps(body.rings_json, ensure_ascii=False)
    ring_stash_blob = _json.dumps(body.ring_stash_json, ensure_ascii=False)
    artifact_stash_blob = _json.dumps(body.artifact_stash_json, ensure_ascii=False)
    artifact_equipped_blob = _json.dumps(body.artifact_equipped_json, ensure_ascii=False)
    submitted_kills, submitted_kill_char = _best_kill_from_stats(
        body.stats_json,
        body.total_kills,
        body.best_kill_character,
    )
    ph = _PH
    with _db_lock:
        conn = _db_connect()
        row = _fetchone(conn, f"SELECT * FROM leaderboard WHERE username = {ph}", (username,))
        if row:
            existing_blob = row["stats_json"] if row["stats_json"] else "{}"
            existing_rings_blob = row["rings_json"] if row["rings_json"] else "{}"
            existing_ring_stash_blob = row["ring_stash_json"] if row["ring_stash_json"] else "[]"
            existing_artifact_stash_blob = row["artifact_stash_json"] if row["artifact_stash_json"] else "[]"
            existing_artifact_equipped_blob = row["artifact_equipped_json"] if row["artifact_equipped_json"] else "{}"
            existing_stats = {}
            try:
                existing_stats = _json.loads(existing_blob)
            except Exception:
                existing_stats = {}
            current_kills, current_kill_char = _best_kill_from_stats(
                existing_stats,
                row["total_kills"],
                row["best_kill_char"],
            )
            if body.stats_json:
                new_kills = submitted_kills
                kill_char = submitted_kill_char
            else:
                new_kills = max(submitted_kills, current_kills)
                kill_char = submitted_kill_char if submitted_kills >= current_kills else current_kill_char
            new_survive = max(body.best_survive_seconds, row["best_survive_sec"])
            surv_char   = body.best_survive_character if body.best_survive_seconds   >= row["best_survive_sec"] else row["best_survive_char"]
            new_blob = stats_blob if body.stats_json else existing_blob
            new_rings_blob = rings_blob if body.rings_json else existing_rings_blob
            new_ring_stash_blob = ring_stash_blob if body.ring_stash_json else existing_ring_stash_blob
            new_artifact_stash_blob = artifact_stash_blob if body.artifact_stash_json else existing_artifact_stash_blob
            new_artifact_equipped_blob = artifact_equipped_blob if body.artifact_equipped_json else existing_artifact_equipped_blob
            _execute(conn,
                f"UPDATE leaderboard SET display_name={ph},total_kills={ph},best_survive_sec={ph},"
                f"best_kill_char={ph},best_survive_char={ph},stats_json={ph},rings_json={ph},"
                f"ring_stash_json={ph},artifact_stash_json={ph},artifact_equipped_json={ph},updated_at={ph} WHERE username={ph}",
                (body.display_name, new_kills, new_survive, kill_char, surv_char, new_blob, new_rings_blob,
                 new_ring_stash_blob, new_artifact_stash_blob, new_artifact_equipped_blob, now, username),
            )
        else:
            _execute(conn,
                f"INSERT INTO leaderboard "
                f"(username,display_name,total_kills,best_survive_sec,best_kill_char,best_survive_char,stats_json,rings_json,"
                f"ring_stash_json,artifact_stash_json,artifact_equipped_json,updated_at)"
                f" VALUES ({ph},{ph},{ph},{ph},{ph},{ph},{ph},{ph},{ph},{ph},{ph},{ph})",
                (username, body.display_name, submitted_kills, body.best_survive_seconds,
                 submitted_kill_char, body.best_survive_character, stats_blob, rings_blob,
                 ring_stash_blob, artifact_stash_blob, artifact_equipped_blob, now),
            )

        latest: dict = body.latest_match if isinstance(body.latest_match, dict) else {}
        if latest:
            char_id: str = str(latest.get("character", "")).strip().lower()
            survive_sec: float = float(latest.get("survive_seconds", 0.0) or 0.0)
            kills: int = int(latest.get("kills", 0) or 0)
            match_ts: int = int(latest.get("ts", 0) or 0)
            rings_json = _json.dumps(latest.get("rings", {}) if isinstance(latest.get("rings", {}), dict) else {}, ensure_ascii=False)
            artifacts_json = _json.dumps(latest.get("artifacts", {}) if isinstance(latest.get("artifacts", {}), dict) else {}, ensure_ascii=False)
            if char_id and survive_sec > 0.0 and match_ts > 0:
                _execute(
                    conn,
                    f"INSERT INTO leaderboard_runs (username, display_name, character, kills, survive_sec, match_ts, rings_json, artifacts_json, created_at) "
                    f"VALUES ({ph},{ph},{ph},{ph},{ph},{ph},{ph},{ph},{ph}) "
                    f"ON CONFLICT DO NOTHING",
                    (username, body.display_name, char_id, kills, survive_sec, match_ts, rings_json, artifacts_json, now),
                )
        conn.commit()
        conn.close()
    return {"ok": True}


@app.get("/stats/user/{username}")
async def stats_user(username: str) -> dict:
    uname = username.strip().lower()
    if not uname:
        return {"ok": False, "stats": {}}
    ph = _PH
    with _db_lock:
        conn = _db_connect()
        row = _fetchone(
            conn,
            f"SELECT stats_json, rings_json, ring_stash_json, artifact_stash_json, artifact_equipped_json "
            f"FROM leaderboard WHERE username = {ph}",
            (uname,),
        )
        conn.close()
    if not row:
        return {"ok": True, "stats": {}, "rings_json": {}, "ring_stash": [], "artifact_stash": [], "artifact_equipped": {}}
    try:
        stats = _json.loads(row["stats_json"] if row["stats_json"] else "{}")
    except Exception:
        stats = {}
    try:
        rings = _json.loads(row["rings_json"] if row["rings_json"] else "{}")
    except Exception:
        rings = {}
    try:
        ring_stash = _json.loads(row["ring_stash_json"] if row["ring_stash_json"] else "[]")
    except Exception:
        ring_stash = []
    try:
        artifact_stash = _json.loads(row["artifact_stash_json"] if row["artifact_stash_json"] else "[]")
    except Exception:
        artifact_stash = []
    try:
        artifact_equipped = _json.loads(row["artifact_equipped_json"] if row["artifact_equipped_json"] else "{}")
    except Exception:
        artifact_equipped = {}
    return {
        "ok": True,
        "stats": stats if isinstance(stats, dict) else {},
        "rings_json": rings if isinstance(rings, dict) else {},
        "ring_stash": ring_stash if isinstance(ring_stash, list) else [],
        "artifact_stash": artifact_stash if isinstance(artifact_stash, list) else [],
        "artifact_equipped": artifact_equipped if isinstance(artifact_equipped, dict) else {},
    }


@app.post("/account/delete")
async def account_delete(body: AccountDeleteRequest) -> dict:
    username = body.username.strip().lower()
    social_email = body.social_email.strip().lower()
    if not username:
        return {"ok": False, "error": "missing username", "deleted": 0}

    keys: list[str] = [username]
    if social_email and social_email not in keys:
        keys.append(social_email)

    placeholders = ",".join([_PH] * len(keys))
    deleted: int = 0

    with _db_lock:
        conn = _db_connect()
        try:
            # Legacy leaderboard tables currently used by the game client.
            if _table_exists(conn, "leaderboard_runs"):
                cur = _execute(conn, f"DELETE FROM leaderboard_runs WHERE username IN ({placeholders})", tuple(keys))
                deleted += int(cur.rowcount or 0)
            if _table_exists(conn, "leaderboard"):
                cur = _execute(conn, f"DELETE FROM leaderboard WHERE username IN ({placeholders})", tuple(keys))
                deleted += int(cur.rowcount or 0)

            # New Supabase schema tables (if present).
            if _table_exists(conn, "users"):
                if social_email:
                    cur = _execute(conn, "DELETE FROM users WHERE username = %s OR email = %s" if _USE_PG else "DELETE FROM users WHERE username = ? OR email = ?", (username, social_email))
                else:
                    cur = _execute(conn, f"DELETE FROM users WHERE username = {_PH}", (username,))
                deleted += int(cur.rowcount or 0)

            conn.commit()
        except Exception as exc:
            _rollback_if_needed(conn)
            logger.exception("account_delete failed")
            return {"ok": False, "error": str(exc), "deleted": deleted}
        finally:
            conn.close()

    return {"ok": True, "deleted": deleted}


@app.get("/stats/leaderboard/kills")
async def leaderboard_kills(limit: int = 20, username: str = "", character: str = "") -> dict:
    try:
        limit = _normalize_limit(limit)
        user_entry = None
        uname = username.strip().lower()
        char_filter = character.strip().lower()
        ph = _PH
        with _db_lock:
            conn = _db_connect()
            if char_filter:
                rows = _fetchall(
                    conn,
                    f"SELECT username, display_name, character, kills, survive_sec, match_ts, rings_json, artifacts_json "
                    f"FROM leaderboard_runs WHERE character = {ph} ORDER BY kills DESC, match_ts ASC",
                    (char_filter,),
                )
            else:
                rows = _fetchall(
                    conn,
                    "SELECT username, display_name, character, kills, survive_sec, match_ts, rings_json, artifacts_json "
                    "FROM leaderboard_runs ORDER BY kills DESC, match_ts ASC",
                    (),
                )
            conn.close()

        ranked = []
        for row in rows:
            entry = _run_entry_from_row(row, "kills")
            if int(entry["value"]) < 0:
                continue
            ranked.append(entry)
        for i, entry in enumerate(ranked):
            entry["rank"] = i + 1
            if uname and entry["username"] == uname:
                user_entry = dict(entry)

        entries = ranked if limit == 0 else ranked[:limit]
        return {
            "entries": entries,
            "user_entry": user_entry,
        }
    except Exception as exc:
        logger.exception("leaderboard_kills failed")
        return {"entries": [], "user_entry": None, "ok": False, "error": str(exc)}


@app.get("/stats/leaderboard/survive")
async def leaderboard_survive(limit: int = 20, username: str = "", character: str = "") -> dict:
    try:
        limit = _normalize_limit(limit)
        user_entry = None
        uname = username.strip().lower()
        char_filter = character.strip().lower()
        ph = _PH
        with _db_lock:
            conn = _db_connect()
            if char_filter:
                rows = _fetchall(
                    conn,
                    f"SELECT username, display_name, character, kills, survive_sec, match_ts, rings_json, artifacts_json "
                    f"FROM leaderboard_runs WHERE character = {ph} ORDER BY survive_sec DESC, match_ts ASC",
                    (char_filter,),
                )
            else:
                rows = _fetchall(
                    conn,
                    "SELECT username, display_name, character, kills, survive_sec, match_ts, rings_json, artifacts_json "
                    "FROM leaderboard_runs ORDER BY survive_sec DESC, match_ts ASC",
                    (),
                )
            conn.close()

        ranked = []
        for row in rows:
            entry = _run_entry_from_row(row, "survive")
            if float(entry["value"]) <= 0.0:
                continue
            ranked.append(entry)
        for i, entry in enumerate(ranked):
            entry["rank"] = i + 1
            if uname and entry["username"] == uname:
                user_entry = dict(entry)

        entries = ranked if limit == 0 else ranked[:limit]
        return {
            "entries": entries,
            "user_entry": user_entry,
        }
    except Exception as exc:
        logger.exception("leaderboard_survive failed")
        return {"entries": [], "user_entry": None, "ok": False, "error": str(exc)}

# Config
FB_APP_ID            = os.environ.get("FB_APP_ID",            "1572914337762590")
FB_APP_SECRET        = os.environ.get("FB_APP_SECRET",        "12cc1b8eedbb212f94112b8c8ebe97d6")
GOOGLE_CLIENT_ID     = os.environ.get("GOOGLE_CLIENT_ID",     "")
GOOGLE_CLIENT_SECRET = os.environ.get("GOOGLE_CLIENT_SECRET", "")
RELAY_BASE           = os.environ.get("RELAY_BASE_URL",       "https://capy-dungeon.onrender.com")
DEEP_LINK            = "capydungeon://auth/callback"
ANDROID_PLAY_STORE_URL = os.environ.get(
    "ANDROID_PLAY_STORE_URL",
    "https://play.google.com/store/apps/details?id=com.capydungeon.game",
)


def _env_int(name: str, default: int = 0) -> int:
    try:
        return int(os.environ.get(name, str(default)))
    except Exception:
        return default


ANDROID_LATEST_VERSION_CODE = _env_int("ANDROID_LATEST_VERSION_CODE", 0)
ANDROID_MIN_SUPPORTED_VERSION_CODE = _env_int("ANDROID_MIN_SUPPORTED_VERSION_CODE", 0)

# ── State-keyed result cache ──────────────────────────────────────────────────
# Facebook's safety crawler hits the redirect URL before the user's browser,
# consuming the one-time OAuth code.  We cache the successful exchange result
# (keyed by `state`) for 5 minutes so repeated requests return the same deep
# link even after the code has been invalidated.
_CACHE_TTL   = 300          # seconds
_auth_cache: dict[str, tuple[str, float]] = {}   # state -> (url, expiry)
_state_locks: dict[str, asyncio.Lock]    = {}    # state -> Lock (one at a time)


def _cache_get(state: str) -> str | None:
    entry = _auth_cache.get(state)
    if entry and entry[1] > time.time():
        return entry[0]
    return None


def _cache_set(state: str, url: str) -> None:
    _auth_cache[state] = (url, time.time() + _CACHE_TTL)
    # Prune expired entries so memory doesn't grow unbounded
    now = time.time()
    stale = [k for k, v in list(_auth_cache.items()) if v[1] <= now]
    for k in stale:
        _auth_cache.pop(k, None)
        _state_locks.pop(k, None)


def _get_state_lock(state: str) -> asyncio.Lock:
    if state not in _state_locks:
        _state_locks[state] = asyncio.Lock()
    return _state_locks[state]


def _deep_link_page(deep_url: str) -> HTMLResponse:
    """Return an HTML page that opens Capy Dungeon via Chrome's intent:// URL scheme.

    Using intent:// is more reliable than window.location to capydungeon:// because
    Chrome on Android sometimes fires the intent without the data URI when using a
    raw custom scheme.  The intent:// format explicitly tells Chrome to construct a
    full Android intent including the data URI and the target package.

    Format:
      intent://auth/callback?...#Intent;scheme=capydungeon;package=com.capydungeon.game;end
    Chrome reconstructs data = "capydungeon://auth/callback?..." and Android routes
    it to GodotAppOAuthCallback → GodotApp via the registered intent filter.
    """
    redirect_url = deep_url
    if deep_url.startswith("capydungeon://"):
        # Strip the scheme prefix — intent:// carries scheme separately
        rest = deep_url[len("capydungeon://"):]   # e.g. "auth/callback?provider=..."
        fallback = urllib.parse.quote("https://capy-dungeon.onrender.com/health", safe="")
        redirect_url = (
            f"intent://{rest}"
            f"#Intent;scheme=capydungeon;package=com.capydungeon.game;"
            f"S.browser_fallback_url={fallback};end"
        )

    esc = lambda s: s.replace("'", "%27")
    html = f"""<!DOCTYPE html>
<html><head><meta charset='utf-8'>
<meta name='viewport' content='width=device-width'>
<title>Signing in to Capy Dungeon...</title>
<script>window.location.replace('{esc(redirect_url)}');</script>
</head>
<body style='font-family:sans-serif;text-align:center;padding:60px;background:#1a1a2e;color:#eee'>
<h2 style='color:#4ade80'>Signed in!</h2>
<p>Returning to Capy Dungeon&hellip;</p>
<p><a href='{esc(redirect_url)}' style='color:#60a5fa'>Tap here if the app did not open</a></p>
</body></html>"""
    return HTMLResponse(content=html)


def _read_doc_html(filename: str, fallback_title: str, fallback_body: str) -> str:
    path = _DOCS_DIR / filename
    if path.exists():
        try:
            return path.read_text(encoding="utf-8")
        except Exception:
            pass
    return (
        "<!DOCTYPE html><html><head><meta charset='utf-8'>"
        f"<title>{fallback_title}</title></head><body>"
        f"<h1>{fallback_title}</h1><p>{fallback_body}</p></body></html>"
    )


@app.api_route("/", methods=["GET", "HEAD"])
async def root():
    return {"status": "ok", "service": "capy-oauth-relay"}


@app.get("/privacy-policy")
@app.get("/privacy-policy.html")
async def privacy_policy_page() -> HTMLResponse:
    html = _read_doc_html(
        "privacy-policy.html",
        "Privacy Policy",
        "Privacy policy content is currently being updated.",
    )
    return HTMLResponse(content=html)


@app.get("/terms")
@app.get("/terms.html")
async def terms_page() -> HTMLResponse:
    html = _read_doc_html(
        "terms.html",
        "Terms and Conditions",
        "Terms and conditions content is currently being updated.",
    )
    return HTMLResponse(content=html)


@app.get("/delete-account")
@app.get("/delete-account.html")
async def delete_account_page() -> HTMLResponse:
    html = _read_doc_html(
        "delete-account.html",
        "Delete Account",
        "To request account deletion, please contact limweiye@hotmail.com.",
    )
    return HTMLResponse(content=html)

@app.api_route("/health", methods=["GET", "HEAD"])
async def health():
    return {"status": "ok", "service": "capy-oauth-relay"}


@app.get("/app/version/android")
async def app_version_android(current_version_code: int = Query(0, ge=0)) -> dict:
    latest = max(ANDROID_LATEST_VERSION_CODE, 0)
    minimum = max(ANDROID_MIN_SUPPORTED_VERSION_CODE, 0)
    required_threshold = max(latest, minimum)
    update_required = required_threshold > 0 and current_version_code < required_threshold
    message = (
        "A newer version is available. Please update from the Play Store to continue."
        if update_required
        else ""
    )
    return {
        "ok": True,
        "platform": "android",
        "current_version_code": current_version_code,
        "latest_version_code": latest,
        "min_supported_version_code": minimum,
        "update_required": update_required,
        "play_store_url": ANDROID_PLAY_STORE_URL,
        "message": message,
    }


@app.get("/fb/callback")
async def fb_callback(
    code:  str = Query(...),
    state: str = Query(""),
) -> HTMLResponse:
    # Serve from cache if already exchanged (handles Facebook bot pre-fetch)
    cached = _cache_get(state)
    if cached:
        return _deep_link_page(cached)

    async with _get_state_lock(state):
        # Re-check after acquiring lock (concurrent requests race)
        cached = _cache_get(state)
        if cached:
            return _deep_link_page(cached)

        redirect_uri = f"{RELAY_BASE}/fb/callback"
        async with httpx.AsyncClient(timeout=10.0) as client:
            token_resp = await client.get(
                "https://graph.facebook.com/v18.0/oauth/access_token",
                params={
                    "client_id":     FB_APP_ID,
                    "client_secret": FB_APP_SECRET,
                    "redirect_uri":  redirect_uri,
                    "code":          code,
                },
            )
            token_data = token_resp.json()
            access_token: str = token_data.get("access_token", "")
            if not access_token:
                err_msg = token_data.get("error", {}).get("message", "token_exchange_failed")
                return _deep_link_page(f"{DEEP_LINK}?error={urllib.parse.quote(err_msg)}&state={urllib.parse.quote(state)}")
            profile_resp = await client.get(
                "https://graph.facebook.com/v18.0/me",
                params={"fields": "id,name,email,picture.type(large)", "access_token": access_token},
            )
            profile = profile_resp.json()

        avatar = profile.get("picture", {}).get("data", {}).get("url", "")
        qs_params = {
            "provider": "facebook",
            "id":       profile.get("id",    ""),
            "name":     profile.get("name",  ""),
            "email":    profile.get("email", ""),
            "picture":  avatar,
            "state":    state,
        }
        deep_url = DEEP_LINK + "?" + urllib.parse.urlencode(qs_params, quote_via=urllib.parse.quote)
        _cache_set(state, deep_url)
        return _deep_link_page(deep_url)


@app.get("/google/callback")
async def google_callback(
    code:  str = Query(...),
    state: str = Query(""),
) -> HTMLResponse:
    # Serve from cache if already exchanged
    cached = _cache_get(state)
    if cached:
        return _deep_link_page(cached)

    async with _get_state_lock(state):
        cached = _cache_get(state)
        if cached:
            return _deep_link_page(cached)

        redirect_uri = f"{RELAY_BASE}/google/callback"
        async with httpx.AsyncClient(timeout=10.0) as client:
            token_resp = await client.post(
                "https://oauth2.googleapis.com/token",
                data={
                    "client_id":     GOOGLE_CLIENT_ID,
                    "client_secret": GOOGLE_CLIENT_SECRET,
                    "redirect_uri":  redirect_uri,
                    "grant_type":    "authorization_code",
                    "code":          code,
                },
            )
            token_data = token_resp.json()
            access_token: str = token_data.get("access_token", "")
            if not access_token:
                err_msg = token_data.get("error_description", token_data.get("error", "token_exchange_failed"))
                return _deep_link_page(f"{DEEP_LINK}?error={urllib.parse.quote(err_msg)}&state={urllib.parse.quote(state)}")
            profile_resp = await client.get(
                "https://openidconnect.googleapis.com/v1/userinfo",
                headers={"Authorization": f"Bearer {access_token}"},
            )
            profile = profile_resp.json()

        qs_params = {
            "provider": "google",
            "id":       profile.get("sub",     ""),
            "name":     profile.get("name",    ""),
            "email":    profile.get("email",   ""),
            "picture":  profile.get("picture", ""),
            "state":    state,
        }
        deep_url = DEEP_LINK + "?" + urllib.parse.urlencode(qs_params, quote_via=urllib.parse.quote)
        _cache_set(state, deep_url)
        return _deep_link_page(deep_url)
