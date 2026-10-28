-- Trillionaire Tycoon: friends leaderboard (invite only)
-- Run once in Supabase: SQL Editor > New query > paste > Run.
-- Safe to run again. Contains no secrets, so it can live in your repo.

-- What friends can see about each player (no email, just the in-game boss name)
create table if not exists public.profiles (
  user_id     uuid primary key references auth.users (id) on delete cascade,
  name        text not null default 'Boss' check (char_length(name) <= 20),
  net_worth   double precision not null default 0,
  tier        int not null default 1,
  businesses  int not null default 0,
  last_played timestamptz not null default now()
);

-- Each player's personal invite code
create table if not exists public.invite_codes (
  user_id uuid primary key references auth.users (id) on delete cascade,
  code    text not null unique
);

-- Connections, stored both ways (A->B and B->A)
create table if not exists public.friendships (
  user_id    uuid not null references auth.users (id) on delete cascade,
  friend_id  uuid not null references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, friend_id),
  check (user_id <> friend_id)
);

alter table public.profiles     enable row level security;
alter table public.invite_codes enable row level security;
alter table public.friendships  enable row level security;

-- Profiles: you can see yours and your connected friends'. Only you can write yours.
drop policy if exists "See own and friends' profiles" on public.profiles;
create policy "See own and friends' profiles" on public.profiles
  for select using (
    auth.uid() = user_id
    or exists (select 1 from public.friendships f where f.user_id = auth.uid() and f.friend_id = profiles.user_id)
  );
drop policy if exists "Create own profile" on public.profiles;
create policy "Create own profile" on public.profiles
  for insert with check (auth.uid() = user_id);
drop policy if exists "Update own profile" on public.profiles;
create policy "Update own profile" on public.profiles
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Invite codes: you can only see your own. Codes are created by my_invite_code() below.
drop policy if exists "See own invite code" on public.invite_codes;
create policy "See own invite code" on public.invite_codes
  for select using (auth.uid() = user_id);

-- Friendships: you can only see your own connections. They're created by redeem_invite() below.
drop policy if exists "See own friendships" on public.friendships;
create policy "See own friendships" on public.friendships
  for select using (auth.uid() = user_id);

-- Your invite code. Pass true to replace it with a new one (the old code stops working).
create or replace function public.my_invite_code(regenerate boolean default false)
returns text language plpgsql security definer set search_path = public as $$
declare
  uid uuid := auth.uid();
  c text;
  alphabet text := 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  i int;
begin
  if uid is null then raise exception 'Sign in first'; end if;
  if not regenerate then
    select code into c from invite_codes where user_id = uid;
    if c is not null then return c; end if;
  end if;
  loop
    c := 'TYC-';
    for i in 1..6 loop
      c := c || substr(alphabet, 1 + floor(random() * length(alphabet))::int, 1);
    end loop;
    exit when not exists (select 1 from invite_codes where code = c);
  end loop;
  insert into invite_codes (user_id, code) values (uid, c)
    on conflict (user_id) do update set code = excluded.code;
  return c;
end $$;

-- Enter a friend's code to connect both ways. Returns the friend's boss name.
create or replace function public.redeem_invite(invite text)
returns text language plpgsql security definer set search_path = public as $$
declare
  uid uuid := auth.uid();
  v text := upper(regexp_replace(coalesce(invite, ''), '[^A-Za-z0-9]', '', 'g'));
  owner uuid;
  nm text;
begin
  if uid is null then raise exception 'Sign in first'; end if;
  if left(v, 3) <> 'TYC' then v := 'TYC' || v; end if;
  select user_id into owner from invite_codes where replace(code, '-', '') = v;
  if owner is null then raise exception 'NO_MATCH'; end if;
  if owner = uid then raise exception 'OWN_CODE'; end if;
  insert into friendships (user_id, friend_id) values (uid, owner), (owner, uid)
    on conflict do nothing;
  select name into nm from profiles where user_id = owner;
  return coalesce(nm, 'your friend');
end $$;

-- Your connected friends, for the leaderboard.
create or replace function public.my_friends()
returns table (user_id uuid, name text, net_worth double precision, tier int, businesses int, last_played timestamptz)
language sql stable security definer set search_path = public as $$
  select p.user_id, p.name, p.net_worth, p.tier, p.businesses, p.last_played
  from friendships f
  join profiles p on p.user_id = f.friend_id
  where f.user_id = auth.uid();
$$;

-- Disconnect from a friend (removes both directions).
create or replace function public.remove_friend(friend uuid)
returns void language sql security definer set search_path = public as $$
  delete from friendships
  where (user_id = auth.uid() and friend_id = friend)
     or (user_id = friend and friend_id = auth.uid());
$$;

-- Only signed-in players can use these.
revoke execute on function public.my_invite_code(boolean) from public, anon;
revoke execute on function public.redeem_invite(text)     from public, anon;
revoke execute on function public.my_friends()            from public, anon;
revoke execute on function public.remove_friend(uuid)     from public, anon;
grant  execute on function public.my_invite_code(boolean) to authenticated;
grant  execute on function public.redeem_invite(text)     to authenticated;
grant  execute on function public.my_friends()            to authenticated;
grant  execute on function public.remove_friend(uuid)     to authenticated;
