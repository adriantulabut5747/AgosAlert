-- ============================================================
-- AgosAlert: delete my account + manage my own photos
-- ============================================================
-- Paste this whole file into Supabase > SQL Editor > New query > Run,
-- AFTER 01-04. Safe to run once.
--
-- What it makes:
--   * public.delete_my_account(): the app's "Delete account" button
--     (Settings). Deletes the caller's login (auth.users); the foreign
--     keys' "on delete cascade" then remove their users row, reports,
--     votes and alert read-marks. Needed for the Data Privacy Act's right
--     to erasure (RA 10173 Sec. 16) and Google Play's account deletion rule.
--   * A storage policy that lets users SEE their own photo files.
--     Supabase's remove() needs select + delete, and 02 only gave delete,
--     so deleting a report silently left its photo behind. The app also
--     lists the folder to delete every photo before deleting the account.
--
-- Changing the display name needs nothing here: 01 already lets users
-- update their own full_name.

-- Runs as the owner (security definer): users can't delete auth.users
-- rows themselves. auth.uid() is the caller, so it only ever deletes
-- the person asking.
create function public.delete_my_account()
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'Not logged in';
  end if;
  -- alerts.posted_by has no cascade (an alert shouldn't vanish with its
  -- admin), so an admin who posted alerts can't be deleted from here.
  if exists (select 1 from public.alerts where posted_by = auth.uid()) then
    raise exception 'admin_has_alerts';
  end if;
  delete from auth.users where id = auth.uid();
end;
$$;

revoke all on function public.delete_my_account() from public, anon;
grant execute on function public.delete_my_account() to authenticated;

create policy "Users see their own photos"
  on storage.objects for select to authenticated
  using (
    bucket_id = 'report-photos'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );
