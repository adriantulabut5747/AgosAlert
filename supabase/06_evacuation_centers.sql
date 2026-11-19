-- ============================================================
-- AgosAlert: evacuation centers (paper, Table 21)
-- ============================================================
-- Paste this whole file into Supabase > SQL Editor > New query > Run,
-- AFTER 01-05. Safe to run once.
--
-- What it makes:
--   * public.evacuation_centers: the centers on the Map and in Help.
--     Everyone (guests too) reads them; only admins add, edit or delete
--     (FR-G5, FR-A8), from the app's Admin page.
--   * The 4 centers the app showed before, as SAMPLE rows.
--
-- Differences from the paper's Table 21 (Adrian's calls):
--   * NO capacity / current_evacuees (Nov 13 2026): nobody can know how
--     many people are inside, so the app doesn't pretend to. Update the
--     paper's table and FR-G5 / FR-A8 to match.
--   * is_sample (extra): true = made-up demo row, shown with a SAMPLE
--     badge. Real centers (once the CDRRMO list comes) are added with
--     is_sample = false, and the sample rows deleted.

create table public.evacuation_centers (
  center_id  bigint generated always as identity primary key,
  name       varchar(120) not null check (length(trim(name)) > 0),
  barangay   varchar(50)  not null check (barangay in (
    'Atlu-Bola', 'Bical', 'Bundagul', 'Cacutud', 'Calumpang', 'Camachiles',
    'Dapdap', 'Dau', 'Dolores', 'Duquit', 'Lakandula', 'Mabiga',
    'Macapagal Village', 'Mamatitang', 'Mangalit', 'Marcos Village',
    'Mawaque', 'Paralayunan', 'Poblacion', 'San Francisco', 'San Joaquin',
    'Santa Ines', 'Santa Maria', 'Santo Rosario', 'Sapang Balen',
    'Sapang Biabas', 'Tabun')),
  -- Same box as kCityBounds in the app: centers must be in Mabalacat.
  latitude   decimal(9, 6) not null check (latitude between 15.130 and 15.300),
  longitude  decimal(9, 6) not null check (longitude between 120.490 and 120.670),
  status     varchar(10)  not null default 'standby'
               check (status in ('open', 'standby', 'closed')),
  photo_url  text,
  is_sample  boolean      not null default false,
  updated_by uuid references public.users (user_id) on delete set null,
  updated_at timestamptz  not null default now()
);

-- Who changed it and when: set by the database, not the app.
create function public.evacuation_centers_stamp()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
begin
  new.updated_at := now();
  new.updated_by := (select auth.uid());
  return new;
end;
$$;

create trigger evacuation_centers_stamp
  before insert or update on public.evacuation_centers
  for each row execute function public.evacuation_centers_stamp();

alter table public.evacuation_centers enable row level security;

create policy "Anyone reads centers"
  on public.evacuation_centers for select to anon, authenticated
  using (true);

create policy "Admins add centers"
  on public.evacuation_centers for insert to authenticated
  with check (public.is_admin());

create policy "Admins edit centers"
  on public.evacuation_centers for update to authenticated
  using (public.is_admin())
  with check (public.is_admin());

create policy "Admins delete centers"
  on public.evacuation_centers for delete to authenticated
  using (public.is_admin());

revoke all on public.evacuation_centers from anon, authenticated;
grant select on public.evacuation_centers to anon, authenticated;
grant insert (name, barangay, latitude, longitude, status, photo_url, is_sample),
      update (name, barangay, latitude, longitude, status, photo_url, is_sample),
      delete
  on public.evacuation_centers to authenticated;

-- Live updates: a status change shows on everyone's map (FR-S3).
alter publication supabase_realtime add table public.evacuation_centers;

-- The app's old made-up centers, kept as SAMPLE rows until the real list
-- arrives. (Run from the SQL Editor there's no logged-in user, so
-- updated_by stays empty.)
insert into public.evacuation_centers (name, barangay, latitude, longitude, status, is_sample) values
  ('Mabalacat City Sports Complex', 'Mabiga',    15.210000, 120.576000, 'open',    true),
  ('Mabalacat City Hall Grounds',   'Poblacion', 15.223000, 120.573500, 'open',    true),
  ('Dau Elementary School',         'Dau',       15.179000, 120.586000, 'open',    true),
  ('Dolores Covered Court',         'Dolores',   15.215000, 120.560000, 'closed',  true);
