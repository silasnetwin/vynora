-- Applied schema migration, versioned in GitHub.
-- Vynora v0.2: friends, blocking, servers, channels and channel messages.
-- Requires initial private messaging migration.
create table if not exists public.friend_requests (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid not null references public.profiles(id) on delete cascade,
  receiver_id uuid not null references public.profiles(id) on delete cascade,
  status text not null default 'pending' check (status in ('pending','accepted','declined')),
  created_at timestamptz not null default now(),
  check (sender_id <> receiver_id),
  unique(sender_id,receiver_id)
);
create table if not exists public.user_blocks (
  blocker_id uuid not null references public.profiles(id) on delete cascade,
  blocked_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key(blocker_id, blocked_id),
  check(blocker_id <> blocked_id)
);
create table if not exists public.servers (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(name) between 1 and 64),
  owner_id uuid not null references public.profiles(id) on delete cascade,
  invite_code text not null unique default encode(gen_random_bytes(16),'hex'),
  created_at timestamptz not null default now()
);
create table if not exists public.server_members (
  server_id uuid not null references public.servers(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  joined_at timestamptz not null default now(),
  primary key(server_id,user_id)
);
create table if not exists public.channels (
  id uuid primary key default gen_random_uuid(),
  server_id uuid not null references public.servers(id) on delete cascade,
  name text not null check (char_length(name) between 1 and 40),
  created_at timestamptz not null default now()
);
create table if not exists public.channel_messages (
  id uuid primary key default gen_random_uuid(),
  channel_id uuid not null references public.channels(id) on delete cascade,
  sender_id uuid not null references public.profiles(id) on delete cascade,
  body text not null check (char_length(body) between 1 and 2000),
  created_at timestamptz not null default now()
);
create index if not exists vynora_channels_server_idx on public.channels(server_id);
create index if not exists vynora_channel_messages_idx on public.channel_messages(channel_id,created_at desc);
create index if not exists vynora_servers_owner_idx on public.servers(owner_id);

alter table public.friend_requests enable row level security;
alter table public.user_blocks enable row level security;
alter table public.servers enable row level security;
alter table public.server_members enable row level security;
alter table public.channels enable row level security;
alter table public.channel_messages enable row level security;
grant select,insert on public.friend_requests to authenticated;
grant update(status) on public.friend_requests to authenticated;
grant select,insert,delete on public.user_blocks to authenticated;
grant select on public.servers,public.server_members,public.channels to authenticated;
grant select,insert on public.channel_messages to authenticated;

create policy vynora_requests_read on public.friend_requests for select to authenticated
  using (sender_id=(select auth.uid()) or receiver_id=(select auth.uid()));
create policy vynora_requests_send on public.friend_requests for insert to authenticated
  with check (sender_id=(select auth.uid()) and status='pending'
    and not exists(select 1 from public.user_blocks b where
      (b.blocker_id=sender_id and b.blocked_id=receiver_id) or
      (b.blocker_id=receiver_id and b.blocked_id=sender_id)));
create policy vynora_requests_accept on public.friend_requests for update to authenticated
  using (receiver_id=(select auth.uid()) and status='pending')
  with check (receiver_id=(select auth.uid()) and status in ('accepted','declined'));
create policy vynora_blocks_read on public.user_blocks for select to authenticated
  using (blocker_id=(select auth.uid()) or blocked_id=(select auth.uid()));
create policy vynora_blocks_insert on public.user_blocks for insert to authenticated
  with check (blocker_id=(select auth.uid()));
create policy vynora_blocks_delete on public.user_blocks for delete to authenticated
  using (blocker_id=(select auth.uid()));

-- Internal checks only: deny anonymous execution and callers without a session.
create or replace function public.is_server_member(p_server uuid)
returns boolean language sql stable security definer set search_path = ''
as $$ select auth.uid() is not null and exists(
  select 1 from public.server_members m
  where m.server_id=p_server and m.user_id=auth.uid()
); $$;
revoke all on function public.is_server_member(uuid) from public,anon;
grant execute on function public.is_server_member(uuid) to authenticated;

create policy vynora_servers_select on public.servers for select to authenticated
  using (public.is_server_member(id));
create policy vynora_server_members_select on public.server_members for select to authenticated
  using (public.is_server_member(server_id));
create policy vynora_channels_select on public.channels for select to authenticated
  using (public.is_server_member(server_id));
create policy vynora_channel_messages_select on public.channel_messages for select to authenticated
  using (exists(select 1 from public.channels c where c.id=channel_id
    and public.is_server_member(c.server_id)));
create policy vynora_channel_messages_insert on public.channel_messages for insert to authenticated
  with check (sender_id=(select auth.uid()) and
    exists(select 1 from public.channels c where c.id=channel_id
    and public.is_server_member(c.server_id)));

-- Server creation / invites / channel creation happen atomically.
create or replace function public.create_server(p_name text)
returns uuid language plpgsql security definer set search_path=''
as $$
declare v_me uuid:=auth.uid(); v_id uuid;
begin
 if v_me is null then raise exception 'Sign in first'; end if;
 if length(trim(p_name)) not between 1 and 64 then raise exception 'Invalid name'; end if;
 insert into public.servers(name,owner_id) values(trim(p_name),v_me) returning id into v_id;
 insert into public.server_members(server_id,user_id) values(v_id,v_me);
 insert into public.channels(server_id,name) values(v_id,'general');
 return v_id;
end;$$;
revoke all on function public.create_server(text) from public,anon;
grant execute on function public.create_server(text) to authenticated;

create or replace function public.join_server(p_invite_code text)
returns uuid language plpgsql security definer set search_path=''
as $$
declare v_me uuid:=auth.uid(); v_id uuid;
begin
 if v_me is null then raise exception 'Sign in first'; end if;
 select id into v_id from public.servers where invite_code=p_invite_code;
 if v_id is null then raise exception 'Invalid invite'; end if;
 insert into public.server_members(server_id,user_id) values(v_id,v_me)
 on conflict do nothing;
 return v_id;
end;$$;
revoke all on function public.join_server(text) from public,anon;
grant execute on function public.join_server(text) to authenticated;

create or replace function public.create_channel(p_server uuid,p_name text)
returns uuid language plpgsql security definer set search_path=''
as $$
declare v_me uuid:=auth.uid(); v_id uuid;
begin
 if v_me is null then raise exception 'Sign in first'; end if;
 if not exists(select 1 from public.servers where id=p_server and owner_id=v_me) then
   raise exception 'Only owner can create channels';
 end if;
 if length(trim(p_name)) not between 1 and 40 then raise exception 'Invalid name'; end if;
 insert into public.channels(server_id,name) values(p_server,trim(p_name)) returning id into v_id;
 return v_id;
end;$$;
revoke all on function public.create_channel(uuid,text) from public,anon;
grant execute on function public.create_channel(uuid,text) to authenticated;

-- A DM requires an accepted friend request, and neither side may block the other.
create or replace function public.start_dm(p_other_user uuid)
returns uuid language plpgsql security definer set search_path=''
as $$
declare v_me uuid:=auth.uid(); v_pair text; v_id uuid;
begin
 if v_me is null then raise exception 'Sign in first'; end if;
 if p_other_user is null or p_other_user=v_me then raise exception 'Invalid recipient'; end if;
 if not exists(select 1 from public.friend_requests where status='accepted'
  and ((sender_id=v_me and receiver_id=p_other_user)
    or (sender_id=p_other_user and receiver_id=v_me))) then
   raise exception 'Friend request must be accepted first';
 end if;
 if exists(select 1 from public.user_blocks where
    (blocker_id=v_me and blocked_id=p_other_user) or
    (blocker_id=p_other_user and blocked_id=v_me)) then
   raise exception 'Messaging unavailable';
 end if;
 v_pair:=least(v_me::text,p_other_user::text)||':'||greatest(v_me::text,p_other_user::text);
 insert into public.conversations(dm_pair,created_by) values(v_pair,v_me)
 on conflict(dm_pair) do nothing returning id into v_id;
 if v_id is null then select id into v_id from public.conversations where dm_pair=v_pair; end if;
 insert into public.conversation_members(conversation_id,user_id)
 values(v_id,v_me),(v_id,p_other_user) on conflict do nothing;
 return v_id;
end;$$;
revoke all on function public.start_dm(uuid) from public,anon;
grant execute on function public.start_dm(uuid) to authenticated;

revoke all on function public.handle_new_user() from public,anon,authenticated;
-- Allow the existing trigger to invoke it with owner privileges.

do $$
begin
 if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime'
  and schemaname='public' and tablename='channel_messages') then
   alter publication supabase_realtime add table public.channel_messages;
 end if;
end $$;

