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

### 5. Wire up the triggers

⚠️ **The dashboard's Database Webhooks feature does not work on this
project** — this project is missing the internal `supabase_functions`
schema it depends on (confirmed: `SELECT nspname FROM pg_namespace WHERE
nspname = 'supabase_functions'` returns no rows). Both the "Supabase Edge
Functions" and plain "HTTP Request" options in **Database → Webhooks →
Create a new webhook** fail with a 400 on trigger creation. Don't use that
UI — use section 16 of `supabase_security_migration.sql` instead, which
calls `net.http_post()` directly from a plain Postgres trigger (same
effect, doesn't depend on the missing schema).

Before running section 16:

1. Make sure `pg_net` is enabled:
   ```sql
   CREATE EXTENSION IF NOT EXISTS pg_net WITH SCHEMA extensions;
   ```
2. Store the shared secret in **Vault** (run once yourself with the real
   value — never commit the real value to this file or to
   `supabase_security_migration.sql`):
   ```sql
   select vault.create_secret(
     '<the value you set as WEBHOOK_SECRET above>',
     'notify_activity_webhook_secret',
     'Shared secret checked by the notify-activity edge function'
   );
   ```
3. Run section 16 of `supabase_security_migration.sql`. It creates one
   trigger function (`public.notify_activity_webhook()`) and 5 triggers:

   | # | Table     | Event  |
   |---|-----------|--------|
   | 1 | comments  | Insert |
   | 2 | questions | Insert |
   | 3 | questions | Update |
   | 4 | stories   | Insert |
   | 5 | stories   | Update |

To sanity-check the pipeline without touching real data, call
`net.http_post()` directly with a synthetic payload and check
`net._http_response` for a `200`/`"ok"` — see this function's git history
for the exact diagnostic query used during setup.

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
