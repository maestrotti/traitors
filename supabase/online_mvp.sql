-- Execute in Supabase SQL Editor. Isolated multiplayer lobby; existing demo schema remains unchanged.
create extension if not exists pgcrypto;
create table if not exists public.online_rooms (
 id uuid primary key default gen_random_uuid(),
 code text not null unique default upper(encode(gen_random_bytes(6),'hex')),
 title text not null check(char_length(title) between 3 and 60),
 host uuid not null references auth.users(id),
 capacity integer not null default 12 check(capacity between 2 and 20),
 status text not null default 'lobby' check(status in ('lobby','started')),
 created_at timestamptz not null default now()
);
create table if not exists public.online_members (
 room_id uuid not null references public.online_rooms(id) on delete cascade,
 user_id uuid not null references auth.users(id) on delete cascade,
 nickname text not null check(char_length(nickname) between 2 and 25),
 ready boolean not null default false,
 joined_at timestamptz not null default now(),
 primary key(room_id,user_id)
);
create table if not exists public.online_chat (
 id bigint generated always as identity primary key,
 room_id uuid not null references public.online_rooms(id) on delete cascade,
 user_id uuid not null references auth.users(id),
 body text not null check(char_length(body) between 1 and 500),
 created_at timestamptz not null default now()
);
create index if not exists online_chat_room_idx on public.online_chat(room_id,id desc);
alter table public.online_rooms enable row level security;
alter table public.online_members enable row level security;
alter table public.online_chat enable row level security;
-- No direct client table access. All operations go through verified SECURITY DEFINER RPCs.
revoke all on public.online_rooms,public.online_members,public.online_chat from anon,authenticated;

create or replace function public.online_create(p_title text,p_nickname text,p_capacity integer default 12)
returns text language plpgsql security definer set search_path='' as $$
declare r public.online_rooms; begin
 if auth.uid() is null then raise exception 'Prijava je obavezna'; end if;
 if length(trim(p_title)) not between 3 and 60 or length(trim(p_nickname)) not between 2 and 25 or p_capacity not between 2 and 20 then raise exception 'Neispravni podaci'; end if;
 insert into public.online_rooms(title,host,capacity) values(trim(p_title),auth.uid(),p_capacity) returning * into r;
 insert into public.online_members(room_id,user_id,nickname) values(r.id,auth.uid(),trim(p_nickname));
 return r.code;
end $$;

create or replace function public.online_join(p_code text,p_nickname text)
returns text language plpgsql security definer set search_path='' as $$
declare r public.online_rooms;begin
 if auth.uid() is null then raise exception 'Prijava je obavezna'; end if;
 if length(trim(p_nickname)) not between 2 and 25 then raise exception 'Ime mora imati 2–25 znakova'; end if;
 select * into r from public.online_rooms where code=upper(trim(p_code)) for update;
 if not found then raise exception 'Vila ne postoji'; end if;
 if exists(select 1 from public.online_members where room_id=r.id and user_id=auth.uid()) then return r.code; end if;
 if r.status<>'lobby' then raise exception 'Igra je već počela'; end if;
 if (select count(*) from public.online_members where room_id=r.id)>=r.capacity then raise exception 'Vila je puna'; end if;
 if exists(select 1 from public.online_members where room_id=r.id and lower(nickname)=lower(trim(p_nickname))) then raise exception 'Ime je zauzeto'; end if;
 insert into public.online_members(room_id,user_id,nickname) values(r.id,auth.uid(),trim(p_nickname));
 return r.code;
end $$;

create or replace function public.online_state(p_code text)
returns jsonb language plpgsql security definer set search_path='' as $$
declare r public.online_rooms;begin
 if auth.uid() is null then raise exception 'Prijava je obavezna'; end if;
 select * into r from public.online_rooms where code=upper(trim(p_code));
 if not found or not exists(select 1 from public.online_members where room_id=r.id and user_id=auth.uid()) then raise exception 'Nisi član ove vile'; end if;
 return jsonb_build_object('code',r.code,'title',r.title,'capacity',r.capacity,'status',r.status,'host',r.host,'me',auth.uid(),
 'members',(select coalesce(jsonb_agg(jsonb_build_object('id',m.user_id,'name',m.nickname,'ready',m.ready) order by m.joined_at),'[]'::jsonb) from public.online_members m where m.room_id=r.id),
 'messages',(select coalesce(jsonb_agg(jsonb_build_object('id',c.id,'user',c.user_id,'body',c.body,'created',c.created_at) order by c.id),'[]'::jsonb) from (select * from public.online_chat where room_id=r.id order by id desc limit 100) c));
end $$;

create or replace function public.online_send(p_code text,p_body text)
returns void language plpgsql security definer set search_path='' as $$
declare rid uuid;begin
 if auth.uid() is null then raise exception 'Prijava je obavezna'; end if;
 if length(trim(p_body)) not between 1 and 500 then raise exception 'Poruka mora imati 1–500 znakova'; end if;
 select id into rid from public.online_rooms where code=upper(trim(p_code));
 if rid is null or not exists(select 1 from public.online_members where room_id=rid and user_id=auth.uid()) then raise exception 'Nisi član ove vile'; end if;
 insert into public.online_chat(room_id,user_id,body) values(rid,auth.uid(),trim(p_body));
end $$;

create or replace function public.online_ready(p_code text,p_ready boolean)
returns void language plpgsql security definer set search_path='' as $$
declare rid uuid;begin
 select id into rid from public.online_rooms where code=upper(trim(p_code)) and status='lobby';
 if rid is null then raise exception 'Čekaonica nije otvorena'; end if;
 update public.online_members set ready=p_ready where room_id=rid and user_id=auth.uid();
 if not found then raise exception 'Nisi član vile'; end if;
end $$;

create or replace function public.online_start(p_code text)
returns void language plpgsql security definer set search_path='' as $$
declare r public.online_rooms;begin
 select * into r from public.online_rooms where code=upper(trim(p_code)) for update;
 if not found or r.host is distinct from auth.uid() then raise exception 'Samo domaćin može pokrenuti'; end if;
 if r.status<>'lobby' then raise exception 'Već pokrenuto'; end if;
 if (select count(*) from public.online_members where room_id=r.id)<2 then raise exception 'Potrebna su najmanje 2 stvarna igrača'; end if;
 if exists(select 1 from public.online_members where room_id=r.id and not ready) then raise exception 'Svi igrači moraju biti spremni'; end if;
 update public.online_rooms set status='started' where id=r.id;
end $$;

revoke all on function public.online_create(text,text,integer),public.online_join(text,text),public.online_state(text),public.online_send(text,text),public.online_ready(text,boolean),public.online_start(text) from public,anon;
grant execute on function public.online_create(text,text,integer),public.online_join(text,text),public.online_state(text),public.online_send(text,text),public.online_ready(text,boolean),public.online_start(text) to authenticated;
