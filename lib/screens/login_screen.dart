import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/demo_data.dart';
import '../services/prefetch.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'home_shell.dart';

/// ============================================================
/// LOGIN SCREEN — demo login, no real accounts yet
/// ============================================================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  bool _obscurePassword = true;
  bool _loading = false;

  // `static` so the notice stays closed for the rest of the visit, even
  // after logging out and coming back to this screen.
  static bool _demoNoticeClosed = false;
  // Drives the "breathing" glow behind the logo. repeat(reverse: true)
  // goes 0 -> 1 over 3 s, then back 1 -> 0 over 3 s, forever.
  late final AnimationController _glow = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat(reverse: true);

  // initState runs once, when this screen is first created (before it is
  // drawn). Good for one-time setup.
  @override
  void initState() {
    super.initState();
    // Once this screen is showing, quietly start downloading what Home,
    // the Map tab, and Report incident need, so they're ready after Login.
    // addPostFrameCallback = "run this right after the first frame is
    // drawn", so the downloads never delay the login screen appearing.
    // `mounted` is false if the screen was already closed by then.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) prefetchAppContent(dark: AppColors(context).isDark);
    });
  }

  // Runs after initState, and again whenever something this screen reads
  // from `context` changes, like the theme. So when the user switches
  // dark/light, the matching logo images get loaded early too. (precache
  // can't go in initState: `context` isn't fully ready there yet.)
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    BrandLogo.precache(context);
  }

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  Future<void> _login({bool guest = false}) async {
    isGuest = guest;
    // A different person may be logging in: forget the last one's votes.
    myVotes.value = {};
    setState(() => _loading = true);
    // Short fake delay so the button's loading state is visible.
    await Future.delayed(const Duration(milliseconds: 700));
    // After an `await`, the screen might have been closed in the meantime;
    // using its context then would crash, so stop if it's gone.
    if (!mounted) return;
    // pushReplacement (not push): the login screen is REMOVED and Home
    // takes its place, so the back button doesn't return to login.
    Navigator.of(context).pushReplacement(slideRoute(const HomeShell()));
  }

  void _notInDemo(String what) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$what isn\'t available in the demo yet.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors(context);
    // Wide windows: photo panel on the left, the form on the right.
    // Phones: just the form (no photo, so the first screen loads fast).
    final wide = MediaQuery.sizeOf(context).width >= 900;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Expanded(flex: 5, child: _PhotoPanel()),
                Expanded(flex: 4, child: _formPane(c, wide: true)),
              ],
            )
          : _formPane(c),
    );
  }

  Widget _formPane(AppColors c, {bool wide = false}) {
    return GradientBackground(
      child: Stack(
        children: [
          const Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedWaves(height: 150),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, box) {
                final column = Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Dismissible "this is a demo" notice.
                    _demoNotice(c),
                    // Wide screens show the logo on the photo panel already.
                    if (!wide) ...[
                      FadeSlideIn(child: _logo(c)),
                      const SizedBox(height: 10),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 100),
                        child: Text(
                          'Flood Monitoring & Emergency Assistance',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: c.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                    ],
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 200),
                      child: _form(c),
                    ),
                    const SizedBox(height: 18),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 300),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.verified_user_outlined,
                            size: 14,
                            color: c.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'No sign up needed for this demo',
                            style: TextStyle(
                              color: c.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
                // While typing, the phone keyboard covers half the screen:
                // allow scrolling so the fields stay reachable.
                if (MediaQuery.viewInsetsOf(context).bottom > 0) {
                  return Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: column,
                      ),
                    ),
                  );
                }
                // Otherwise: exactly one screen tall, never a scrollbar.
                // On a short window the whole form shrinks a little to fit
                // (FittedBox only ever scales DOWN, never up).
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: SizedBox(
                        width: math.min(420, box.maxWidth - 48),
                        child: column,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Sits at the top of the form (in the normal flow, so it can never
  // cover the form, whatever the screen height).
  Widget _demoNotice(AppColors c) {
    return Padding(
      padding: EdgeInsets.only(bottom: _demoNoticeClosed ? 0 : 18),
      // Fades out smoothly when closed. When _demoNoticeClosed
      // becomes true, the child switches from the card to an empty
      // SizedBox; the transition fades the card AND shrinks its
      // height (SizeTransition) at the same time.
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: SizeTransition(sizeFactor: anim, child: child),
        ),
        child: _demoNoticeClosed
            ? const SizedBox(width: double.infinity)
            : FadeSlideIn(
                delay: const Duration(milliseconds: 700),
                child: _demoNoticeCard(c),
              ),
      ),
    );
  }

  Widget _demoNoticeCard(AppColors c) {
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const IconBadge(Icons.science_rounded, kLogoYellow, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This is a demo',
                  style: TextStyle(
                    color: c.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Just tap Login, no email or password needed. '
                  'There\'s no backend yet, so nothing is saved or sent. '
                  'Unofficial: not from the Mabalacat City government.',
                  style: TextStyle(
                    color: c.textSecondary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Dismiss',
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.close_rounded, color: c.textSecondary, size: 18),
            onPressed: () => setState(() => _demoNoticeClosed = true),
          ),
        ],
      ),
    );
  }

  Widget _logo(AppColors c) {
    // The logo image already includes the "agosalert." text.
    // If it fails to load, show the old glowing icon + title.
    return Stack(
      alignment: Alignment.topCenter,
      clipBehavior: Clip.none,
      children: [
        // Soft breathing light behind the round part of the logo.
        // Its center opacity goes between 0.16 and 0.30
        // (0.16 + 0.14 * _glow.value), fading to 0 at the edge.
        // top: -50 lets it stick out above the logo (Clip.none above
        // allows drawing outside the Stack).
        Positioned(
          top: -50,
          child: AnimatedBuilder(
            animation: _glow,
            builder: (context, _) => Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    kLogoCyan.withValues(alpha: 0.16 + _glow.value * 0.14),
                    kLogoCyan.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        ),
        _logoImage(c),
      ],
    );
  }

  Widget _logoImage(AppColors c) {
    return BrandLogo.icon(
      height: 170,
      fallback: Column(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: kBrandGradient,
            ),
            child: const Icon(
              Icons.waves_rounded,
              color: Colors.white,
              size: 44,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'AGOSALERT',
            style: TextStyle(
              color: c.textPrimary,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _form(AppColors c) {
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back',
            style: TextStyle(
              color: c.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 22,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Login to your account',
            style: TextStyle(color: c.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 22),
          const AppTextField(
            hint: 'Email or phone number',
            icon: Icons.alternate_email_rounded,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          AppTextField(
            hint: 'Password',
            icon: Icons.lock_outline_rounded,
            obscure: _obscurePassword,
            suffix: IconButton(
              tooltip: _obscurePassword ? 'Show password' : 'Hide password',
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: c.textSecondary,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _notInDemo('Password reset'),
              child: Text(
                'Forgot password?',
                style: TextStyle(
                  color: c.accent,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          GradientButton(
            label: 'Login',
            icon: Icons.arrow_forward_rounded,
            loading: _loading,
            onPressed: _login,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: Divider(color: c.border)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'or',
                  style: TextStyle(color: c.textSecondary, fontSize: 12),
                ),
              ),
              Expanded(child: Divider(color: c.border)),
            ],
          ),
          const SizedBox(height: 20),
          PressableScale(
            onTap: _login,
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: c.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AssetImageWithFallback(
                    'assets/images/google_logo.png',
                    width: 20,
                    height: 20,
                    fallback: Icon(
                      Icons.g_mobiledata,
                      color: c.textPrimary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Continue with Google',
                    style: TextStyle(
                      color: c.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () => _login(guest: true),
              child: Text(
                'Continue as guest',
                style: TextStyle(
                  color: c.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Popup for guests who tap something only logged-in users can do, like
/// voting. [action] finishes the title, e.g. 'vote' -> "Log in to vote".
/// "Log in" goes back to the login screen (removing every screen behind
/// it, like logging out).
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
                    const IconBadge(Icons.lock_rounded, kSkyBlue, size: 60),
                    const SizedBox(height: 14),
                    Text(
                      'Log in to $action',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: c.textPrimary,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Guests can only view. Log in or sign up to join in '
                      'and help your community.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: c.textSecondary,
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 20),
                    GradientButton(
                      label: 'Log in',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: () => Navigator.of(dialogContext)
                          .pushAndRemoveUntil(
                            slideRoute(const LoginScreen()),
                            (_) => false,
                          ),
                    ),
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: Text(
                        'Not now',
                        style: TextStyle(color: c.textSecondary),
                      ),
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

/// Wide screens: the left half of the login screen. A real Mabalacat
/// sunset, the logo, what the app is for, and a Kapampangan welcome.
class _PhotoPanel extends StatelessWidget {
  const _PhotoPanel();

  @override
  Widget build(BuildContext context) {
    return LocalPhotoView(
      kPhotoSunset,
      radius: 0,
      overlay: Stack(
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x33060911), Color(0xE6060911)],
              ),
            ),
            child: SizedBox.expand(),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: WaterLines(
              color: Colors.white.withValues(alpha: 0.18),
              height: 140,
              count: 5,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(56, 48, 56, 72),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // The white "alert" version of the logo reads well on the
                // dark photo in both themes.
                Image.asset('assets/images/logo_wordmark_dark.png', height: 30),
                const Spacer(),
                const Text(
                  'Mayap a salubung!',
                  style: TextStyle(
                    color: Color(0xFF7CC0EC),
                    fontSize: 17,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Welcome, in Kapampangan',
                  style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 12),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Know the water\nbefore it reaches you.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    height: 1.12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.2,
                  ),
                ),
                const SizedBox(height: 14),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: const Text(
                    'Live weather, flood reports from your neighbors, and help '
                    'when you need it, for every barangay in Mabalacat City.',
                    style: TextStyle(
                      color: Color(0xD9FFFFFF),
                      fontSize: 15,
                      height: 1.55,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Unofficial demo · a school project',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Asks "Log out?" and, if confirmed, goes back to the login screen.
/// Used by the More tab and by the profile menu in the desktop top bar.
void confirmLogout(BuildContext context) {
  showAppSheet(
    context,
    builder: (sheet) {
      final c = AppColors(sheet);
      return Column(
        children: [
          const IconBadge(Icons.logout_rounded, kDanger, size: 60),
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
            'You\'ll stop getting alerts on this device.',
            style: TextStyle(color: c.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 20),
          GradientButton(
            label: 'Log out',
            gradient: const LinearGradient(
              colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
            ),
            onPressed: () => Navigator.of(
              context,
            ).pushAndRemoveUntil(slideRoute(const LoginScreen()), (_) => false),
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: () => Navigator.of(sheet).pop(),
            child: Text('Cancel', style: TextStyle(color: c.textSecondary)),
          ),
        ],
      );
    },
  );
}
