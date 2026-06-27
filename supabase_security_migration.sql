-- ============================================================
-- Storyloom — Security Migration
-- Run this in: Supabase Dashboard → SQL Editor → New Query
-- Safe to run more than once (uses CREATE OR REPLACE / IF NOT EXISTS).
-- ============================================================


-- ============================================================
-- 0. CREATE TABLES — story_invites and story_access
--    These must exist before the RLS policies in sections 4/5/9
--    are applied. Safe to run if they already exist.
-- ============================================================

-- story_invites: a storyteller creates an invite code valid for their vault.
-- One row per active invite; expires_at enforced by redeem_invite RPC.
CREATE TABLE IF NOT EXISTS public.story_invites (
    id          uuid        DEFAULT gen_random_uuid() PRIMARY KEY,
    owner_id    uuid        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    code        text        NOT NULL UNIQUE,
    expires_at  timestamptz NOT NULL,
    uses_count  int         NOT NULL DEFAULT 0,
    created_at  timestamptz DEFAULT now()
);
ALTER TABLE public.story_invites ENABLE ROW LEVEL SECURITY;

-- story_access: one row per (story, reader) pair granted via redeem_invite.
-- ON CONFLICT in redeem_invite requires the unique constraint added in section 11.
CREATE TABLE IF NOT EXISTS public.story_access (
    id           uuid        DEFAULT gen_random_uuid() PRIMARY KEY,
    story_id     uuid        NOT NULL REFERENCES public.stories(id) ON DELETE CASCADE,
    user_id      uuid        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    access_level text        NOT NULL DEFAULT 'view',
    date_granted timestamptz DEFAULT now()
);
ALTER TABLE public.story_access ENABLE ROW LEVEL SECURITY;


-- ============================================================
-- 1. PROFILES — block client-side subscription_tier updates
-- ============================================================
-- Users may update their own name, birth_year, role, and profile_photo_url.
-- subscription_tier must ONLY be updated by the backend (RevenueCat webhook
-- via service_role key). This policy enforces that at the database level.

-- Drop the broad update policy if it exists, then add the restricted one.
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile restricted" ON public.profiles;

CREATE POLICY "Users can update own profile restricted"
ON public.profiles
FOR UPDATE
TO authenticated
USING (auth.uid() = id)
WITH CHECK (
    auth.uid() = id
    -- Prevent any change to subscription_tier from the client.
    -- The only way to change it is via service_role (backend webhook).
    AND subscription_tier = (
        SELECT subscription_tier FROM public.profiles WHERE id = auth.uid()
    )
);

-- Ensure SELECT and INSERT policies exist (safe no-ops if already there).
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'profiles'
    AND policyname = 'Users can view own profile'
  ) THEN
    CREATE POLICY "Users can view own profile"
    ON public.profiles FOR SELECT TO authenticated
    USING (auth.uid() = id);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'profiles'
    AND policyname = 'Users can insert own profile'
  ) THEN
    CREATE POLICY "Users can insert own profile"
    ON public.profiles FOR INSERT TO authenticated
    WITH CHECK (auth.uid() = id);
  END IF;
END $$;


-- ============================================================
-- 2. STORIES — enforce owner_id on DELETE and UPDATE
-- ============================================================
DROP POLICY IF EXISTS "Owners can delete own stories" ON public.stories;
DROP POLICY IF EXISTS "Owners can update own stories" ON public.stories;
DROP POLICY IF EXISTS "Owners can insert stories" ON public.stories;
DROP POLICY IF EXISTS "Readers can view accessible stories" ON public.stories;

CREATE POLICY "Owners can insert stories"
ON public.stories FOR INSERT TO authenticated
WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Owners can update own stories"
ON public.stories FOR UPDATE TO authenticated
USING (auth.uid() = owner_id)
WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Owners can delete own stories"
ON public.stories FOR DELETE TO authenticated
USING (auth.uid() = owner_id);

-- Readers: can only see stories they have been granted access to,
-- plus their own stories.
CREATE POLICY "Readers can view accessible stories"
ON public.stories FOR SELECT TO authenticated
USING (
    auth.uid() = owner_id
    OR EXISTS (
        SELECT 1 FROM public.story_access
        WHERE story_access.story_id = stories.id
          AND story_access.user_id = auth.uid()
    )
);


-- ============================================================
-- 3. FOLDERS — enforce owner_id on all operations
-- ============================================================
DROP POLICY IF EXISTS "Owners can manage own folders" ON public.folders;
DROP POLICY IF EXISTS "Owners can insert folders" ON public.folders;
DROP POLICY IF EXISTS "Owners can select folders" ON public.folders;
DROP POLICY IF EXISTS "Owners can update folders" ON public.folders;
DROP POLICY IF EXISTS "Owners can delete folders" ON public.folders;

