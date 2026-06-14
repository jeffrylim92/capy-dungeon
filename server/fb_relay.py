#!/usr/bin/env python3
"""Capy Dungeon — Facebook OAuth relay server.

Flow
----
1. Mobile app opens browser:
     facebook.com/dialog/oauth?redirect_uri=RELAY_BASE/fb/callback&state=…
2. Facebook redirects here with  ?code=…&state=…
3. We exchange code → access token → user profile (server-side, secret never leaves server)
4. We redirect to:
     capydungeon://auth/callback?provider=facebook&id=…&name=…&email=…&state=…
5. The OS reopens Capy Dungeon; Main.gd calls SocialAuth.handle_deep_link(url)

Deploy to Render.com (free tier)
---------------------------------
1. Push this file to GitHub (any repo, public or private).
2. render.com → New → Web Service → connect repo → set Root Directory to  server/
3. Build command : pip install -r requirements.txt
4. Start command : uvicorn fb_relay:app --host 0.0.0.0 --port $PORT
5. Add environment variables (Render dashboard → Environment):
      FB_APP_ID       = 1572914337762590
      FB_APP_SECRET   = 12cc1b8eedbb212f94112b8c8ebe97d6
      RELAY_BASE_URL  = https://<your-service-name>.onrender.com
6. After first deploy, copy the service URL into FACEBOOK_RELAY_URL in SocialAuth.gd.
7. Add  https://<your-service-name>.onrender.com/fb/callback
   as a Valid OAuth Redirect URI in the Facebook developer dashboard.
"""

import os
import urllib.parse

import httpx
from fastapi import FastAPI, Query
from fastapi.responses import RedirectResponse

app = FastAPI()

# ── Config ────────────────────────────────────────────────────────────────────
# Set via environment variables in production; fall back to dev values here.
FB_APP_ID     = os.environ.get("FB_APP_ID",     "1572914337762590")
FB_APP_SECRET = os.environ.get("FB_APP_SECRET", "12cc1b8eedbb212f94112b8c8ebe97d6")
RELAY_BASE    = os.environ.get("RELAY_BASE_URL", "https://capy-dungeon.onrender.com")
DEEP_LINK     = "capydungeon://auth/callback"

# ── Routes ────────────────────────────────────────────────────────────────────

@app.get("/health")
async def health() -> dict:
    return {"status": "ok", "service": "capy-fb-relay"}


@app.get("/fb/callback")
async def fb_callback(
    code:  str = Query(..., description="Authorization code from Facebook"),
    state: str = Query("",  description="CSRF state token from the app"),
) -> RedirectResponse:
    redirect_uri = f"{RELAY_BASE}/fb/callback"

    async with httpx.AsyncClient(timeout=10.0) as client:
        # 1. Exchange code for access token
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
            return RedirectResponse(
                url=f"{DEEP_LINK}?error={urllib.parse.quote(err_msg)}&state={urllib.parse.quote(state)}",
                status_code=302,
            )

        # 2. Fetch user profile (id, name, email, avatar)
        profile_resp = await client.get(
            "https://graph.facebook.com/v18.0/me",
            params={
                "fields":       "id,name,email,picture.type(large)",
                "access_token": access_token,
            },
        )
        profile = profile_resp.json()

    # 3. Build the deep-link redirect back to the app
    avatar = profile.get("picture", {}).get("data", {}).get("url", "")
    params = {
        "provider": "facebook",
        "id":       profile.get("id",    ""),
        "name":     profile.get("name",  ""),
        "email":    profile.get("email", ""),
        "picture":  avatar,
        "state":    state,
    }
    deep_link_url = DEEP_LINK + "?" + urllib.parse.urlencode(
        params, quote_via=urllib.parse.quote
    )
    return RedirectResponse(url=deep_link_url, status_code=302)
