-- Applied to Vynora Supabase project on 2026-11-08.
-- Vynora v0.4: owner-managed servers and channels.
-- Mutating RPCs check the authenticated caller, do not accept owner_id from clients.
create or replace function public.rename_server(p_server uuid, p_name text)
returns void language plpgsql security definer set search_path=''
as $$
begin
 if auth.uid() is null or trim(coalesce(p_name,'')) = '' or length(trim(p_name)) > 64 then
   raise exception 'Invalid session or server name';
 end if;
 update public.servers set name=trim(p_name) where id=p_server and owner_id=auth.uid();
 if not found then raise exception 'Only the server owner can rename this server'; end if;
end; $$;

create or replace function public.rename_channel(p_channel uuid, p_name text)
returns void language plpgsql security definer set search_path=''
as $$
begin
 if auth.uid() is null or trim(coalesce(p_name,''))='' or length(trim(p_name))>40 then
  raise exception 'Invalid session or channel name';
 end if;
 update public.channels c set name=trim(p_name)
 from public.servers s where c.id=p_channel and c.server_id=s.id and s.owner_id=auth.uid();
 if not found then raise exception 'Only the server owner can rename a channel'; end if;
end; $$;

create or replace function public.delete_channel(p_channel uuid)
returns void language plpgsql security definer set search_path=''
as $$
declare v_server uuid;
begin
 if auth.uid() is null then raise exception 'Sign in first'; end if;
 select c.server_id into v_server
 from public.channels c join public.servers s on c.server_id=s.id
 where c.id=p_channel and s.owner_id=auth.uid();
 if v_server is null then raise exception 'Only the server owner can delete channels'; end if;
 if (select count(*) from public.channels where server_id=v_server) <= 1 then
  raise exception 'The final text channel cannot be deleted';
 end if;
 delete from public.channels where id=p_channel;
end; $$;

create or replace function public.leave_server(p_server uuid)
returns void language plpgsql security definer set search_path=''
as $$
begin
 if auth.uid() is null then raise exception 'Sign in first'; end if;
 if exists(select 1 from public.servers where id=p_server and owner_id=auth.uid()) then
  raise exception 'Server owners cannot leave; delete the server instead';
 end if;
 delete from public.server_members where server_id=p_server and user_id=auth.uid();
 if not found then raise exception 'You are not a member of this server'; end if;
end; $$;

create or replace function public.delete_server(p_server uuid)
returns void language plpgsql security definer set search_path=''
as $$
begin
 if auth.uid() is null then raise exception 'Sign in first'; end if;
 delete from public.servers where id=p_server and owner_id=auth.uid();
 if not found then raise exception 'Only the server owner can delete this server'; end if;
end; $$;

revoke all on function public.rename_server(uuid,text) from public,anon;
revoke all on function public.rename_channel(uuid,text) from public,anon;
revoke all on function public.delete_channel(uuid) from public,anon;
revoke all on function public.leave_server(uuid) from public,anon;
revoke all on function public.delete_server(uuid) from public,anon;
grant execute on function public.rename_server(uuid,text) to authenticated;
grant execute on function public.rename_channel(uuid,text) to authenticated;
grant execute on function public.delete_channel(uuid) to authenticated;
grant execute on function public.leave_server(uuid) to authenticated;
grant execute on function public.delete_server(uuid) to authenticated;

