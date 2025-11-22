# Jellyfin SSO Integration for Mobile App

## Overview
This document describes the SSO integration between the Streamflix mobile app, Keycloak, and Jellyfin.

## Current Implementation

### Mobile App Flow
1. User clicks "Sign In" button
2. Keycloak OAuth login via `keycloak_wrapper` package
3. App receives Keycloak tokens (access_token, id_token, refresh_token)
4. App needs to exchange Keycloak token for Jellyfin session

### Problem
Jellyfin's SSO plugin is designed for web browser-based OAuth flows with redirects. Mobile apps need a different approach since they can't easily handle browser redirects and cookie-based sessions.

## Required Backend API Endpoint

The backend team needs to provide a token exchange endpoint:

### Endpoint Specification

```
POST /api/jellyfin/token
```

**Headers:**
```
Authorization: Bearer <keycloak_access_token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "device_id": "streamflix-tv-001",
  "device_name": "StreamFlix TV App",
  "client_version": "1.0.0"
}
```

**Success Response (200 OK):**
```json
{
  "access_token": "<jellyfin_access_token>",
  "user_id": "<jellyfin_user_id>",
  "server_id": "<jellyfin_server_id>",
  "user": {
    "name": "User Display Name",
    "has_configured_password": false,
    "has_configured_easy_password": false
  }
}
```

**Error Response (401 Unauthorized):**
```json
{
  "error": "invalid_token",
  "error_description": "Keycloak token is invalid or expired"
}
```

## Backend Implementation Guide

The backend endpoint should:

1. **Validate Keycloak Token**
   ```python
   from services.shared.auth import verify_bearer

   async def jellyfin_token_exchange(authorization: str):
       # Validate Keycloak token
       user_data = await verify_bearer(authorization)
       username = user_data.get('preferred_username')
       email = user_data.get('email')
   ```

2. **Check if Jellyfin User Exists**
   ```python
   import httpx

   jellyfin_url = "http://tv.ozzu.world:8096"

   # Get all users (requires admin token)
   response = await httpx.get(
       f"{jellyfin_url}/Users",
       headers={"X-Emby-Token": admin_token}
   )
   ```

3. **Create Jellyfin User if Needed (via SSO)**
   - If user doesn't exist, trigger SSO user provisioning
   - Jellyfin SSO plugin will create user automatically on first SSO login
   - Alternatively, create user programmatically:
   ```python
   await httpx.post(
       f"{jellyfin_url}/Users/New",
       headers={"X-Emby-Token": admin_token},
       json={
           "Name": username,
           "AuthenticationProviderId": "SSO-Auth",  # Mark as SSO user
       }
   )
   ```

4. **Generate Jellyfin Session Token**
   ```python
   # Option A: Use Jellyfin's AuthenticateByName with SSO flag
   response = await httpx.post(
       f"{jellyfin_url}/Users/AuthenticateByName",
       headers={
           "X-Emby-Authorization": 'MediaBrowser Client="StreamFlix", Device="TV", DeviceId="...", Version="1.0.0"'
       },
       json={
           "Username": username,
           "Pw": "",  # SSO users may not have passwords
       }
   )

   # Option B: Use admin token to create session directly
   response = await httpx.post(
       f"{jellyfin_url}/Sessions",
       headers={"X-Emby-Token": admin_token},
       json={
           "UserId": user_id,
           "DeviceId": device_id,
           "DeviceName": device_name,
       }
   )
   ```

5. **Return Jellyfin Token to Mobile App**
   ```python
   return {
       "access_token": response.json()["AccessToken"],
       "user_id": response.json()["User"]["Id"],
       "server_id": response.json()["ServerId"],
   }
   ```

## Alternative: Direct SSO Flow (If Backend API Not Available)

If the backend team cannot provide the API endpoint, the mobile app can use WebView to complete the SSO flow:

1. Open Jellyfin SSO URL in WebView: `https://tv.ozzu.world/sso/OID/start/keycloak`
2. Jellyfin redirects to Keycloak OAuth
3. Keycloak recognizes existing session, auto-completes auth
4. Keycloak redirects back to Jellyfin
5. Jellyfin creates session and redirects to success URL
6. Extract session token from cookies/URL
7. Close WebView and use token for API requests

However, this approach is less reliable and user-friendly than a backend token exchange endpoint.

## Mobile App Changes

The app currently attempts both approaches:

1. **Primary:** Call backend API endpoint `/api/jellyfin/token` with Keycloak token
2. **Fallback:** Try direct SSO endpoint `/sso/OID/r/keycloak`
3. **Last Resort:** Use stored credentials if available

See `lib/services/auth_service.dart:226-335` for implementation.

## Testing

Once the backend endpoint is deployed, test with:

```bash
# 1. Get Keycloak token
TOKEN=$(curl -X POST "https://idp.ozzu.world/realms/allsafe/protocol/openid-connect/token" \
  -d "client_id=streamflix-tv-app" \
  -d "grant_type=password" \
  -d "username=test" \
  -d "password=testpass" \
  | jq -r '.access_token')

# 2. Exchange for Jellyfin token
curl -X POST "https://api.ozzu.world/api/jellyfin/token" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"device_id": "test", "device_name": "Test", "client_version": "1.0.0"}'
```

## Questions for Backend Team

1. ✅ Has Jellyfin SSO plugin been configured with Keycloak?
2. ❓ What is the SSO provider name in Jellyfin? (default: "keycloak")
3. ❓ Can you provide the `/api/jellyfin/token` endpoint as specified above?
4. ❓ How are Jellyfin users provisioned? Auto-create on first SSO login?
5. ❓ What roles/permissions should new users have by default?

## Resources

- Jellyfin SSO Plugin: https://github.com/9p4/jellyfin-plugin-sso
- Keycloak OIDC Docs: https://www.keycloak.org/docs/latest/securing_apps/#_oidc
- Backend Auth Module: `/home/user/June/June/services/shared/auth.py`
