import 'package:flutter/material.dart';

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
  late final AnimationController _glow = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() => _loading = true);
    // Short fake delay so the button's loading state is visible.
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
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
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GradientBackground(
        child: Stack(
          children: [
            const Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedWaves(height: 150),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 24,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      children: [
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
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
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
        // Soft breathing light behind the round part of the logo
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
    return AssetImageWithFallback(
      'assets/images/logo_icon.png',
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
              onPressed: _login,
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
