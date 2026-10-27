-- Trillionaire Tycoon: cloud saves
-- Run this once in Supabase: SQL Editor > New query > paste > Run.

create table if not exists public.saves (
  user_id    uuid primary key references auth.users (id) on delete cascade,
  data       jsonb not null,
  updated_at timestamptz not null default now()
);

-- Each player can only read and write their own save.
alter table public.saves enable row level security;

create policy "Players read their own save"
  on public.saves for select
  using (auth.uid() = user_id);

create policy "Players create their own save"
  on public.saves for insert
  with check (auth.uid() = user_id);

create policy "Players update their own save"
  on public.saves for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
