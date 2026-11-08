-- Vynora: first private messaging schema for Supabase/PostgreSQL
-- Run once in Supabase SQL Editor, or apply as a migration.
-- IMPORTANT: never execute this against a production database without reviewing it.
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text not null unique check (char_length(username) between 3 and 48 and username ~ '^[a-z0-9_.]+
  display_name text not null default 'Vynora User' check (char_length(display_name) between 1 and 40),
  created_at timestamptz not null default now()
);

create table if not exists public.conversations (
  id uuid primary key default gen_random_uuid(),
  dm_pair text not null unique,
  created_by uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table if not exists public.conversation_members (
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  joined_at timestamptz not null default now(),
  primary key (conversation_id, user_id)
);
create index if not exists conversation_members_user_idx on public.conversation_members(user_id);

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  sender_id uuid not null references public.profiles(id) on delete cascade,
  body text not null check (char_length(body) between 1 and 2000),
  created_at timestamptz not null default now()
);
create index if not exists messages_conversation_time_idx on public.messages(conversation_id, created_at desc);

-- Profiles are created server-side when a user confirms an account.
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
  insert into public.profiles (id, username, display_name)
  values (
    new.id,
    'user_' || replace(new.id::text, '-', ''),
    left(coalesce(nullif(btrim(new.raw_user_meta_data->>'display_name'), ''), 'Vynora User'), 40)
  )
  on conflict (id) do nothing;
  return new;
end;
$$;
drop trigger if exists on_auth_user_created_vynora on auth.users;
create trigger on_auth_user_created_vynora
after insert on auth.users for each row execute function public.handle_new_user();

-- Backfill users registered before installing the migration, if any.
insert into public.profiles(id, username, display_name)
select id, 'user_' || replace(id::text, '-', ''), 'Vynora User'
from auth.users on conflict(id) do nothing;

-- SECURITY DEFINER avoids a recursive RLS policy on conversation_members.
create or replace function public.is_conversation_member(p_conversation_id uuid)
returns boolean language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.conversation_members m
    where m.conversation_id = p_conversation_id and m.user_id = (select auth.uid())
  );
$$;

-- DM creation is atomic and prevents clients from adding themselves to arbitrary chats.
create or replace function public.start_dm(p_other_user uuid)
returns uuid language plpgsql security definer set search_path = ''
as $$
declare
  v_me uuid := auth.uid();
  v_pair text;
  v_id uuid;
begin
  if v_me is null then raise exception 'Not signed in'; end if;
  if p_other_user is null or p_other_user = v_me then raise exception 'Invalid recipient'; end if;
  if not exists (select 1 from public.profiles where id = p_other_user) then
    raise exception 'Recipient not found';
  end if;

  v_pair := least(v_me::text, p_other_user::text) || ':' || greatest(v_me::text, p_other_user::text);
  insert into public.conversations(dm_pair, created_by)
  values (v_pair, v_me)
  on conflict(dm_pair) do nothing returning id into v_id;

  if v_id is null then
    select id into v_id from public.conversations where dm_pair = v_pair;
  else
    insert into public.conversation_members(conversation_id, user_id)
    values (v_id, v_me), (v_id, p_other_user);
  end if;
  return v_id;
end;
$$;

alter table public.profiles enable row level security;
alter table public.conversations enable row level security;
alter table public.conversation_members enable row level security;
alter table public.messages enable row level security;

-- Explicit grants: anonymous clients cannot read or write private data.
revoke all on public.profiles, public.conversations, public.conversation_members, public.messages from anon, authenticated;
grant select on public.profiles to authenticated;
grant update(username, display_name) on public.profiles to authenticated;
grant select on public.conversations to authenticated;
grant select on public.conversation_members to authenticated;
grant select, insert on public.messages to authenticated;

drop policy if exists "profiles: signed-in users can discover others" on public.profiles;
create policy "profiles: signed-in users can discover others"
on public.profiles for select to authenticated using (true);

drop policy if exists "profiles: update self" on public.profiles;
create policy "profiles: update self"
on public.profiles for update to authenticated
using (id = (select auth.uid())) with check (id = (select auth.uid()));

drop policy if exists "conversations: members read" on public.conversations;
create policy "conversations: members read"
on public.conversations for select to authenticated
using (public.is_conversation_member(id));

drop policy if exists "conversation_members: members read" on public.conversation_members;
create policy "conversation_members: members read"
on public.conversation_members for select to authenticated
using (public.is_conversation_member(conversation_id));

drop policy if exists "messages: members read" on public.messages;
create policy "messages: members read"
on public.messages for select to authenticated
using (public.is_conversation_member(conversation_id));

drop policy if exists "messages: members send as self" on public.messages;
create policy "messages: members send as self"
on public.messages for insert to authenticated
with check (sender_id = (select auth.uid()) and public.is_conversation_member(conversation_id));

revoke all on function public.is_conversation_member(uuid) from public, anon;
grant execute on function public.is_conversation_member(uuid) to authenticated;
revoke all on function public.start_dm(uuid) from public, anon;
grant execute on function public.start_dm(uuid) to authenticated;

-- Enable Postgres-change notifications for INSERT events on messages.
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'messages'
  ) then
    alter publication supabase_realtime add table public.messages;
  end if;
end $$;
