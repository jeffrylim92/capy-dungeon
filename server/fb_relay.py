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

import os
import urllib.parse

import httpx
from fastapi import FastAPI, Query
from fastapi.responses import HTMLResponse, RedirectResponse

app = FastAPI()

# Config
FB_APP_ID            = os.environ.get("FB_APP_ID",            "1572914337762590")
FB_APP_SECRET        = os.environ.get("FB_APP_SECRET",        "12cc1b8eedbb212f94112b8c8ebe97d6")
GOOGLE_CLIENT_ID     = os.environ.get("GOOGLE_CLIENT_ID",     "")
GOOGLE_CLIENT_SECRET = os.environ.get("GOOGLE_CLIENT_SECRET", "")
RELAY_BASE           = os.environ.get("RELAY_BASE_URL",       "https://capy-dungeon.onrender.com")
DEEP_LINK            = "capydungeon://auth/callback"


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
    params = {
        "provider": "facebook",
        "id":       profile.get("id",    ""),
        "name":     profile.get("name",  ""),
        "email":    profile.get("email", ""),
        "picture":  avatar,
        "state":    state,
    }
    return _deep_link_page(DEEP_LINK + "?" + urllib.parse.urlencode(params, quote_via=urllib.parse.quote))


@app.get("/google/callback")
async def google_callback(
    code:  str = Query(...),
    state: str = Query(""),
) -> HTMLResponse:
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

    params = {
        "provider": "google",
        "id":       profile.get("sub",     ""),
        "name":     profile.get("name",    ""),
        "email":    profile.get("email",   ""),
        "picture":  profile.get("picture", ""),
        "state":    state,
    }
    return _deep_link_page(DEEP_LINK + "?" + urllib.parse.urlencode(params, quote_via=urllib.parse.quote))
