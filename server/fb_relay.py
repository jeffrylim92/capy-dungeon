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
import os
import sqlite3
import threading
import time
import urllib.parse
from datetime import datetime, timezone

import httpx
from fastapi import FastAPI, Query
from fastapi.responses import HTMLResponse
from pydantic import BaseModel

app = FastAPI()

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
        import psycopg2
        from psycopg2.extras import RealDictCursor
        conn = psycopg2.connect(_DATABASE_URL, cursor_factory=RealDictCursor)
        return conn
    conn = sqlite3.connect(_DB_PATH, check_same_thread=False)
    conn.row_factory = sqlite3.Row
    return conn


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
                updated_at        TEXT    DEFAULT ''
            )
        """)
        # Migrate older tables missing the stats_json column
        try:
            _execute(conn, "ALTER TABLE leaderboard ADD COLUMN stats_json TEXT DEFAULT '{}'")
        except Exception:
            pass
        conn.commit()
        conn.close()


_db_init()


class StatsSubmit(BaseModel):
    username: str
    display_name: str
    total_kills: int = 0
    best_survive_seconds: float = 0.0
    best_kill_character: str = ""
    best_survive_character: str = ""
    stats_json: dict = {}  # full per-character stats for cloud backup


@app.post("/stats/submit")
async def stats_submit(body: StatsSubmit) -> dict:
    username = body.username.strip().lower()
    if not username:
        return {"ok": False, "error": "missing username"}
    now = datetime.now(timezone.utc).isoformat()
    stats_blob = _json.dumps(body.stats_json, ensure_ascii=False)
    ph = _PH
    with _db_lock:
        conn = _db_connect()
        row = _fetchone(conn, f"SELECT * FROM leaderboard WHERE username = {ph}", (username,))
        if row:
            new_kills   = max(body.total_kills, row["total_kills"])
            new_survive = max(body.best_survive_seconds, row["best_survive_sec"])
            kill_char   = body.best_kill_character    if body.total_kills            >= row["total_kills"]    else row["best_kill_char"]
            surv_char   = body.best_survive_character if body.best_survive_seconds   >= row["best_survive_sec"] else row["best_survive_char"]
            existing_blob = row["stats_json"] if row["stats_json"] else "{}"
            new_blob = stats_blob if body.stats_json else existing_blob
            _execute(conn,
                f"UPDATE leaderboard SET display_name={ph},total_kills={ph},best_survive_sec={ph},"
                f"best_kill_char={ph},best_survive_char={ph},stats_json={ph},updated_at={ph} WHERE username={ph}",
                (body.display_name, new_kills, new_survive, kill_char, surv_char, new_blob, now, username),
            )
        else:
            _execute(conn,
                f"INSERT INTO leaderboard "
                f"(username,display_name,total_kills,best_survive_sec,best_kill_char,best_survive_char,stats_json,updated_at)"
                f" VALUES ({ph},{ph},{ph},{ph},{ph},{ph},{ph},{ph})",
                (username, body.display_name, body.total_kills, body.best_survive_seconds,
                 body.best_kill_character, body.best_survive_character, stats_blob, now),
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
        row = _fetchone(conn, f"SELECT stats_json FROM leaderboard WHERE username = {ph}", (uname,))
        conn.close()
    if not row or not row["stats_json"]:
        return {"ok": True, "stats": {}}
    try:
        data = _json.loads(row["stats_json"])
    except Exception:
        data = {}
    return {"ok": True, "stats": data}


@app.get("/stats/leaderboard/kills")
async def leaderboard_kills(limit: int = 10) -> dict:
    limit = min(max(limit, 1), 50)
    ph = _PH
    with _db_lock:
        conn = _db_connect()
        rows = _fetchall(conn,
            f"SELECT display_name, total_kills, best_kill_char "
            f"FROM leaderboard ORDER BY total_kills DESC LIMIT {ph}", (limit,)
        )
        conn.close()
    return {
        "entries": [
            {"rank": i + 1, "display_name": r["display_name"],
             "value": r["total_kills"], "character": r["best_kill_char"]}
            for i, r in enumerate(rows)
        ]
    }


@app.get("/stats/leaderboard/survive")
async def leaderboard_survive(limit: int = 10) -> dict:
    limit = min(max(limit, 1), 50)
    ph = _PH
    with _db_lock:
        conn = _db_connect()
        rows = _fetchall(conn,
            f"SELECT display_name, best_survive_sec, best_survive_char "
            f"FROM leaderboard ORDER BY best_survive_sec DESC LIMIT {ph}", (limit,)
        )
        conn.close()
    return {
        "entries": [
            {"rank": i + 1, "display_name": r["display_name"],
             "value": r["best_survive_sec"], "character": r["best_survive_char"]}
            for i, r in enumerate(rows)
        ]
    }

# Config
FB_APP_ID            = os.environ.get("FB_APP_ID",            "1572914337762590")
FB_APP_SECRET        = os.environ.get("FB_APP_SECRET",        "12cc1b8eedbb212f94112b8c8ebe97d6")
GOOGLE_CLIENT_ID     = os.environ.get("GOOGLE_CLIENT_ID",     "")
GOOGLE_CLIENT_SECRET = os.environ.get("GOOGLE_CLIENT_SECRET", "")
RELAY_BASE           = os.environ.get("RELAY_BASE_URL",       "https://capy-dungeon.onrender.com")
DEEP_LINK            = "capydungeon://auth/callback"

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


@app.get("/health")
async def health() -> dict:
    return {"status": "ok", "service": "capy-oauth-relay"}


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
