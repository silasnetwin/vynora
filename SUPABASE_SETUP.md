# Vynora Cloud / Supabase setup

This is an experimental cloud messaging prototype. Local demo: `index.html`. Cloud prototype: `cloud.html`.

1. Create a Supabase organization and project at https://supabase.com/dashboard.
2. Open SQL Editor and review/run `supabase/migrations/202611080001_vynora_private_messaging.sql` on your **new, empty project**. This creates profiles, DMs, private messages and RLS policies.
3. In Project Settings → API Keys, copy **Project URL** and **publishable key** into `supabase-config.js`. These two values may be public in browser code. NEVER commit a service_role/secret key.
4. In Authentication → URL Configuration, set Site URL and allowed redirect URLs for your GitHub Pages or future Vynora domain. Enable email authentication. If email confirmation is enabled, users must confirm before signing in.
5. Use `cloud.html` in a browser through GitHub Pages or another HTTPS static host. Register **two separate test accounts**, look up the other's `user_<UUID without hyphens>` username, open a DM, send messages. Try another browser to test.
6. To use friendly usernames, add a safe rename/uniqueness flow later. Current accounts receive an automatic unique username in the database.
7. Inspect Supabase SQL Editor and Auth dashboard to check that rows/users were created. Test RLS explicitly with different accounts.

Caution: This first version is NOT a production-ready public chat service. Before public launch implement friend requests/consent, blocking, reporting/moderation, rate limiting/anti-spam, privacy settings, secure account recovery and abuse prevention. Messages aren't end-to-end encrypted. Realtime delivery depends on project settings and can use a 10-second polling fallback. No billing or paid subscription is required for the starter demo subject to Supabase limits.

GitHub Pages only serves the client files. All chat data is stored in Supabase PostgreSQL, not GitHub or the browser. The prior Rust + SQLite desktop source is separate from this browser experiment.
