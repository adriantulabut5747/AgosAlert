-- ============================================================
-- AgosAlert: report trash (30 days) + account deletion wait (7 days)
-- ============================================================
-- BEFORE running this: make the "purge" Edge Function
-- (supabase/functions/purge/index.ts, steps at its top). Then paste this
-- whole file into Supabase > SQL Editor > New query > Run, AFTER 01-08.
-- Safe to run once.
--
-- Reports:
--   * Deleting a report (its owner or an admin) only puts it in the
--     trash: deleted_at / deleted_by are set and everyone stops seeing it.
--   * A report past its 14-day expiry is in the trash too.
--   * 30 days after it went in the trash, the purge function erases the
--     row AND its photo (SQL can't delete Storage files, a function can).
--   * The owner can restore a report they deleted themselves (Settings >
--     Trash); admins can restore any. An expired report can't
--     come back: its 14 days are over.
--   * "Delete now" in the trash still erases it at once (02's delete rule).
--
-- Accounts (like Facebook):
--   * "Delete account" sets users.deletion_requested_at and the app signs
--     the person out everywhere. Their reports are hidden and they can't
--     post meanwhile.
--   * Logging in within 7 days asks "Keep my account?"; Keep clears it.
--   * After 7 days the purge function deletes their photos, then their
--     login; the cascades remove their row, reports, votes and read-marks.

alter table public.flood_reports
  add column deleted_at timestamptz,
  add column deleted_by uuid references public.users (user_id) on delete set null;

alter table public.users
  add column deletion_requested_at timestamptz;

-- Trashed / pending reports and accounts vanish from the public feed...
create or replace view public.flood_report_feed as
  select r.report_id, r.user_id, r.incident_type, r.severity, r.depth_cm,
         r.barangay, r.latitude, r.longitude, r.note, r.photo_url,
         r.photo_taken_at, r.expires_at, r.status, r.created_at,
         u.full_name as poster_name, u.barangay as poster_barangay,
         (select count(*) from public.report_votes v
           where v.report_id = r.report_id and v.vote = 1) as up_votes,
         (select count(*) from public.report_votes v
           where v.report_id = r.report_id and v.vote = -1) as down_votes,
         (select v.vote from public.report_votes v
           where v.report_id = r.report_id and v.user_id = auth.uid()) as my_vote
  from public.flood_reports r
  join public.users u on u.user_id = r.user_id
  where r.status <> 'removed' and r.expires_at > now()
    and r.deleted_at is null and u.deletion_requested_at is null;

-- ...and from the table itself (owners and admins still see theirs).
drop policy "Anyone reads active reports; owners and admins read all"
  on public.flood_reports;
create policy "Anyone reads active reports; owners and admins read all"
  on public.flood_reports for select to anon, authenticated
  using (
    (status <> 'removed' and expires_at > now() and deleted_at is null)
    or user_id = (select auth.uid())
    or public.is_admin()
  );

-- An account waiting to be deleted can't post or upload.
create or replace function public.is_active_user()
returns boolean
language sql
stable
security definer set search_path = ''
as $$
  select exists (
    select 1 from public.users
    where user_id = (select auth.uid()) and account_status = 'active'
      and deletion_requested_at is null
  );
$$;

-- ------------------------------------------------------------ reports

-- Functions, not an update grant: users must not set deleted_at to some
-- old date (erased early) or deleted_by to someone else.
create function public.trash_report(p_report_id bigint)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.flood_reports
     set deleted_at = now(), deleted_by = auth.uid()
   where report_id = p_report_id
     and deleted_at is null and expires_at > now()
     and (user_id = auth.uid() or public.is_admin());
  if not found then
    raise exception 'not_found';
  end if;
end;
$$;

-- The owner can't undo an admin's delete (that would bring spam back).
create function public.restore_report(p_report_id bigint)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.flood_reports
     set deleted_at = null, deleted_by = null
   where report_id = p_report_id
     and deleted_at is not null and expires_at > now()
     and (public.is_admin() or (user_id = auth.uid() and deleted_by = auth.uid()));
  if not found then
    raise exception 'not_found';
  end if;
end;
$$;

revoke all on function public.trash_report(bigint) from public, anon;
revoke all on function public.restore_report(bigint) from public, anon;
grant execute on function public.trash_report(bigint) to authenticated;
grant execute on function public.restore_report(bigint) to authenticated;

-- ----------------------------------------------------------- accounts

create function public.request_account_deletion()
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
  -- admin), so the purge couldn't delete this account.
  if exists (select 1 from public.alerts where posted_by = auth.uid()) then
    raise exception 'admin_has_alerts';
  end if;
  update public.users set deletion_requested_at = now()
   where user_id = auth.uid();
end;
$$;

create function public.cancel_account_deletion()
returns void
language sql
security definer
set search_path = ''
as $$
  update public.users set deletion_requested_at = null
   where user_id = auth.uid();
$$;

revoke all on function public.request_account_deletion() from public, anon;
revoke all on function public.cancel_account_deletion() from public, anon;
grant execute on function public.request_account_deletion() to authenticated;
grant execute on function public.cancel_account_deletion() to authenticated;

-- 05's instant delete is replaced by the 7-day wait.
drop function public.delete_my_account();

-- --------------------------------------------------- hourly clean-up
-- The old job deleted expired reports straight away (and left their
-- photos behind). Now pg_net calls the purge function every hour, which
-- erases what's been in the trash 30 days, photos included.
create extension if not exists pg_net;

select cron.unschedule('delete-expired-flood-reports');

select cron.schedule(
  'purge-trash',
  '15 * * * *',
  $$select net.http_post(
      url := 'https://zhoenxifrazofjzwjljr.supabase.co/functions/v1/purge',
      headers := '{"Content-Type": "application/json"}'::jsonb,
      body := '{}'::jsonb
    )$$
);

-- The purge function logs in as service_role. This project doesn't give
-- new tables to it automatically (01-08 only granted anon/authenticated),
-- so without this it gets "permission denied for table flood_reports".
grant select, delete on public.flood_reports to service_role;
grant select on public.users to service_role;
