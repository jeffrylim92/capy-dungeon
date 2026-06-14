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
import os
import time
import urllib.parse

import httpx
from fastapi import FastAPI, Query
from fastapi.responses import HTMLResponse

app = FastAPI()

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


def _deep_link_page(url: str) -> HTMLResponse:
    """Return an HTML page that opens a custom URL scheme via JS.
    Direct HTTP 302 to capydungeon:// is mishandled by some mobile browsers
    (Chrome treats it as a relative URL). JS window.location is reliable."""
    escaped = url.replace("'", "%27")
    html = f"""<!DOCTYPE html>
<html><head><meta charset='utf-8'>
<meta name='viewport' content='width=device-width'>
<title>Signing in to Capy Dungeon...</title>
<script>
window.location.replace('{escaped}');
</script>
</head>
<body style='font-family:sans-serif;text-align:center;padding:60px;background:#1a1a2e;color:#eee'>
<h2 style='color:#4ade80'>Signed in!</h2>
<p>Returning to Capy Dungeon...</p>
<p><a href='{escaped}' style='color:#60a5fa'>Tap here if the app didn't open</a></p>
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
