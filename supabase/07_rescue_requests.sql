-- ============================================================
-- AgosAlert: rescue requests + flagged numbers (paper, Tables 17-18)
-- ============================================================
-- Paste this whole file into Supabase > SQL Editor > New query > Run,
-- AFTER 01-06. Safe to run once.
--
-- What it makes:
--   * public.rescue_requests: "Request rescue" in the Help tab (FR-G8,
--     FR-R5). Guests send them too (user_id NULL), with a name and phone
--     number. Only admins see them all and change their status (FR-A3).
--   * public.flagged_numbers: numbers an admin confirmed sent a false
--     request (FR-A5). Admins only; the Admin page highlights new
--     requests from these numbers.
--   * create_rescue_request(...): how the app sends one. A function, so
--     guests can send without being allowed to read the table, get the
--     new request's id back, and are limited to 3 sends per number per
--     10 minutes (stops a stuck button or a prank script flooding it).
--   * rescue_request_status(id, phone): a guest's "track my request"
--     (FR-G9). Needs the id AND the phone it was sent with.
--   * A daily clean-up: requests are deleted 30 days after they're sent
--     (they hold phone numbers and health details), except flagged-false
--     ones, which the flag needs.
--
-- IMPORTANT (Nov 19 2026): nobody monitors these yet. The app says so in
-- big letters and tells people to call 911. Don't remove that notice
-- until real responders watch the Admin page.

create table public.rescue_requests (
  request_id    bigint generated always as identity primary key,
  -- Deleting an account deletes its requests (Privacy Policy: erasure).
  user_id       uuid references public.users (user_id) on delete cascade,
  contact_name  varchar(100) not null check (length(trim(contact_name)) > 0),
  -- Digits with an optional +, e.g. 09171234567 or +639171234567.
  contact_phone varchar(15)  not null check (contact_phone ~ '^\+?[0-9]{7,14}$'),
  barangay      varchar(50)  not null check (barangay in (
    'Atlu-Bola', 'Bical', 'Bundagul', 'Cacutud', 'Calumpang', 'Camachiles',
    'Dapdap', 'Dau', 'Dolores', 'Duquit', 'Lakandula', 'Mabiga',
    'Macapagal Village', 'Mamatitang', 'Mangalit', 'Marcos Village',
    'Mawaque', 'Paralayunan', 'Poblacion', 'San Francisco', 'San Joaquin',
    'Santa Ines', 'Santa Maria', 'Santo Rosario', 'Sapang Balen',
    'Sapang Biabas', 'Tabun')),
  latitude      decimal(9, 6) check (latitude between 15.130 and 15.300),
  longitude     decimal(9, 6) check (longitude between 120.490 and 120.670),
  people_count  smallint     not null check (people_count between 1 and 99),
  special_needs text[] check (special_needs <@ array[
    'elderly', 'pwd', 'infant_child', 'pregnant', 'medical_care']::text[]),
  note          text check (length(note) <= 500),
  status        varchar(20)  not null default 'received' check (status in (
    'received', 'verifying', 'help_on_the_way', 'resolved', 'flagged_false')),
  handled_by    uuid references public.users (user_id) on delete set null,
  created_at    timestamptz  not null default now(),
  updated_at    timestamptz  not null default now()
);

create index rescue_requests_created_at on public.rescue_requests (created_at desc);
create index rescue_requests_phone on public.rescue_requests (contact_phone, created_at);

-- Status changes: stamp when and which admin.
create function public.rescue_requests_stamp()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
begin
  new.updated_at := now();
  new.handled_by := (select auth.uid());
  return new;
end;
$$;

create trigger rescue_requests_stamp
  before update on public.rescue_requests
  for each row execute function public.rescue_requests_stamp();

create table public.flagged_numbers (
  phone_number varchar(15)  primary key,
  request_id   bigint       not null references public.rescue_requests (request_id) on delete cascade,
  reason       text,
  flagged_by   uuid         not null references public.users (user_id),
  flagged_at   timestamptz  not null default now()
);

create function public.flagged_numbers_stamp()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
begin
  new.flagged_by := (select auth.uid());
  new.flagged_at := now();
  return new;
end;
$$;

create trigger flagged_numbers_stamp
  before insert or update on public.flagged_numbers
  for each row execute function public.flagged_numbers_stamp();

-- ------------------------------------------------------------ rules
alter table public.rescue_requests enable row level security;
alter table public.flagged_numbers enable row level security;

-- No insert policy: everyone sends through create_rescue_request().
create policy "Users read their own requests; admins read all"
  on public.rescue_requests for select to authenticated
  using (user_id = (select auth.uid()) or public.is_admin());

create policy "Admins change request status"
  on public.rescue_requests for update to authenticated
  using (public.is_admin())
  with check (public.is_admin());

create policy "Admins manage flagged numbers"
  on public.flagged_numbers for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());

revoke all on public.rescue_requests from anon, authenticated;
revoke all on public.flagged_numbers from anon, authenticated;
grant select on public.rescue_requests to authenticated;
grant update (status) on public.rescue_requests to authenticated;
grant select, insert, update, delete on public.flagged_numbers to authenticated;

-- ------------------------------------------------------- functions
create function public.create_rescue_request(
  p_contact_name  text,
  p_contact_phone text,
  p_barangay      text,
  p_latitude      numeric,
  p_longitude     numeric,
  p_people_count  int,
  p_special_needs text[],
  p_note          text
)
returns bigint
language plpgsql
security definer set search_path = ''
as $$
declare
  new_id bigint;
begin
  if (select count(*) from public.rescue_requests
      where contact_phone = p_contact_phone
        and created_at > now() - interval '10 minutes') >= 3 then
    raise exception 'too_many_requests';
  end if;
  insert into public.rescue_requests (
    user_id, contact_name, contact_phone, barangay, latitude, longitude,
    people_count, special_needs, note)
  values (
    (select auth.uid()), trim(p_contact_name), p_contact_phone, p_barangay,
    p_latitude, p_longitude, p_people_count, p_special_needs,
    nullif(trim(p_note), ''))
  returning request_id into new_id;
  return new_id;
end;
$$;

-- A guest's own request: the id and phone it was sent with must match.
create function public.rescue_request_status(p_request_id bigint, p_contact_phone text)
returns table (status varchar, updated_at timestamptz)
language sql
stable
security definer set search_path = ''
as $$
  select r.status, r.updated_at from public.rescue_requests r
  where r.request_id = p_request_id and r.contact_phone = p_contact_phone;
$$;

revoke all on function public.create_rescue_request(text, text, text, numeric, numeric, int, text[], text) from public;
revoke all on function public.rescue_request_status(bigint, text) from public;
grant execute on function public.create_rescue_request(text, text, text, numeric, numeric, int, text[], text) to anon, authenticated;
grant execute on function public.rescue_request_status(bigint, text) to anon, authenticated;

-- Live updates: admins see new requests at once, users their status (FR-S3).
alter publication supabase_realtime add table public.rescue_requests;

-- ---------------------------------------------------- 30-day clean-up
select cron.schedule(
  'delete-old-rescue-requests',
  '30 3 * * *',
  $$delete from public.rescue_requests
    where created_at < now() - interval '30 days' and status <> 'flagged_false'$$
);
