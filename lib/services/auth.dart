import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter/foundation.dart' show ValueNotifier, kIsWeb;

import '../data/demo_data.dart';
import 'reports.dart' show deleteAllMyPhotos, loadReports;
import 'session.dart' show recoveryTokenHash;
import 'share.dart' show clearAddressQuery;
import 'supabase_config.dart';

/// ============================================================
/// AUTH — accounts, through Supabase
/// ============================================================
///
/// Supabase Auth checks the email + password (we never see a stored
/// password). Our own data about the person (name, barangay, role) is one
/// row of the `users` table, made by a trigger when they sign up: see
/// supabase/01_users.sql. [me] is that row once someone is logged in.
///
/// Supabase remembers the login in the browser, so a reload stays logged
/// in: [initAuth] picks it up before the app starts.

/// One row of the `users` table (paper, Table 14). Field names match
/// the columns, so the Laravel build can mirror them.
class AppUser {
  final String userId;
  final String fullName;
  final String email;
  final String? phoneNumber;
  final String barangay;
  final String role; // 'registered' or 'admin'
  final String accountStatus; // 'active' or 'suspended'

  const AppUser({
    required this.userId,
    required this.fullName,
    required this.email,
    this.phoneNumber,
    required this.barangay,
    this.role = 'registered',
    this.accountStatus = 'active',
  });

  AppUser.fromRow(Map<String, dynamic> row)
    : userId = row['user_id'] as String,
      fullName = row['full_name'] as String,
      email = row['email'] as String,
      phoneNumber = row['phone_number'] as String?,
      barangay = row['barangay'] as String,
      role = row['role'] as String,
      accountStatus = row['account_status'] as String;

  bool get isAdmin => role == 'admin';

  /// "Juan Dela Cruz" -> "JC", "Tugak" -> "T". For the avatar.
  String get initials {
    final words = fullName.trim().split(RegExp(r'\s+'));
    final first = words.first[0];
    return (words.length == 1 ? first : first + words.last[0]).toUpperCase();
  }
}

/// The logged-in user, or null for a guest.
AppUser? me;

/// Bumped when [me] changes in place (a new display name), so the top
/// bar's name and avatar rebuild.
final meChanged = ValueNotifier(0);

/// Guests can look around but can't vote or report (FR-G10).
bool get isGuest => me == null;

SupabaseClient get _db => Supabase.instance.client;

/// Connects to Supabase and, if this browser is still logged in, loads
/// the user's row. Called once in main(), before the app starts.
Future<void> initAuth() async {
  assert(kSupabaseUrl != '', 'Paste your project into supabase_config.dart');
  await Supabase.initialize(url: kSupabaseUrl, publishableKey: kSupabaseKey);
  final resetCode = recoveryTokenHash;
  if (resetCode != null) {
    clearAddressQuery(); // one use only: a reload mustn't try it again
    try {
      // Logs the person in with the email's one-time code. Checked here,
      // not by Supabase's own ?code= link, so the email works on any
      // device (that one only works in the browser that asked).
      await _db.auth.verifyOTP(type: OtpType.recovery, tokenHash: resetCode);
      resetLinkWorked = true;
    } catch (_) {
      resetLinkWorked = false; // used already, or older than an hour
    }
  }
  if (_db.auth.currentSession == null) return;
  try {
    await _loadMe();
  } catch (_) {
    // Offline, or the account was suspended: start on the login screen.
  }
}

/// Opened from a password reset email: true = logged in, ask for the new
/// password (main.dart); false = the link was used or expired; null = a
/// normal start.
bool? resetLinkWorked;

/// "Forgot password?": Supabase emails a reset link (through the Gmail
/// SMTP set in the dashboard; template: supabase/email_reset_password.html).
/// It says nothing about whether the email has an account, so nobody can
/// use it to find out who's signed up.
Future<void> sendPasswordReset(String email) =>
    _db.auth.resetPasswordForEmail(email.trim(), redirectTo: _appAddress);

/// Where the reset link lands: this app's own address (without ?...), or
/// the live app on phones. Must be in Supabase > Auth > URL Configuration
/// > Redirect URLs, or Supabase falls back to the Site URL.
String get _appAddress => kIsWeb
    ? '${Uri.base.origin}${Uri.base.path}'
    : 'https://adriantulabut5747.github.io/AgosAlert/app/';

/// Settings > Password, and the reset link's "Set a new password".
/// [current] (Settings only) is checked by logging in with it again,
/// because Supabase's own "require current password" check is a server
/// setting that isn't on.
/// shortcut: app-side only; someone holding a stolen login token could
/// still call the API directly. Enough for a demo.
Future<void> changePassword(String password, {String? current}) async {
  if (current != null) {
    await _db.auth.signInWithPassword(email: me!.email, password: current);
  }
  await _db.auth.updateUser(UserAttributes(password: password));
}

Future<void> logInWithEmail({
  required String email,
  required String password,
}) async {
  await _db.auth.signInWithPassword(email: email, password: password);
  await _loadMe();
}

/// Makes the account. The name and barangay ride along as "metadata",
/// which the database trigger copies into the new `users` row.
Future<void> signUp({
  required String fullName,
  required String email,
  required String password,
  required String barangay,
}) async {
  final res = await _db.auth.signUp(
    email: email,
    password: password,
    data: {'full_name': fullName, 'barangay': barangay},
  );
  // No session = Supabase wants the email confirmed first (the
  // "Confirm email" switch is on in the dashboard).
  if (res.session == null) {
    throw const AuthException(
      'Check your email to confirm your account, then log in.',
      code: 'confirm_email',
    );
  }
  await _loadMe();
}

Future<void> logOut() async {
  await _db.auth.signOut();
  _forgetMe();
}

/// Changes the name everyone sees on the user's reports.
Future<void> saveMyName(String fullName) async {
  final name = fullName.trim().replaceAll(RegExp(r'\s+'), ' ');
  await _db.from('users').update({'full_name': name}).eq('user_id', me!.userId);
  final u = me!;
  me = AppUser(
    userId: u.userId,
    fullName: name,
    email: u.email,
    phoneNumber: u.phoneNumber,
    barangay: u.barangay,
    role: u.role,
    accountStatus: u.accountStatus,
  );
  meChanged.value++;
  await loadReports(); // the feed shows poster names
}

/// Deletes the account for good: photos first (the database can't delete
/// Storage files), then supabase/05_account.sql's delete_my_account(),
/// whose cascade removes the users row, reports, votes and read-marks.
Future<void> deleteMyAccount() async {
  await deleteAllMyPhotos();
  await _db.rpc('delete_my_account');
  // The login no longer exists on the server: only forget it here.
  await _db.auth.signOut(scope: SignOutScope.local);
  _forgetMe();
}

void _forgetMe() {
  me = null;
  // A different person may use the app next: forget this one's answers.
  myVotes.value = {};
  stillFlooded.value = {};
  myBarangay.value = null;
}

/// Saves "My barangay" to the user's row.
Future<void> saveMyBarangay(String barangay) async {
  await _db
      .from('users')
      .update({'barangay': barangay})
      .eq('user_id', me!.userId);
}

Future<void> _loadMe() async {
  final row = await _db
      .from('users')
      .select()
      .eq('user_id', _db.auth.currentUser!.id)
      .single();
  final user = AppUser.fromRow(row);
  if (user.accountStatus != 'active') {
    await _db.auth.signOut();
    throw const AuthException(
      'This account is suspended. Contact the AgosAlert admin.',
      code: 'account_suspended',
    );
  }
  me = user;
  myBarangay.value = user.barangay;
}
