create table if not exists public.post_comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.posts(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  content_text text not null check (char_length(trim(content_text)) > 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists post_comments_post_id_idx
  on public.post_comments (post_id, created_at);

create index if not exists post_comments_user_id_idx
  on public.post_comments (user_id, created_at desc);

alter table public.post_comments enable row level security;

create policy "post_comments_select_authenticated"
on public.post_comments
for select
to authenticated
using (true);

create policy "post_comments_insert_own"
on public.post_comments
for insert
to authenticated
with check (auth.uid() = user_id);

create policy "post_comments_update_own"
on public.post_comments
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "post_comments_delete_own"
on public.post_comments
for delete
to authenticated
using (auth.uid() = user_id);

create or replace function public.set_post_comments_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists post_comments_set_updated_at on public.post_comments;
create trigger post_comments_set_updated_at
before update on public.post_comments
for each row
execute function public.set_post_comments_updated_at();

alter table public.posts
  add column if not exists comment_count integer not null default 0;

create or replace function public.sync_post_comment_count()
returns trigger
language plpgsql
as $$
declare
  target_post_id uuid;
begin
  target_post_id = coalesce(new.post_id, old.post_id);

  update public.posts
  set comment_count = (
    select count(*)
    from public.post_comments
    where post_id = target_post_id
  )
  where id = target_post_id;

  return coalesce(new, old);
end;
$$;

drop trigger if exists post_comments_sync_count_insert on public.post_comments;
create trigger post_comments_sync_count_insert
after insert on public.post_comments
for each row
execute function public.sync_post_comment_count();

drop trigger if exists post_comments_sync_count_delete on public.post_comments;
create trigger post_comments_sync_count_delete
after delete on public.post_comments
for each row
execute function public.sync_post_comment_count();

drop trigger if exists post_comments_sync_count_update on public.post_comments;
create trigger post_comments_sync_count_update
after update of post_id on public.post_comments
for each row
execute function public.sync_post_comment_count();
