# Storyloom — Claude Code Reference

## Project
Storyloom is an iOS app (SwiftUI + SwiftData + Supabase) for preserving and sharing family stories. Storytellers write, record narration, and attach images to stories; readers access them via invite codes.

**Stack:** SwiftUI · SwiftData · Supabase (auth, db, storage, realtime) · RevenueCat (planned) · Resend email · Vercel (storyloom.live)  
**Repo:** https://github.com/Erik27UX/StoryLoom · **Bundle ID:** erikfischer.Storyloom · **Team:** 3BJ76TZ89X

---

## 1. Workflow — GSD (Get Shit Done)
Reference: https://github.com/gsd-build/get-shit-done

Follow this loop for all non-trivial work:
1. **Discuss** → `/gsd-discuss-phase` — lock decisions before planning
2. **Plan** → `/gsd-plan-phase` — atomic tasks with verification conditions
3. **Execute** → `/gsd-execute-phase` — parallel where possible, one commit per task
4. **Verify** → `/gsd-verify-work` — test before shipping
5. **Ship** → `/gsd-ship`

**Quick fixes** (bugs, copy edits, small tweaks): use `/gsd-quick "task"` — no full phase machinery needed.  
**Start of session:** run `/gsd-progress` to see where we left off.  
**Lost context:** run `/gsd-resume-work`.

---

## 2. Coding Principles — Karpathy Guidelines
Reference: https://github.com/forrestchang/andrej-karpathy-skills

### Think Before Coding
Don't assume. Don't hide confusion. Surface tradeoffs.
- State assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them — don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

### Simplicity First
Minimum code that solves the problem. Nothing speculative.
- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" that wasn't requested.
- If you write 200 lines and it could be 50, rewrite it.

### Surgical Changes
Touch only what you must. Clean up only your own mess.
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- Every changed line should trace directly to the user's request.

### Goal-Driven Execution
Define success criteria. Loop until verified.
- Transform tasks into verifiable goals before starting.
- For multi-step tasks, state a brief plan with verification checkpoints.

---

## 3. Swift Rules — Everything Claude Code
Reference: https://github.com/affaan-m/everything-claude-code (rules/swift/)

### Coding Style
- Prefer `let` over `var`; default to `struct`, use `class` only for reference semantics
- Follow Apple API Design Guidelines — clarity at point of use, name by role not type
- Enable Swift 6 strict concurrency checking; favour `Sendable` value types
- Use actors for shared mutable state instead of locks or dispatch queues
- Use Swift 6 typed throws with pattern matching for error handling

### Patterns
- Protocol-oriented design: focused protocols with extensions for shared defaults
- Value types for data models; enums with associated values for distinct states
- Actor pattern for shared mutable state (no manual synchronisation needed)
- Dependency injection: pass protocol-typed dependencies with default implementations

### Security
- Store tokens and passwords in **Keychain**, never `UserDefaults`
- Never hardcode secrets in source — decompilation tools extract them trivially
- Don't disable App Transport Security (ATS)
- Validate and sanitise all user input, deep link data, and clipboard content before processing
- Use `URL(string:)` with proper validation — never force-unwrap URL initialisation

---

## 4. UI/UX Principles
Reference: https://github.com/nextlevelbuilder/ui-ux-pro-max-skill

- Minimum text contrast **4.5:1** in light mode
- Smooth transitions **150–300ms** for state changes
- Touch targets sized for finger interaction (minimum 44×44pt)
- Micro-interactions for user feedback on actions
- Soft shadows and subtle depth for premium feel
- Avoid harsh animations, neon colours, or "AI gradient" aesthetics
- Design is industry-specific — Storyloom is warm, personal, family-oriented (cream/brown palette, serif-adjacent type)

---

## 5. Development Skills — Superpowers
Reference: https://github.com/obra/superpowers

Install in Claude Code: `/plugin install superpowers@claude-plugins-official`

Key workflow additions:
- **Test-first**: write failing test → watch it fail → write minimal code → pass → commit
- **YAGNI + DRY**: no speculative features, no premature abstraction
- Use `/plan` before executing complex changes
- Use `/code-review` after execution, before shipping

---

## 6. Memory — claude-mem
Reference: https://github.com/thedotmack/claude-mem  
**Status: Installed** — memory builds passively from each session.

- Worker must be running: `npx claude-mem start`
- Web viewer: http://localhost:37701
- Search past sessions: use the `mem-search` skill in any prompt
- Tag sensitive content with `<private>` to exclude from memory
- Memory injection starts from the second session onward
- To run a full codebase ingest: `/learn-codebase` (optional, ~5 min)

**Disabling temporarily:** set `CLAUDE_MEM_WELCOME_HINT_ENABLED=false` or stop the worker.

---

## How to disable any of these
To stop following a reference, comment it out or delete its section from this file. Takes effect next session. For claude-mem specifically: `npx claude-mem stop` stops the worker; to fully uninstall run `npx claude-mem uninstall`.
