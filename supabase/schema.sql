-- Production-oriented starting schema. The local demo does not yet call these tables.
create extension if not exists pgcrypto;
create table if not exists public.profiles(id uuid primary key references auth.users(id) on delete cascade, display_name text not null check(char_length(display_name) between 2 and 40), avatar_url text, created_at timestamptz not null default now());
create table if not exists public.villas(id uuid primary key default gen_random_uuid(), owner_id uuid not null references public.profiles(id), name text not null check(char_length(name) between 3 and 80), capacity integer not null check(capacity between 10 and 30), is_private boolean not null default true, fill_ai boolean not null default true, invite_token_hash text not null unique, status text not null default 'lobby' check(status in ('lobby','running','finished')), current_day integer not null default 1, phase text not null default 'lobby', fund integer not null default 0 check(fund>=0), scheduled_at timestamptz, created_at timestamptz not null default now());
create table if not exists public.villa_members(villa_id uuid not null references public.villas(id) on delete cascade, user_id uuid not null references public.profiles(id) on delete cascade, joined_at timestamptz not null default now(), primary key(villa_id,user_id));
create table if not exists public.game_players(id uuid primary key default gen_random_uuid(), villa_id uuid not null references public.villas(id) on delete cascade, user_id uuid references public.profiles(id), bot_name text, is_bot boolean not null default false, is_alive boolean not null default true, role text check(role in ('traitor','faithful')), shield_until_day integer, unique(villa_id,user_id), check((is_bot and user_id is null and bot_name is not null) or (not is_bot and user_id is not null and bot_name is null)));
create table if not exists public.game_votes(id uuid primary key default gen_random_uuid(), villa_id uuid not null references public.villas(id) on delete cascade, day integer not null, round integer not null default 1, voter_id uuid not null references public.game_players(id), target_id uuid not null references public.game_players(id), created_at timestamptz not null default now(), unique(villa_id,day,round,voter_id), check(voter_id<>target_id));
create table if not exists public.game_events(id bigint generated always as identity primary key,villa_id uuid not null references public.villas(id) on delete cascade,day integer not null,event_type text not null,public_payload jsonb not null default '{}',created_at timestamptz not null default now());
create table if not exists public.game_messages(id bigint generated always as identity primary key,villa_id uuid not null references public.villas(id) on delete cascade,sender_id uuid references public.profiles(id),channel text not null check(channel in ('public','traitors')),body text not null check(char_length(body) between 1 and 500),expires_at timestamptz not null default(now()+interval '1 day'),created_at timestamptz not null default now());
create index if not exists game_messages_expiry_idx on public.game_messages(expires_at);
create index if not exists game_events_villa_idx on public.game_events(villa_id,created_at);
-- Client access is intentionally restricted until server-side, role-aware RPC is implemented.
-- Do not expose role/game_players rows directly through permissive SELECT policies.
alter table public.profiles enable row level security;
alter table public.villas enable row level security;
alter table public.villa_members enable row level security;
alter table public.game_players enable row level security;
alter table public.game_votes enable row level security;
alter table public.game_events enable row level security;
alter table public.game_messages enable row level security;
create policy "profile owner reads" on public.profiles for select to authenticated using(id=auth.uid());
create policy "profile owner inserts" on public.profiles for insert to authenticated with check(id=auth.uid());
create policy "profile owner updates" on public.profiles for update to authenticated using(id=auth.uid()) with check(id=auth.uid());
-- Important: no public role/game_votes policies here. Implement trusted server functions first.
