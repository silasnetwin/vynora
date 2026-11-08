-- Recorded from applied Supabase migration.
-- Vynora: least-privilege grants on all user-data tables.
-- RLS stays enabled and restricts the rows in addition to these table/column grants.
revoke all privileges on
 public.profiles,public.conversations,public.conversation_members,public.messages,
 public.friend_requests,public.user_blocks,public.servers,public.server_members,
 public.channels,public.channel_messages,public.dm_reactions,public.channel_reactions
from PUBLIC, anon, authenticated;

grant select on
 public.profiles,public.conversations,public.conversation_members,public.messages,
 public.friend_requests,public.user_blocks,public.servers,public.server_members,
 public.channels,public.channel_messages,public.dm_reactions,public.channel_reactions
to authenticated;

grant update(username,display_name,last_seen_at,presence_status) on public.profiles to authenticated;
grant insert, delete on public.messages to authenticated;
grant update(body) on public.messages to authenticated;
grant insert, delete on public.friend_requests to authenticated;
grant update(status) on public.friend_requests to authenticated;
grant insert, delete on public.user_blocks to authenticated;
grant insert, delete on public.channel_messages to authenticated;
grant update(body) on public.channel_messages to authenticated;
grant insert, delete on public.dm_reactions,public.channel_reactions to authenticated;
