-- Applied to Vynora Supabase project; recorded for reproducibility.
-- Vynora 0.3: low-frequency approximate user presence
alter table public.profiles add column if not exists last_seen_at timestamptz;
alter table public.profiles add column if not exists presence_status text not null default 'online'
 check (presence_status in ('online','away','busy','invisible'));
grant update(last_seen_at,presence_status) on public.profiles to authenticated;
create index if not exists vynora_profiles_last_seen_idx on public.profiles(last_seen_at desc);

