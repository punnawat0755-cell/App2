-- Fix: legacy video posts not visible across accounts
-- Run this in Supabase SQL Editor (project used by this app).

begin;

-- 1) Backfill only legacy/empty visibility flags for video posts.
update posts p
set
  status = case
    when trim(coalesce(p.status, '')) = '' then 'active'
    else p.status
  end,
  moderation_status = case
    when trim(coalesce(p.moderation_status, '')) = '' then 'approved'
    else p.moderation_status
  end,
  is_visible = coalesce(p.is_visible, true),
  moderated_at = coalesce(p.moderated_at, timezone('utc', now()))
from (
  select distinct pm.post_id
  from post_media pm
  where lower(coalesce(pm.media_type, '')) like 'video%'
     or coalesce(pm.storage_path, '') ~* '\.(mp4|mov|m4v|avi|webm|mkv)(\?.*)?$'
     or coalesce(pm.public_url, '') ~* '\.(mp4|mov|m4v|avi|webm|mkv)(\?.*)?$'
) videos
where p.id = videos.post_id
  and coalesce(lower(nullif(trim(p.status), '')), 'active')
      not in ('draft', 'hidden', 'deleted', 'archived');

-- 2) Ensure RLS allows reading own posts + public approved posts.
alter table posts enable row level security;
drop policy if exists posts_select_owner_or_public on posts;
create policy posts_select_owner_or_public
on posts
for select
to authenticated
using (
  user_id = auth.uid()
  or (
    coalesce(lower(nullif(trim(status), '')), 'active') = 'active'
    and coalesce(is_visible, true) = true
    and coalesce(lower(nullif(trim(moderation_status), '')), 'approved')
      = 'approved'
  )
);

-- 3) Ensure video rows in post_media are readable whenever parent post is readable.
alter table post_media enable row level security;
drop policy if exists post_media_select_owner_or_public on post_media;
create policy post_media_select_owner_or_public
on post_media
for select
to authenticated
using (
  exists (
    select 1
    from posts p
    where p.id = post_media.post_id
      and (
        p.user_id = auth.uid()
        or (
          coalesce(lower(nullif(trim(p.status), '')), 'active') = 'active'
          and coalesce(p.is_visible, true) = true
          and coalesce(lower(nullif(trim(p.moderation_status), '')), 'approved')
            = 'approved'
        )
      )
  )
);

commit;

-- Optional quick checks:
-- select id, user_id, status, moderation_status, is_visible, created_at
-- from posts
-- order by created_at desc
-- limit 30;
--
-- select post_id, media_type, storage_bucket, storage_path
-- from post_media
-- order by created_at desc nulls last
-- limit 30;
