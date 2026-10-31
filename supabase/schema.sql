create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text not null default 'Adventurer' check (char_length(username) between 1 and 40),
  xp integer not null default 0 check (xp >= 0),
  level integer not null default 1 check (level >= 1),
  streak integer not null default 0 check (streak >= 0),
  completed integer not null default 0 check (completed >= 0),
  created_at timestamptz not null default now()
);
alter table public.profiles add column if not exists completed integer not null default 0 check (completed >= 0);
create table if not exists public.user_preferences (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references public.profiles(id) on delete cascade,
  preferred_categories text[] not null default '{}',
  preferred_moods text[] not null default '{}',
  max_budget integer not null default 0 check (max_budget >= 0),
  preferred_environment text not null default 'Both' check (preferred_environment in ('Indoor','Outdoor','Both'))
);
create table if not exists public.missions (
  id text primary key,
  title text not null,
  description text not null,
  category text not null check (category in ('Social','Creative','Adventure','Learning','Fitness','Entertainment')),
  mood_tags text[] not null default '{}',
  duration_minutes integer not null check (duration_minutes > 0),
  budget integer not null default 0 check (budget >= 0),
  difficulty text not null check (difficulty in ('Easy','Medium','Hard')),
  xp_reward integer not null check (xp_reward > 0),
  environment text not null check (environment in ('Indoor','Outdoor','Both')),
  instructions text not null default ''
);
create table if not exists public.activity_history (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  mission_id text references public.missions(id) on delete set null,
  activity_type text not null check (activity_type in ('decision','mission')),
  selected_option text,
  status text not null check (status in ('accepted','completed','skipped')),
  user_note text,
  client_id text,
  completed_at timestamptz,
  created_at timestamptz not null default now()
);
alter table public.activity_history add column if not exists client_id text;
create table if not exists public.achievements (
  id text primary key,
  title text not null,
  description text not null,
  xp_required integer not null check (xp_required >= 0)
);

create index if not exists activity_history_user_created_idx on public.activity_history(user_id, created_at desc);
create unique index if not exists activity_history_user_client_idx on public.activity_history(user_id, client_id);
create index if not exists missions_category_idx on public.missions(category);

alter table public.profiles enable row level security;
alter table public.user_preferences enable row level security;
alter table public.missions enable row level security;
alter table public.activity_history enable row level security;
alter table public.achievements enable row level security;

drop policy if exists "profile owner access" on public.profiles;
create policy "profile owner access" on public.profiles for all using (auth.uid() = id) with check (auth.uid() = id);
drop policy if exists "preferences owner access" on public.user_preferences;
create policy "preferences owner access" on public.user_preferences for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
drop policy if exists "missions are readable" on public.missions;
create policy "missions are readable" on public.missions for select using (true);
drop policy if exists "history owner access" on public.activity_history;
create policy "history owner access" on public.activity_history for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
drop policy if exists "achievements are readable" on public.achievements;
create policy "achievements are readable" on public.achievements for select using (true);

create or replace function public.initialize_yolo_profile()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles(id) values (new.id) on conflict (id) do nothing;
  insert into public.user_preferences(user_id) values (new.id) on conflict (user_id) do nothing;
  return new;
end;
$$;
drop trigger if exists on_auth_user_created_yolo on auth.users;
create trigger on_auth_user_created_yolo after insert on auth.users for each row execute procedure public.initialize_yolo_profile();
