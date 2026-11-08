# ✦ Vynora

An independent Discord-inspired browser messenger prototype with a dark UI, direct messages and a Supabase-based backend.

> **Status:** Experimental preview. The frontend is in this repository. The Supabase database migration is committed but **not yet deployed** to a verified project. Do not use the prototype for sensitive conversations.

## Open the app

- **Demo (local-only):** [GitHub Pages](https://silasnetwin.github.io/vynora/) — interface, test contacts and localStorage messages (not shared with other people).
- **Cloud (online accounts):** [Vynora Cloud](https://silasnetwin.github.io/vynora/cloud.html) — requires a configured and migrated Supabase project.

## Current features

| Feature | Demo | Cloud preview |
|---|---|---|
| Dark messenger UI | ✅ | ✅ |
| Direct-message chats | Local demo contacts | Signed-in accounts |
| Persist messages | Browser localStorage | PostgreSQL (after setup) |
| Register / login | — | Supabase Auth |
| Find users | Demo contacts | Searchable usernames |
| Realtime delivery | — | Postgres Changes + polling fallback |
| Private messages via RLS | — | Policies in SQL migration |
| Servers, voice, video, moderation | Mock / planned | Planned |

## Set up Supabase

See **[SUPABASE_SETUP.md](SUPABASE_SETUP.md)** for the complete guide. Key files:

- `cloud.html` — frontend with Supabase Auth and DMs
- `supabase-config.js` — **public** project URL and publishable key placeholders
- `supabase/migrations/202611080001_vynora_private_messaging.sql` — PostgreSQL schema, profile creation trigger, RPC, RLS and Realtime publication
- `index.html` — standalone no-backend demo

**Never commit database passwords, service-role keys or Supabase secret API keys.** A publishable API key is designed for use in the browser, but RLS must be correctly configured before making real accounts public.

## Architecture

```
Browser (GitHub Pages / future app.vynora.me)
     │
     ├── Supabase Auth        → accounts & sessions
     ├── Supabase PostgREST   → profiles, messages
     ├── Supabase Realtime    → live inserts
     └── Supabase Postgres    → data with RLS
```

The browser application does not use the earlier Rust + SQLite desktop prototype. A Rust client could share the same Supabase backend later.

## Before a public launch

Add friend requests and consent for DMs, block/report controls, abuse prevention, rate limits, account recovery, better automated tests and a full security review. No end-to-end encryption is implemented.

Independent branding and implementation; not affiliated with Discord.
