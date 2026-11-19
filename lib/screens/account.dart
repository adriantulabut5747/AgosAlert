import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

import '../data/demo_data.dart' show shortDate;
import '../services/auth.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'login_screen.dart';

/// ============================================================
/// ACCOUNT — logging in and out
/// ============================================================
///
/// The login screen itself is screens/login_screen.dart; the Supabase
/// calls are in services/auth.dart.

/// Opens the login screen on top of the guest's app ("Continue as
/// guest" there comes back here).
void logIn(BuildContext context) {
  Navigator.of(context).push(slideRoute(const LoginScreen()));
}

/// Popup for guests who tap something only logged-in users can do, like
/// voting. [action] finishes the title, e.g. 'vote' -> "Log in to vote".
Future<void> showLoginRequired(BuildContext context, {required String action}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: Colors.black.withValues(alpha: 0.5),
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (dialogContext, _, _) {
      final c = AppColors(dialogContext);
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          // At most 420 wide, so it stays a small card on desktops.
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Material(
              color: c.surface,
              borderRadius: BorderRadius.circular(28),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const IconBadge(CupertinoIcons.lock_fill, kBlue, size: 60),
                    const SizedBox(height: 14),
                    Text(
                      'Log in to $action',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: c.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Guests can only look around. A free account lets '
                      'you report floods and vote on reports.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: c.textSecondary,
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 20),
                    PrimaryButton(
                      label: 'Log in or sign up',
                      icon: CupertinoIcons.arrow_right,
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        logIn(context);
                      },
                    ),
                    const SizedBox(height: 4),
                    SecondaryButton(
                      label: 'Not now',
                      onPressed: () => Navigator.of(dialogContext).pop(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (_, anim, _, child) => FadeTransition(
      opacity: anim,
      child: ScaleTransition(
        scale: Tween(begin: 0.95, end: 1.0).animate(anim),
        child: child,
      ),
    ),
  );
}

/// Asks "Log out?" and, if confirmed, signs out and shows the login
/// screen. Used by the profile menu.
void confirmLogout(BuildContext context) {
  showAppSheet(
    context,
    builder: (sheet) {
      final c = AppColors(sheet);
      return Column(
        children: [
          const IconBadge(CupertinoIcons.square_arrow_right, kDanger, size: 60),
          const SizedBox(height: 14),
          Text(
            'Log out?',
            style: TextStyle(
              color: c.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'You\'ll go back to the login screen.',
            style: TextStyle(color: c.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Log out',
            color: kDanger,
            onPressed: () async {
              final nav = Navigator.of(context);
              await logOut();
              // Removes every screen behind it, so Back can't return to
              // the logged-in app.
              nav.pushAndRemoveUntil(
                slideRoute(const LoginScreen()),
                (_) => false,
              );
            },
          ),
          const SizedBox(height: 6),
          SecondaryButton(
            label: 'Cancel',
            onPressed: () => Navigator.of(sheet).pop(),
          ),
        ],
      );
    },
  );
}

/// Settings > Account > Name: changes the name shown on the user's
/// reports (the `full_name` column; 01_users.sql lets users update it).
void editDisplayName(BuildContext context, {VoidCallback? onSaved}) {
  final name = TextEditingController(text: me!.fullName);
  var busy = false;
  String? error;
  showAppSheet(
    context,
    builder: (sheet) => StatefulBuilder(
      builder: (sheet, setSheet) {
        final c = AppColors(sheet);
        Future<void> save() async {
          final value = name.text.trim();
          if (value.isEmpty) {
            return setSheet(() => error = 'Your name can\'t be empty.');
          }
          if (value.length > 100) {
            return setSheet(() => error = 'Keep it under 100 characters.');
          }
          setSheet(() {
            busy = true;
            error = null;
          });
          try {
            await saveMyName(value);
            onSaved?.call();
            if (sheet.mounted) Navigator.of(sheet).pop();
          } catch (_) {
            setSheet(() {
              busy = false;
              error = 'Couldn\'t save. Check your connection and try again.';
            });
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Your name',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: c.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Everyone sees it on your flood reports.',
              textAlign: TextAlign.center,
              style: TextStyle(color: c.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            AppTextField(
              hint: 'Full name',
              icon: CupertinoIcons.person,
              controller: name,
              autofillHints: const [AutofillHints.name],
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => save(),
            ),
            if (error != null) ...[
              const SizedBox(height: 8),
              Text(
                error!,
                style: const TextStyle(color: kDanger, fontSize: 13),
              ),
            ],
            const SizedBox(height: 16),
            PrimaryButton(label: 'Save', loading: busy, onPressed: save),
            const SizedBox(height: 6),
            SecondaryButton(
              label: 'Cancel',
              onPressed: () => Navigator.of(sheet).pop(),
            ),
          ],
        );
      },
    ),
  );
}

/// Settings > Delete account. Asks first, then starts the 7-day wait
/// (services/auth.dart requestAccountDeletion) and goes to the login
/// screen, which says until when logging in still keeps it.
void confirmDeleteAccount(BuildContext context) {
  var busy = false;
  String? error;
  showAppSheet(
    context,
    builder: (sheet) => StatefulBuilder(
      builder: (sheet, setSheet) {
        final c = AppColors(sheet);
        return Column(
          children: [
            const IconBadge(CupertinoIcons.trash_fill, kDanger, size: 60),
            const SizedBox(height: 14),
            Text(
              'Delete your account?',
              style: TextStyle(
                color: c.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'You\'re logged out everywhere and your reports are hidden. '
              'In $kAccountDeleteDays days your account, reports, photos '
              'and votes are deleted for good. Log in before then to keep '
              'it.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: c.textSecondary,
                fontSize: 13,
                height: 1.45,
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: 10),
              Text(
                error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: kDanger, fontSize: 13),
              ),
            ],
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Delete my account',
              color: kDanger,
              loading: busy,
              onPressed: () async {
                final nav = Navigator.of(context);
                setSheet(() {
                  busy = true;
                  error = null;
                });
                try {
                  final until = shortDate(
                    DateTime.now().add(
                      const Duration(days: kAccountDeleteDays),
                    ),
                  );
                  await requestAccountDeletion();
                  nav.pushAndRemoveUntil(
                    slideRoute(
                      LoginScreen(
                        message:
                            'Your account goes for good on $until. Changed your mind? Log in before then.',
                      ),
                    ),
                    (_) => false,
                  );
                } catch (e) {
                  setSheet(() {
                    busy = false;
                    error = '$e'.contains('admin_has_alerts')
                        ? 'Admin accounts that posted alerts can\'t be '
                              'deleted here. Email us (see Privacy Policy).'
                        : 'Couldn\'t delete it. Check your connection and '
                              'try again.';
                  });
                }
              },
            ),
            const SizedBox(height: 6),
            SecondaryButton(
              label: 'Cancel',
              onPressed: busy ? null : () => Navigator.of(sheet).pop(),
            ),
          ],
        );
      },
    ),
  );
}

// Plain-words message for a failed reset / password change, from
// Supabase's error codes (not its English messages).
String _passwordError(Object e) {
  if (e is! AuthException) {
    return 'Couldn\'t reach the server. Check your connection and try again.';
  }
  return switch (e.code) {
    'weak_password' =>
      'That password is too easy to guess. Add numbers or symbols.',
    'same_password' => 'That\'s your current password. Pick a new one.',
    'invalid_credentials' => 'Your current password is wrong.',
    'over_email_send_rate_limit' || 'over_request_rate_limit' =>
      'Too many tries. Wait a few minutes, then try again.',
    'email_address_invalid' ||
    'validation_failed' => 'That email doesn\'t look right. Check for typos.',
    _ => e.message,
  };
}

/// Login screen > "Forgot password?": emails a reset link. [email] fills
/// the field with what's already typed in the login form.
void forgotPassword(BuildContext context, {String email = ''}) {
  final field = TextEditingController(text: email.trim());
  var busy = false;
  var sent = false;
  String? error;
  showAppSheet(
    context,
    builder: (sheet) => StatefulBuilder(
      builder: (sheet, setSheet) {
        final c = AppColors(sheet);
        Future<void> send() async {
          if (!field.text.contains('@')) {
            return setSheet(() => error = 'Type the email you log in with.');
          }
          setSheet(() {
            busy = true;
            error = null;
          });
          try {
            await sendPasswordReset(field.text);
            setSheet(() => sent = true);
          } catch (e) {
            setSheet(() {
              busy = false;
              error = _passwordError(e);
            });
          }
        }

        final title = TextStyle(
          color: c.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        );
        final body = TextStyle(
          color: c.textSecondary,
          fontSize: 13,
          height: 1.45,
        );
        if (sent) {
          // Same answer whether or not the email has an account (Supabase
          // doesn't say either), so nobody can test who's signed up.
          return Column(
            children: [
              const IconBadge(CupertinoIcons.mail_solid, kBlue, size: 60),
              const SizedBox(height: 14),
              Text('Check your email', style: title),
              const SizedBox(height: 6),
              Text(
                'If ${field.text.trim()} has an account, a reset link is on '
                'its way. It works once, for 1 hour. Not there? Check Spam.',
                textAlign: TextAlign.center,
                style: body,
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Done',
                onPressed: () => Navigator.of(sheet).pop(),
              ),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Reset your password',
              textAlign: TextAlign.center,
              style: title,
            ),
            const SizedBox(height: 4),
            Text(
              'We\'ll email you a link to set a new one.',
              textAlign: TextAlign.center,
              style: body,
            ),
            const SizedBox(height: 16),
            AppTextField(
              hint: 'Email',
              icon: CupertinoIcons.mail,
              controller: field,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => send(),
            ),
            if (error != null) ...[
              const SizedBox(height: 8),
              Text(
                error!,
                style: const TextStyle(color: kDanger, fontSize: 13),
              ),
            ],
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Send reset link',
              color: kBlue,
              loading: busy,
              onPressed: send,
            ),
            const SizedBox(height: 6),
            SecondaryButton(
              label: 'Cancel',
              onPressed: () => Navigator.of(sheet).pop(),
            ),
          ],
        );
      },
    ),
  );
}

/// Settings > Account > Password, and (afterReset) what a reset email's
/// link opens: type the new password twice. Settings also asks for the
/// current one, so someone holding your unlocked phone can't lock you
/// out; the reset link skips it (that person forgot it).
void showChangePassword(BuildContext context, {bool afterReset = false}) {
  final current = TextEditingController();
  final first = TextEditingController();
  final again = TextEditingController();
  var busy = false;
  var show = false;
  String? error;
  showAppSheet(
    context,
    builder: (sheet) => StatefulBuilder(
      builder: (sheet, setSheet) {
        final c = AppColors(sheet);
        Future<void> save() async {
          if (!afterReset && current.text.isEmpty) {
            return setSheet(() => error = 'Type your current password first.');
          }
          if (first.text.length < 6) {
            return setSheet(() => error = 'Use at least 6 characters.');
          }
          if (first.text != again.text) {
            return setSheet(() => error = 'The two passwords don\'t match.');
          }
          setSheet(() {
            busy = true;
            error = null;
          });
          try {
            await changePassword(
              first.text,
              current: afterReset ? null : current.text,
            );
            if (!sheet.mounted) return;
            Navigator.of(sheet).pop();
            if (context.mounted) {
              showSuccessDialog(
                context,
                title: 'Password changed',
                message: 'Use the new one next time you log in.',
              );
            }
          } catch (e) {
            setSheet(() {
              busy = false;
              error = _passwordError(e);
            });
          }
        }

        // The show/hide eye sits on the top field and shows them all.
        Widget field(
          TextEditingController ctl,
          String hint, {
          bool top = false,
          bool last = false,
        }) => AppTextField(
          hint: hint,
          icon: CupertinoIcons.lock,
          controller: ctl,
          obscure: !show,
          autofillHints: [
            ctl == current ? AutofillHints.password : AutofillHints.newPassword,
          ],
          textInputAction: last ? TextInputAction.done : TextInputAction.next,
          onSubmitted: last ? (_) => save() : null,
          suffix: !top
              ? null
              : PressableScale(
                  onTap: () => setSheet(() => show = !show),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      show ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
                      color: c.textSecondary,
                      size: 20,
                    ),
                  ),
                ),
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              afterReset ? 'Set a new password' : 'Change password',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: c.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              afterReset
                  ? 'You\'re logged in from the email link. Pick a new password.'
                  : 'At least 6 characters.',
              textAlign: TextAlign.center,
              style: TextStyle(color: c.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            AutofillGroup(
              child: Column(
                children: [
                  if (!afterReset) ...[
                    field(current, 'Current password', top: true),
                    const SizedBox(height: 10),
                  ],
                  field(first, 'New password', top: afterReset),
                  const SizedBox(height: 10),
                  field(again, 'New password again', last: true),
                ],
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: 8),
              Text(
                error!,
                style: const TextStyle(color: kDanger, fontSize: 13),
              ),
            ],
            const SizedBox(height: 16),
            PrimaryButton(label: 'Save', loading: busy, onPressed: save),
            const SizedBox(height: 6),
            SecondaryButton(
              label: afterReset ? 'Later' : 'Cancel',
              onPressed: () => Navigator.of(sheet).pop(),
            ),
          ],
        );
      },
    ),
  );
}