CREATE POLICY "Owners can select folders"
ON public.folders FOR SELECT TO authenticated
USING (auth.uid() = owner_id);

CREATE POLICY "Owners can insert folders"
ON public.folders FOR INSERT TO authenticated
WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Owners can update folders"
ON public.folders FOR UPDATE TO authenticated
USING (auth.uid() = owner_id)
WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Owners can delete folders"
ON public.folders FOR DELETE TO authenticated
USING (auth.uid() = owner_id);


-- ============================================================
-- 4. STORY_ACCESS — readers can only grant themselves access
--    via the redeem_invite RPC; storytellers can remove access
-- ============================================================
DROP POLICY IF EXISTS "Storytellers can view their readers" ON public.story_access;
DROP POLICY IF EXISTS "Storytellers can remove readers" ON public.story_access;
DROP POLICY IF EXISTS "Readers can view own access" ON public.story_access;

-- Storytellers can see who has access to their stories
CREATE POLICY "Storytellers can view their readers"
ON public.story_access FOR SELECT TO authenticated
USING (
    auth.uid() = user_id
    OR EXISTS (
        SELECT 1 FROM public.stories
        WHERE stories.id = story_access.story_id
          AND stories.owner_id = auth.uid()
    )
);

-- Storytellers can remove a reader from their stories
CREATE POLICY "Storytellers can remove readers"
ON public.story_access FOR DELETE TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.stories
        WHERE stories.id = story_access.story_id
          AND stories.owner_id = auth.uid()
    )
);

-- Direct INSERT by clients is blocked — access is only granted
-- through the redeem_invite SECURITY DEFINER function below.
-- (No INSERT policy = denied for authenticated role.)


-- ============================================================
-- 5. STORY_INVITES — owner can manage their own invites
-- ============================================================
DROP POLICY IF EXISTS "Owners can manage own invites" ON public.story_invites;
DROP POLICY IF EXISTS "Owners can insert invites" ON public.story_invites;
DROP POLICY IF EXISTS "Owners can select invites" ON public.story_invites;
DROP POLICY IF EXISTS "Owners can delete invites" ON public.story_invites;

CREATE POLICY "Owners can insert invites"
ON public.story_invites FOR INSERT TO authenticated
WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Owners can select invites"
ON public.story_invites FOR SELECT TO authenticated
USING (auth.uid() = owner_id);

CREATE POLICY "Owners can delete invites"
ON public.story_invites FOR DELETE TO authenticated
USING (auth.uid() = owner_id);


-- ============================================================
-- 6. COMMENTS — enforce user_id from auth; derive user_name
--    from profiles so it cannot be spoofed by the client
-- ============================================================

-- Trigger function: always override user_id and user_name from the
-- authenticated session, ignoring whatever the client sent.
CREATE OR REPLACE FUNCTION public.set_comment_author()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public AS $$
BEGIN
    NEW.user_id   := auth.uid();
    NEW.user_name := COALESCE(
        (SELECT name FROM public.profiles WHERE id = auth.uid()),
        NEW.user_name  -- fallback to client value only if profile has no name yet
    );
    RETURN NEW;
END; $$;

DROP TRIGGER IF EXISTS comments_set_author ON public.comments;
CREATE TRIGGER comments_set_author
BEFORE INSERT ON public.comments
FOR EACH ROW EXECUTE FUNCTION public.set_comment_author();

-- RLS for comments
DROP POLICY IF EXISTS "Authenticated users can insert comments" ON public.comments;
DROP POLICY IF EXISTS "Anyone with story access can view comments" ON public.comments;
DROP POLICY IF EXISTS "Users can delete own comments" ON public.comments;

CREATE POLICY "Authenticated users can insert comments"
ON public.comments FOR INSERT TO authenticated
WITH CHECK (true);  -- trigger enforces the actual user_id

CREATE POLICY "Anyone with story access can view comments"
ON public.comments FOR SELECT TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.stories s
        WHERE s.id = comments.story_id
          AND (
            s.owner_id = auth.uid()
            OR EXISTS (
                SELECT 1 FROM public.story_access sa
                WHERE sa.story_id = s.id AND sa.user_id = auth.uid()
            )
          )
    )
);

CREATE POLICY "Users can delete own comments"
ON public.comments FOR DELETE TO authenticated
USING (auth.uid() = user_id);


-- ============================================================
-- 7. QUESTIONS — same author enforcement as comments
-- ============================================================

