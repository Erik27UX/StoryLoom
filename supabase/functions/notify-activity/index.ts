// Storyloom — notify-activity Edge Function
//
// Sends real APNs push notifications when a storyteller's readers interact
// with their stories, or when a storyteller answers a reader's question.
// Triggered by Supabase Database Webhooks (configured in the dashboard —
// see supabase/functions/notify-activity/README.md for setup steps).
//
// Payload shapes handled (Database Webhook default format):
//   { type: "INSERT" | "UPDATE", table: string, record: {...}, old_record?: {...} }
//
// Events handled:
//   - INSERT on comments   -> notify the story owner (category NEW_COMMENT)
//   - INSERT on questions  -> notify the story owner (category NEW_COMMENT)
//   - UPDATE on questions, is_answered flips to true -> notify the asker (category QUESTION_ANSWERED)
//   - INSERT/UPDATE on stories, is_published becomes true -> notify every reader with story_access (category NEW_STORY)
//
// The payload keys sent to APNs (category, story_id) mirror exactly what
// NotificationManager.routeNotification() in the iOS app reads from a
// notification's userInfo, so tapping a push navigates to the right story
// the same way a local/foreground notification already does.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const WEBHOOK_SECRET = Deno.env.get("WEBHOOK_SECRET"); // shared secret set on each DB Webhook's custom header

const APNS_KEY_ID = Deno.env.get("APNS_KEY_ID")!;
const APNS_TEAM_ID = Deno.env.get("APNS_TEAM_ID")!;
const APNS_PRIVATE_KEY_PEM = Deno.env.get("APNS_PRIVATE_KEY")!; // full .p8 file contents
const APNS_BUNDLE_ID = Deno.env.get("APNS_BUNDLE_ID") ?? "erikfischer.Storyloom";
// "production" for TestFlight/App Store builds, "sandbox" for Xcode Debug-run builds.
const APNS_ENV = Deno.env.get("APNS_ENV") ?? "production";
const APNS_HOST =
  APNS_ENV === "sandbox" ? "api.sandbox.push.apple.com" : "api.push.apple.com";

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

// ---------------------------------------------------------------------------
// APNs auth token (JWT, ES256) — cached in memory and reused for its lifetime.
// Apple recommends not generating a fresh token more than once every ~20 min;
// a Supabase Edge Function instance may stay warm across several invocations,
// so caching here avoids needless re-signing without affecting correctness
// on cold starts (cache is simply empty then, and gets (re)built once).
// ---------------------------------------------------------------------------

let cachedToken: { jwt: string; issuedAt: number } | null = null;

function base64UrlEncode(bytes: Uint8Array): string {
  let str = "";
  for (const b of bytes) str += String.fromCharCode(b);
  return btoa(str).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

function pemToDer(pem: string): ArrayBuffer {
  const stripped = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\s+/g, "");
  const binary = atob(stripped);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return bytes.buffer;
}

async function getApnsJwt(): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  if (cachedToken && now - cachedToken.issuedAt < 60 * 30) {
    return cachedToken.jwt;
  }

  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToDer(APNS_PRIVATE_KEY_PEM),
    { name: "ECDSA", namedCurve: "P-256" },
    false,
    ["sign"],
  );

  const header = { alg: "ES256", kid: APNS_KEY_ID };
  const claims = { iss: APNS_TEAM_ID, iat: now };

  const encoder = new TextEncoder();
  const headerB64 = base64UrlEncode(encoder.encode(JSON.stringify(header)));
  const claimsB64 = base64UrlEncode(encoder.encode(JSON.stringify(claims)));
  const signingInput = `${headerB64}.${claimsB64}`;

  // Web Crypto's ECDSA signature for P-256 is the raw (r||s) 64-byte form,
  // which is exactly the format a JWS/JWT signature needs — no DER conversion.
  const signature = await crypto.subtle.sign(
    { name: "ECDSA", hash: "SHA-256" },
    key,
    encoder.encode(signingInput),
  );

  const jwt = `${signingInput}.${base64UrlEncode(new Uint8Array(signature))}`;
  cachedToken = { jwt, issuedAt: now };
  return jwt;
}

// ---------------------------------------------------------------------------
// Send a single push to one device token.
// ---------------------------------------------------------------------------

async function sendPush(
  deviceToken: string,
  category: "NEW_STORY" | "NEW_COMMENT" | "QUESTION_ANSWERED",
  title: string,
  body: string,
  storyId: string | null,
): Promise<void> {
  const jwt = await getApnsJwt();

  const payload: Record<string, unknown> = {
    aps: {
      alert: { title, body },
      sound: "default",
      category,
    },
    category,
  };
  if (storyId) payload.story_id = storyId;

  const res = await fetch(`https://${APNS_HOST}/3/device/${deviceToken}`, {
    method: "POST",
    headers: {
      "authorization": `bearer ${jwt}`,
      "apns-topic": APNS_BUNDLE_ID,
      "apns-push-type": "alert",
      "apns-priority": "10",
    },
    body: JSON.stringify(payload),
  });

  if (!res.ok) {
    const text = await res.text();
    console.error(`APNs send failed (${res.status}) for token ${deviceToken.slice(0, 8)}…: ${text}`);
  }
}

