-- Recorded from applied Supabase migration.
grant delete on public.friend_requests to authenticated;
create policy vynora_withdraw_request on public.friend_requests
for delete to authenticated
using (sender_id = (select auth.uid()) and status in ('pending','declined'));
