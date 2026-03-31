create table if not exists public.pet_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  level integer not null default 1 check (level >= 1),
  exp integer not null default 0 check (exp >= 0),
  energy_percent integer not null default 50 check (energy_percent between 0 and 100),
  food_count integer not null default 3 check (food_count >= 0),
  owned_items integer[] not null default '{}',
  equipped_item_id integer,
  next_food_ready_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists pet_profiles_updated_at_idx
  on public.pet_profiles (updated_at desc);

alter table public.pet_profiles enable row level security;

create policy "pet_profiles_select_own"
on public.pet_profiles
for select
to authenticated
using (auth.uid() = user_id);

create policy "pet_profiles_insert_own"
on public.pet_profiles
for insert
to authenticated
with check (auth.uid() = user_id);

create policy "pet_profiles_update_own"
on public.pet_profiles
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "pet_profiles_delete_own"
on public.pet_profiles
for delete
to authenticated
using (auth.uid() = user_id);

create or replace function public.set_pet_profiles_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists pet_profiles_set_updated_at on public.pet_profiles;
create trigger pet_profiles_set_updated_at
before update on public.pet_profiles
for each row
execute function public.set_pet_profiles_updated_at();

create or replace function public.ensure_my_pet_profile()
returns public.pet_profiles
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_row public.pet_profiles;
begin
  if v_user_id is null then
    raise exception 'not authenticated';
  end if;

  insert into public.pet_profiles (user_id)
  values (v_user_id)
  on conflict (user_id) do nothing;

  select *
  into v_row
  from public.pet_profiles
  where user_id = v_user_id;

  return v_row;
end;
$$;

grant execute on function public.ensure_my_pet_profile() to authenticated;