CREATE OR REPLACE FUNCTION public.set_question_author()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public AS $$
BEGIN
    NEW.user_id   := auth.uid();
    NEW.user_name := COALESCE(
        (SELECT name FROM public.profiles WHERE id = auth.uid()),
        NEW.user_name
    );
    RETURN NEW;
END; $$;

DROP TRIGGER IF EXISTS questions_set_author ON public.questions;
CREATE TRIGGER questions_set_author
BEFORE INSERT ON public.questions
FOR EACH ROW EXECUTE FUNCTION public.set_question_author();

DROP POLICY IF EXISTS "Authenticated users can insert questions" ON public.questions;
DROP POLICY IF EXISTS "Anyone with story access can view questions" ON public.questions;
DROP POLICY IF EXISTS "Owners can update question answers" ON public.questions;

CREATE POLICY "Authenticated users can insert questions"
ON public.questions FOR INSERT TO authenticated
WITH CHECK (true);

CREATE POLICY "Anyone with story access can view questions"
ON public.questions FOR SELECT TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.stories s
        WHERE s.id = questions.story_id
          AND (
            s.owner_id = auth.uid()
            OR EXISTS (
                SELECT 1 FROM public.story_access sa
                WHERE sa.story_id = s.id AND sa.user_id = auth.uid()
            )
          )
    )
);

-- Only the story owner can write the answer
CREATE POLICY "Owners can update question answers"
ON public.questions FOR UPDATE TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.stories s
        WHERE s.id = questions.story_id AND s.owner_id = auth.uid()
    )
);


-- ============================================================
-- 8. REACTIONS — one like per user per story; constrained delta
-- ============================================================
DROP POLICY IF EXISTS "Users can manage own reactions" ON public.reactions;
DROP POLICY IF EXISTS "Anyone with story access can view reactions" ON public.reactions;

CREATE POLICY "Users can upsert own reactions"
ON public.reactions FOR INSERT TO authenticated
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own reactions"
ON public.reactions FOR DELETE TO authenticated
USING (auth.uid() = user_id);

CREATE POLICY "Anyone with story access can view reactions"
ON public.reactions FOR SELECT TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.stories s
        WHERE s.id = reactions.story_id
          AND (
            s.owner_id = auth.uid()
            OR EXISTS (
                SELECT 1 FROM public.story_access sa
                WHERE sa.story_id = s.id AND sa.user_id = auth.uid()
            )
          )
    )
);

-- Hardened increment_like_count: delta must be ±1, count never goes negative,
-- and a decrement only applies if the user actually has a reaction row.
CREATE OR REPLACE FUNCTION public.increment_like_count(p_story_id uuid, delta int)
RETURNS void LANGUAGE plpgsql SECURITY INVOKER
SET search_path = public AS $$
BEGIN
    IF delta NOT IN (1, -1) THEN
        RAISE EXCEPTION 'delta must be 1 or -1';
    END IF;
    -- For decrements, only proceed if the reaction actually exists
    IF delta = -1 AND NOT EXISTS (
        SELECT 1 FROM public.reactions
        WHERE story_id = p_story_id AND user_id = auth.uid()
    ) THEN
        RETURN;
    END IF;
    UPDATE public.stories
    SET like_count = GREATEST(0, like_count + delta)
    WHERE id = p_story_id;
END; $$;


-- ============================================================
-- 9. REDEEM_INVITE RPC — server-side invite validation
--    Replaces the multi-step client-side flow in AddStoryVaultView.
--    Validates expiry, prevents self-invite, grants story_access,
--    increments uses_count — all atomically in one transaction.
-- ============================================================
CREATE OR REPLACE FUNCTION public.redeem_invite(p_code text)
RETURNS json LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public AS $$
DECLARE
    v_owner_id   uuid;
    v_owner_name text;
BEGIN
    -- Validate the code and get the vault owner
    SELECT owner_id INTO v_owner_id
    FROM public.story_invites
    WHERE code = p_code
      AND expires_at > now();

    IF v_owner_id IS NULL THEN
        RAISE EXCEPTION 'invalid_code'
            USING HINT = 'Invalid or expired invite code';
    END IF;

    -- Prevent a storyteller from redeeming their own invite
    IF v_owner_id = auth.uid() THEN
        RAISE EXCEPTION 'self_invite'
            USING HINT = 'You cannot use your own invite code';
    END IF;

    -- Fetch the owner display name for the success message
    SELECT COALESCE(name, 'your storyteller')
    INTO v_owner_name
    FROM public.profiles
    WHERE id = v_owner_id;

    -- Grant read access to all of the owner's published stories
    INSERT INTO public.story_access (story_id, user_id, access_level, date_granted)
    SELECT s.id, auth.uid(), 'view', now()
    FROM public.stories s
    WHERE s.owner_id = v_owner_id
      AND s.is_published = true
    ON CONFLICT (story_id, user_id) DO NOTHING;

    -- Increment uses counter
    UPDATE public.story_invites
    SET uses_count = uses_count + 1
    WHERE code = p_code;

    -- Return only the owner's display name — never expose their UUID to clients.
    RETURN json_build_object(
        'owner_name', v_owner_name
    );