// ---------------------------------------------------------------------------
// Webhook payload types
// ---------------------------------------------------------------------------

interface WebhookPayload {
  type: "INSERT" | "UPDATE" | "DELETE";
  table: string;
  record: Record<string, unknown>;
  old_record?: Record<string, unknown>;
}

Deno.serve(async (req) => {
  // Fail closed: if WEBHOOK_SECRET isn't configured, refuse every request
  // rather than silently accepting unauthenticated ones.
  if (!WEBHOOK_SECRET || req.headers.get("x-webhook-secret") !== WEBHOOK_SECRET) {
    return new Response("Unauthorized", { status: 401 });
  }

  let payload: WebhookPayload;
  try {
    payload = await req.json();
  } catch {
    return new Response("Bad Request", { status: 400 });
  }

  try {
    switch (payload.table) {
      case "comments":
        if (payload.type === "INSERT") await handleNewComment(payload.record);
        break;

      case "questions":
        if (payload.type === "INSERT") {
          await handleNewQuestion(payload.record);
        } else if (payload.type === "UPDATE") {
          const wasAnswered = payload.old_record?.is_answered === true;
          const isAnswered = payload.record.is_answered === true;
          if (isAnswered && !wasAnswered) await handleQuestionAnswered(payload.record);
        }
        break;

      case "stories":
        // A story can be published either immediately at creation (INSERT)
        // or later via an edit (UPDATE) — handle both.
        if (payload.type === "INSERT") {
          if (payload.record.is_published === true) await handleStoryPublished(payload.record);
        } else if (payload.type === "UPDATE") {
          const wasPublished = payload.old_record?.is_published === true;
          const isPublished = payload.record.is_published === true;
          if (isPublished && !wasPublished) await handleStoryPublished(payload.record);
        }
        break;
    }
  } catch (err) {
    console.error("notify-activity handler error:", err);
    // Still return 200 — Supabase Webhooks retry on non-2xx, and a transient
    // push failure shouldn't cause repeated re-delivery of the same event.
  }

  return new Response("ok", { status: 200 });
});

// ---------------------------------------------------------------------------
// Event handlers
// ---------------------------------------------------------------------------

async function pushTokenFor(userId: string): Promise<string | null> {
  const { data } = await supabase
    .from("profiles")
    .select("push_token")
    .eq("id", userId)
    .maybeSingle();
  return (data?.push_token as string | undefined) ?? null;
}

async function handleNewComment(record: Record<string, unknown>) {
  const storyId = record.story_id as string;
  const commenterId = record.user_id as string;
  const commenterName = (record.user_name as string) ?? "Someone";
  const text = ((record.text as string) ?? "").slice(0, 80);

  const { data: story } = await supabase
    .from("stories")
    .select("owner_id")
    .eq("id", storyId)
    .maybeSingle();
  if (!story || story.owner_id === commenterId) return; // don't notify yourself

  const token = await pushTokenFor(story.owner_id as string);
  if (!token) return;

  await sendPush(
    token,
    "NEW_COMMENT",
    "New comment",
    text ? `${commenterName}: ${text}` : `${commenterName} left a comment`,
    storyId,
  );
}

async function handleNewQuestion(record: Record<string, unknown>) {
  const storyId = record.story_id as string;
  const askerId = record.user_id as string;
  const askerName = (record.user_name as string) ?? "Someone";
  const text = ((record.text as string) ?? "").slice(0, 80);

  const { data: story } = await supabase
    .from("stories")
    .select("owner_id")
    .eq("id", storyId)
    .maybeSingle();
  if (!story || story.owner_id === askerId) return;

  const token = await pushTokenFor(story.owner_id as string);
  if (!token) return;

  // Matches the client's local-notification behavior: new questions also
  // use the NEW_COMMENT category (see NotificationManager.handleNewActivityNotification).
  await sendPush(
    token,
    "NEW_COMMENT",
    "New question",
    text ? `${askerName}: ${text}` : `${askerName} asked a question`,
    storyId,
  );
}

async function handleQuestionAnswered(record: Record<string, unknown>) {
  const storyId = record.story_id as string;
  const askerId = record.user_id as string;
  const answerText = ((record.answer_text as string) ?? "").slice(0, 80);

  const token = await pushTokenFor(askerId);
  if (!token) return;

  await sendPush(
    token,
    "QUESTION_ANSWERED",
    "Your question was answered",
    answerText || "Open Storyloom to read the answer",
    storyId,
  );
}

async function handleStoryPublished(record: Record<string, unknown>) {
  const storyId = record.id as string;
  const title = (record.title as string) ?? "A new story";

  const { data: accessRows } = await supabase
    .from("story_access")
    .select("user_id")
    .eq("story_id", storyId);
  if (!accessRows || accessRows.length === 0) return;

  const uniqueUserIds = [...new Set(accessRows.map((r) => r.user_id as string))];

  for (const userId of uniqueUserIds) {
    const token = await pushTokenFor(userId);
    if (!token) continue;
    await sendPush(token, "NEW_STORY", "New story published", title, storyId);
  }
}
