-- Applied to Vynora Supabase project; recorded for reproducibility.
-- Vynora 0.3: editable messages and private emoji reactions.
-- Applied after vynora_private_messaging_initial and vynora_social_servers_channels.
alter table public.messages add column if not exists edited_at timestamptz;
alter table public.channel_messages add column if not exists edited_at timestamptz;

create or replace function public.vynora_set_edited_at()
returns trigger language plpgsql security invoker set search_path=''
as $$ begin
  if new.body is distinct from old.body then new.edited_at := now(); end if;
  return new;
end $$;
revoke execute on function public.vynora_set_edited_at() from public, anon, authenticated;
drop trigger if exists vynora_dm_message_edited on public.messages;
create trigger vynora_dm_message_edited before update of body on public.messages
for each row execute function public.vynora_set_edited_at();
drop trigger if exists vynora_channel_message_edited on public.channel_messages;
create trigger vynora_channel_message_edited before update of body on public.channel_messages
for each row execute function public.vynora_set_edited_at();

grant update(body), delete on public.messages to authenticated;
grant update(body), delete on public.channel_messages to authenticated;

create policy vynora_dm_edit on public.messages for update to authenticated
using(sender_id=auth.uid() and public.is_conversation_member(conversation_id))
with check(sender_id=auth.uid() and public.can_send_dm(conversation_id));
create policy vynora_dm_delete on public.messages for delete to authenticated
using(sender_id=auth.uid() and public.is_conversation_member(conversation_id));
create policy vynora_channel_edit on public.channel_messages for update to authenticated
using(sender_id=auth.uid() and exists(
 select 1 from public.channels c where c.id=channel_id and public.is_server_member(c.server_id)))
with check(sender_id=auth.uid() and exists(
 select 1 from public.channels c where c.id=channel_id and public.is_server_member(c.server_id)));
create policy vynora_channel_delete on public.channel_messages for delete to authenticated
using(sender_id=auth.uid() and exists(
 select 1 from public.channels c where c.id=channel_id and public.is_server_member(c.server_id)));

create table if not exists public.dm_reactions(
  id uuid primary key default gen_random_uuid(),
  message_id uuid not null references public.messages(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  emoji text not null check (char_length(emoji) between 1 and 12),
  created_at timestamptz not null default now(),
  unique(message_id,user_id,emoji)
);
create table if not exists public.channel_reactions(
  id uuid primary key default gen_random_uuid(),
  message_id uuid not null references public.channel_messages(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  emoji text not null check(char_length(emoji) between 1 and 12),
  created_at timestamptz not null default now(),
  unique(message_id,user_id,emoji)
);
create index if not exists vynora_dm_reactions_message_idx on public.dm_reactions(message_id);
create index if not exists vynora_channel_reactions_message_idx on public.channel_reactions(message_id);
alter table public.dm_reactions enable row level security;
alter table public.channel_reactions enable row level security;
grant select, insert, delete on public.dm_reactions, public.channel_reactions to authenticated;

create policy vynora_dm_reactions_read on public.dm_reactions for select to authenticated
using(exists(select 1 from public.messages m where m.id=message_id
 and public.is_conversation_member(m.conversation_id)));
create policy vynora_dm_reactions_insert on public.dm_reactions for insert to authenticated
with check(user_id=auth.uid() and exists(select 1 from public.messages m where m.id=message_id
 and public.can_send_dm(m.conversation_id)));
create policy vynora_dm_reactions_delete on public.dm_reactions for delete to authenticated
using(user_id=auth.uid() and exists(select 1 from public.messages m where m.id=message_id
 and public.is_conversation_member(m.conversation_id)));
create policy vynora_channel_reactions_read on public.channel_reactions for select to authenticated
using(exists(select 1 from public.channel_messages m join public.channels c on c.id=m.channel_id
  where m.id=message_id and public.is_server_member(c.server_id)));
create policy vynora_channel_reactions_insert on public.channel_reactions for insert to authenticated
with check(user_id=auth.uid() and exists(select 1 from public.channel_messages m
 join public.channels c on c.id=m.channel_id
 where m.id=message_id and public.is_server_member(c.server_id)));
create policy vynora_channel_reactions_delete on public.channel_reactions for delete to authenticated
using(user_id=auth.uid() and exists(select 1 from public.channel_messages m
 join public.channels c on c.id=m.channel_id
 where m.id=message_id and public.is_server_member(c.server_id)));

do $$ begin
 if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime'
 and schemaname='public' and tablename='dm_reactions') then
 alter publication supabase_realtime add table public.dm_reactions;
 end if;
 if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime'
 and schemaname='public' and tablename='channel_reactions') then
 alter publication supabase_realtime add table public.channel_reactions;
 end if;
end $$;