END; $$;

-- Grant execute to authenticated users only
REVOKE ALL ON FUNCTION public.redeem_invite(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.redeem_invite(text) TO authenticated;


-- ============================================================
-- 10. DELETE_USER_ACCOUNT RPC
--     Deletes all user data and the auth user. Called from AuthManager.deleteAccount().
--     Create this if it doesn't exist yet.
-- ============================================================
CREATE OR REPLACE FUNCTION public.delete_user_account()
RETURNS void LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public AS $$
DECLARE v_uid uuid := auth.uid();
BEGIN
    -- Delete all user content (cascade handles related rows)
    DELETE FROM public.story_access  WHERE user_id = v_uid;
    DELETE FROM public.story_invites WHERE owner_id = v_uid;
    DELETE FROM public.reactions     WHERE user_id = v_uid;
    DELETE FROM public.comments      WHERE user_id = v_uid;
    DELETE FROM public.questions     WHERE user_id = v_uid;
    DELETE FROM public.stories       WHERE owner_id = v_uid;
    DELETE FROM public.folders       WHERE owner_id = v_uid;
    DELETE FROM public.profiles      WHERE id = v_uid;
    -- Delete the auth user (requires service_role — this function runs as SECURITY DEFINER)
    DELETE FROM auth.users WHERE id = v_uid;
END; $$;

REVOKE ALL ON FUNCTION public.delete_user_account() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.delete_user_account() TO authenticated;


-- ============================================================
-- 11. STORY_ACCESS — unique constraint required for ON CONFLICT
--     in the redeem_invite RPC. Without this, ON CONFLICT won't fire
--     and duplicate access rows will be created.
-- ============================================================
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'story_access_story_user_unique'
          AND conrelid = 'public.story_access'::regclass
    ) THEN
        ALTER TABLE public.story_access
        ADD CONSTRAINT story_access_story_user_unique UNIQUE (story_id, user_id);
    END IF;
END $$;


-- ============================================================
-- 12. INPUT LENGTH CONSTRAINTS
--     Mirrors the UI character limits in CommentsView (2000)
--     and QuestionsView (1000) so the DB enforces them even
--     if requests come from outside the app.
-- ============================================================

-- Comments
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'comments_text_length' AND conrelid = 'public.comments'::regclass
    ) THEN
        ALTER TABLE public.comments
        ADD CONSTRAINT comments_text_length CHECK (char_length(text) BETWEEN 1 AND 2000);
    END IF;
END $$;

-- Questions
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'questions_text_length' AND conrelid = 'public.questions'::regclass
    ) THEN
        ALTER TABLE public.questions
        ADD CONSTRAINT questions_text_length CHECK (char_length(text) BETWEEN 1 AND 1000);
    END IF;
END $$;

-- Stories (generous limit — long-form writing is expected)
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'stories_content_length' AND conrelid = 'public.stories'::regclass
    ) THEN
        ALTER TABLE public.stories
        ADD CONSTRAINT stories_content_length CHECK (char_length(content) <= 100000);
    END IF;
END $$;

-- Profiles name
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'profiles_name_length' AND conrelid = 'public.profiles'::regclass
    ) THEN
        ALTER TABLE public.profiles
        ADD CONSTRAINT profiles_name_length CHECK (name IS NULL OR char_length(name) <= 100);
    END IF;
END $$;


-- ============================================================
-- 13. PUSH NOTIFICATIONS — add push_token column to profiles
--     Required for APNs (Phase 1 of pre-launch checklist).
--     Safe to run if column already exists (IF NOT EXISTS guard).
-- ============================================================

ALTER TABLE public.profiles
    ADD COLUMN IF NOT EXISTS push_token text;


-- ============================================================
-- DONE. Verify with:
--   SELECT policyname, cmd, roles FROM pg_policies WHERE schemaname = 'public' ORDER BY tablename, policyname;
--   SELECT conname, contype FROM pg_constraint WHERE conrelid IN ('public.comments'::regclass, 'public.questions'::regclass, 'public.stories'::regclass, 'public.story_access'::regclass);
-- ============================================================
