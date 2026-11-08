-- Applied schema migration, versioned in GitHub.
create or replace function public.can_send_dm(p_conversation uuid)
returns boolean language sql stable security definer set search_path=''
as $$
 select auth.uid() is not null
  and exists(
   select 1 from public.conversation_members me
   join public.conversation_members other on other.conversation_id=me.conversation_id
      and other.user_id<>me.user_id
   where me.conversation_id=p_conversation and me.user_id=auth.uid()
   and exists(select 1 from public.friend_requests f
      where f.status='accepted'
      and ((f.sender_id=me.user_id and f.receiver_id=other.user_id)
        or (f.receiver_id=me.user_id and f.sender_id=other.user_id)))
   and not exists(select 1 from public.user_blocks b
      where (b.blocker_id=me.user_id and b.blocked_id=other.user_id)
         or (b.blocked_id=me.user_id and b.blocker_id=other.user_id))
  );
$$;
revoke all on function public.can_send_dm(uuid) from public,anon;
grant execute on function public.can_send_dm(uuid) to authenticated;
drop policy if exists "messages: members send as self" on public.messages;
create policy "messages: members send as self" on public.messages
 for insert to authenticated
 with check(sender_id=auth.uid() and public.can_send_dm(conversation_id));
