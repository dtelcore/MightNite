-- Friend-code rooms for MightNite online 1v1.
-- The game uses the publishable key. The database password never ships in the client.

create table if not exists public.rooms (
	id uuid primary key default gen_random_uuid(),
	code text not null unique check (char_length(code) = 4),
	status text not null default 'lobby' check (status in ('lobby', 'select', 'fight', 'done')),
	host_id text not null,
	guest_id text,
	p1_character text,
	p2_character text,
	stage_id text,
	game_version text not null default '1',
	host_ready boolean not null default false,
	guest_ready boolean not null default false,
	created_at timestamptz not null default now()
);

alter table public.rooms replica identity full;

alter table public.rooms enable row level security;

grant select, insert, update, delete on table public.rooms to anon, authenticated;

drop policy if exists rooms_select on public.rooms;
drop policy if exists rooms_insert on public.rooms;
drop policy if exists rooms_update on public.rooms;
drop policy if exists rooms_delete on public.rooms;

create policy rooms_select on public.rooms
	for select to anon, authenticated
	using (true);

create policy rooms_insert on public.rooms
	for insert to anon, authenticated
	with check (true);

create policy rooms_update on public.rooms
	for update to anon, authenticated
	using (true)
	with check (true);

create policy rooms_delete on public.rooms
	for delete to anon, authenticated
	using (true);

do $$
begin
	if not exists (
		select 1 from pg_publication_tables
		where pubname = 'supabase_realtime'
			and schemaname = 'public'
			and tablename = 'rooms'
	) then
		alter publication supabase_realtime add table public.rooms;
	end if;
end $$;

create or replace function public.purge_old_rooms()
returns void
language sql
security definer
set search_path = public
as $$
	delete from public.rooms where created_at < now() - interval '1 hour';
$$;

grant execute on function public.purge_old_rooms() to anon, authenticated;

drop policy if exists rooms_broadcast_select on realtime.messages;
drop policy if exists rooms_broadcast_insert on realtime.messages;

create policy rooms_broadcast_select on realtime.messages
	for select to anon, authenticated
	using (true);

create policy rooms_broadcast_insert on realtime.messages
	for insert to anon, authenticated
	with check (true);

notify pgrst, 'reload schema';