/// After logging in to an account waiting to be deleted (Facebook
/// style): "Keep my account" cancels the deletion; "Log out" (or closing
/// the sheet) logs out and leaves it. True = the account was kept.
Future<bool> askKeepAccount(BuildContext context) async {
  final when = shortDate(me!.deletesAt!);
  var busy = false;
  String? error;
  final kept = await showAppSheet<bool>(
    context,
    builder: (sheet) => StatefulBuilder(
      builder: (sheet, setSheet) {
        final c = AppColors(sheet);
        return Column(
          children: [
            const IconBadge(CupertinoIcons.person_fill, kBlue, size: 60),
            const SizedBox(height: 14),
            Text(
              'Keep your account?',
              style: TextStyle(
                color: c.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'You asked to delete it. It goes for good on $when, with '
              'your reports, photos and votes, unless you keep it now.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: c.textSecondary,
                fontSize: 13,
                height: 1.45,
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: 10),
              Text(
                error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: kDanger, fontSize: 13),
              ),
            ],
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Keep my account',
              loading: busy,
              onPressed: () async {
                setSheet(() {
                  busy = true;
                  error = null;
                });
                try {
                  await cancelAccountDeletion();
                  if (sheet.mounted) Navigator.of(sheet).pop(true);
                } catch (_) {
                  setSheet(() {
                    busy = false;
                    error =
                        'Couldn\'t reach the server. Check your connection '
                        'and try again.';
                  });
                }
              },
            ),
            const SizedBox(height: 6),
            SecondaryButton(
              label: 'Log out',
              onPressed: busy ? null : () => Navigator.of(sheet).pop(false),
            ),
          ],
        );
      },
    ),
  );
  if (kept == true) return true;
  await logOut();
  return false;
}
