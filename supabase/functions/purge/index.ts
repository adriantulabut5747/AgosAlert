// ============================================================
// AgosAlert: the hourly clean-up (Edge Function "purge")
// ============================================================
// Erases, photos first, then rows:
//   * reports that have been in the trash 30 days (deleted, or past
//     their 14-day expiry), with their photo files;
//   * accounts 7 days after "Delete account" whose owner never logged
//     back in: every file in their photo folder, then their login (the
//     cascades remove their users row, reports, votes and read-marks).
// SQL can't delete Storage files, which is why this is a function.
//
// Make it once (no CLI needed):
//   1. Supabase > Edge Functions > Deploy a new function > Via Editor.
//   2. Name it exactly: purge
//   3. Paste this whole file, Deploy.
//   4. Its Details / Settings: turn OFF "Verify JWT" (Enforce JWT
//      verification). pg_cron calls it with no key. That's safe: calling
//      it only erases what's already due, nothing else.
//   5. Then run supabase/09_trash.sql, which calls it every hour.
// Test: the function's "Test" button should answer {"reports":0,...}.

import { createClient } from 'npm:@supabase/supabase-js@2';

// Supabase fills these in for every function. The service key skips the
// rules (RLS), so it never leaves this server.
// Older projects get SUPABASE_SERVICE_ROLE_KEY; newer ones only the
// sb_secret_ keys, as JSON ({"default": "sb_secret_..."}).
const key = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? JSON.parse(Deno.env.get('SUPABASE_SECRET_KEYS') ?? '{}').default;
if (!key) throw new Error('No service / secret key in this function');
const db = createClient(Deno.env.get('SUPABASE_URL')!, key);
const photos = db.storage.from('report-photos');
const DAY = 86_400_000;

function check<T>({ data, error }: { data: T; error: unknown }): T {
  if (error) throw error;
  return data;
}

Deno.serve(async () => {
  try {
    // ---------------------------------------- reports, 30 days in the trash
    const cutoff = new Date(Date.now() - 30 * DAY).toISOString();
    const reports = check(
      await db
        .from('flood_reports')
        .select('report_id, photo_url')
        .or(`deleted_at.lte."${cutoff}",expires_at.lte."${cutoff}"`)
        .limit(500), // the rest go next hour
    );
    const paths = reports.map((r) => r.photo_url?.split('/report-photos/')[1]).filter((p): p is string => !!p);
    // A failed photo delete stops here, so the row stays and it's retried next hour.
    if (paths.length) check(await photos.remove(paths));
    if (reports.length) {
      check(
        await db
          .from('flood_reports')
          .delete()
          .in(
            'report_id',
            reports.map((r) => r.report_id),
          ),
      );
    }

    // ---------------------------------- accounts, 7 days after the request
    const users = check(
      await db
        .from('users')
        .select('user_id')
        .lte('deletion_requested_at', new Date(Date.now() - 7 * DAY).toISOString()),
    );
    for (const { user_id } of users) {
      // list() returns up to 1000 at a time: repeat until the folder is empty.
      for (;;) {
        const files = check(await photos.list(user_id, { limit: 1000 }));
        if (!files.length) break;
        check(await photos.remove(files.map((f) => `${user_id}/${f.name}`)));
      }
      check(await db.auth.admin.deleteUser(user_id));
    }

    return Response.json({ reports: reports.length, accounts: users.length });
  } catch (e) {
    console.error(e);
    return Response.json({ error: String((e as Error)?.message ?? e) }, { status: 500 });
  }
});
