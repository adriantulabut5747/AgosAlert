-- ============================================================
-- AgosAlert: admin powers the earlier files didn't give
-- ============================================================
-- Paste this whole file into Supabase > SQL Editor > New query > Run,
-- AFTER 01-07. Safe to run once.
--
-- What it makes:
--   * set_account_status(user, 'active' | 'suspended'): Admin page >
--     Users (FR-A7). A function, not a column grant, because users may
--     already edit their own row (01): granting account_status would let
--     a suspended user reactivate themselves.
--   * Storage policies so admins can delete any report's photo.
--
-- Already possible from 01-07 (nothing to add): admins read every user,
-- verify / remove / delete any flood report (02), post, edit and delete
-- alerts (04), manage evacuation centers (06), handle rescue requests and
-- flag numbers (07). Making someone an admin stays in the Table Editor
-- (users.role), on purpose: no button in the app hands out admin rights.

create function public.set_account_status(p_user_id uuid, p_status text)
returns void
language plpgsql
security definer set search_path = ''
as $$
begin
  if not public.is_admin() then
    raise exception 'admins_only';
  end if;
  if p_user_id = (select auth.uid()) then
    raise exception 'not_yourself'; -- an admin can't lock themselves out
  end if;
  if p_status not in ('active', 'suspended') then
    raise exception 'bad_status';
  end if;
  update public.users set account_status = p_status where user_id = p_user_id;
end;
$$;

revoke all on function public.set_account_status(uuid, text) from public, anon;
grant execute on function public.set_account_status(uuid, text) to authenticated;

-- Admins deleting a report for good also delete its photo (FR-A2).
-- 02 + 05 only let people see / delete files in their own folder.
create policy "Admins see all report photos"
  on storage.objects for select to authenticated
  using (bucket_id = 'report-photos' and public.is_admin());

create policy "Admins delete any report photo"
  on storage.objects for delete to authenticated
  using (bucket_id = 'report-photos' and public.is_admin());
