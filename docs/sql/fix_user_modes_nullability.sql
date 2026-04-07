begin;

alter table if exists public.user_modes
  alter column current_mode drop not null;

alter table if exists public.user_modes
  alter column selected_for_day drop not null;

create or replace function public.ensure_my_role_state()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'Not authenticated';
  end if;

  insert into public.user_modes (user_id, current_mode, selected_for_day)
  values (v_uid, null, null)
  on conflict (user_id) do nothing;
end;
$$;

alter function public.ensure_my_role_state() owner to postgres;
revoke all on function public.ensure_my_role_state() from public;
grant execute on function public.ensure_my_role_state() to authenticated;

commit;
