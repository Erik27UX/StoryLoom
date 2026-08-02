# notify-activity — APNs push Edge Function

Sends real push notifications (app backgrounded/killed) for:
- New comment on your story → notifies you (the storyteller)
- New question on your story → notifies you (the storyteller)
- Your question gets answered → notifies you (the reader who asked)
- A storyteller publishes a new story → notifies every reader who has access

Foreground/in-app banners already work via Realtime + local notifications
(`NotificationManager.observeActivityEvents()`) — this function covers the
case where the recipient isn't currently in the app.

## One-time setup

### 1. Install the Supabase CLI (if you don't have it)

```bash
brew install supabase/tap/supabase
```

### 2. Link this project (run from the repo root)

```bash
supabase login
supabase link --project-ref snczqjrrlymkzgkjxbce
```

### 3. Deploy the function

```bash
supabase functions deploy notify-activity --no-verify-jwt
```

`--no-verify-jwt` is required because Database Webhooks call this function
directly, not through a logged-in user's session — the `WEBHOOK_SECRET`
check inside the function (see below) is what protects it instead.

### 4. Set secrets

Run these from your terminal — the `.p8` file's contents go straight from
disk into Supabase and are never typed or pasted anywhere else:

```bash
supabase secrets set APNS_KEY_ID=F6HFL7T2S6
supabase secrets set APNS_TEAM_ID=3BJ76TZ89X
supabase secrets set APNS_BUNDLE_ID=erikfischer.Storyloom
supabase secrets set APNS_PRIVATE_KEY="$(cat '/Users/erikfischer/Desktop/Storyloom project/sec/AuthKey_F6HFL7T2S6.p8')"

# A random shared secret — generate one and set it both here and in each
# Database Webhook's custom header (step 5 below). Any long random string works:
supabase secrets set WEBHOOK_SECRET="$(openssl rand -hex 32)"
```

**APNS_ENV:** defaults to `production` (correct for TestFlight/App Store
builds). If you're testing pushes against an Xcode Debug-run build on a
real device before archiving, that build registers with Apple's *sandbox*
environment instead, and pushes must go to a different Apple endpoint. Only
if you hit that case:

```bash
supabase secrets set APNS_ENV=sandbox
```

Switch it back to `production` (or unset it) before shipping.

### 5. Configure Database Webhooks

In **Supabase Dashboard → Database → Webhooks → Create a new webhook**,
create three webhooks, all pointing at:

```
https://snczqjrrlymkzgkjxbce.supabase.co/functions/v1/notify-activity
```

For each one, add a custom HTTP header:
```
x-webhook-secret: <the same value you set as WEBHOOK_SECRET above>
```

| # | Table     | Events           |
|---|-----------|------------------|
| 1 | comments  | Insert           |
| 2 | questions | Insert, Update   |
| 3 | stories   | Insert, Update   |

That's it — no changes needed on the iOS app side. `NotificationManager`
already uploads the device's push token to `profiles.push_token` once the
Push Notifications capability + permission are in place, and this function
reads that same column.

## Verifying it works

1. Have two test accounts — one storyteller, one reader (on separate
   physical devices or with the app backgrounded on one).
2. Publish a story from the storyteller account → the reader's device
   should get a push.
3. Comment as the reader → the storyteller's device should get a push.
4. Answer the reader's question as the storyteller → the reader's device
   should get a push.

Check **Supabase Dashboard → Edge Functions → notify-activity → Logs** if a
push doesn't arrive — failed APNs sends are logged there with the HTTP
status Apple returned (e.g. `BadDeviceToken` usually means a sandbox/
production environment mismatch — see APNS_ENV above).
