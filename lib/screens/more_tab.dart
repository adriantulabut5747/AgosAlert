import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/common.dart';
import 'evacuation_centers_screen.dart';
import 'home_shell.dart';
import 'info_screens.dart';
import 'login_screen.dart';
import 'settings_screen.dart';

/// ============================================================
/// MORE TAB — profile, shortcuts, settings, help, log out
/// ============================================================
class MoreTab extends StatelessWidget {
  const MoreTab({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors(context);
    void push(Widget page) => Navigator.of(context).push(slideRoute(page));
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      children: [
        const PageHeader('More'),
        const SizedBox(height: 16),
        FadeSlideIn(child: _profileCard(c)),
        const SizedBox(height: 24),
        FadeSlideIn(
          delay: const Duration(milliseconds: 80),
          child: _group(c, 'Safety', [
            _Item(
              Icons.map_rounded,
              'Flood map',
              kSkyBlue,
              () => HomeShell.of(context)?.switchTab(1),
            ),
            _Item(
              Icons.night_shelter_rounded,
              'Evacuation centers',
              kSafe,
              () => push(const EvacuationCentersScreen()),
            ),
            _Item(
              Icons.phone_in_talk_rounded,
              'Emergency hotlines',
              kDanger,
              () => HomeShell.of(context)?.switchTab(3),
            ),
          ]),
        ),
        const SizedBox(height: 18),
        FadeSlideIn(
          delay: const Duration(milliseconds: 140),
          child: _group(c, 'App', [
            _Item(
              Icons.tune_rounded,
              'Settings',
              const Color(0xFF6366F1),
              () => push(const SettingsScreen()),
            ),
            _Item(
              Icons.help_rounded,
              'Help & FAQ',
              const Color(0xFF14B8A6),
              () => push(const HelpScreen()),
            ),
            _Item(
              Icons.info_rounded,
              'About AgosAlert',
              kLogoCyan,
              () => push(const AboutScreen()),
            ),
          ]),
        ),
        const SizedBox(height: 18),
        FadeSlideIn(
          delay: const Duration(milliseconds: 200),
          child: _group(c, null, [
            _Item(
              Icons.logout_rounded,
              'Log out',
              kDanger,
              () => _confirmLogout(context),
              destructive: true,
            ),
          ]),
        ),
        const SizedBox(height: 28),
        Center(
          child: Column(
            children: [
              Opacity(
                opacity: 0.8,
                child: const BrandLogo.wordmark(height: 20),
              ),
              const SizedBox(height: 6),
              Text(
                'Version 1.0.0 · Made in Mabalacat City',
                style: TextStyle(color: c.textSecondary, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _profileCard(AppColors c) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [kOceanBlue, kSkyBlue, kLogoCyan],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: kSkyBlue.withValues(alpha: 0.4),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AnimatedWaves(
                height: 60,
                colors: [Color(0x14FFFFFF), Color(0x1FFFFFFF)],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.2),
                      border: Border.all(color: Colors.white, width: 2.5),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'AP',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AC Parcore',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Text(
                          'ac.parcore@mcc.edu.ph',
                          style: TextStyle(
                            color: Color(0xD9FFFFFF),
                            fontSize: 12.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                color: Colors.white,
                                size: 13,
                              ),
                              SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'Mabalacat City resident',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _group(AppColors c, String? title, List<_Item> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) FieldLabel(title),
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) Divider(height: 1, indent: 64, color: c.border),
                _row(c, items[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _row(AppColors c, _Item item) {
    return InkWell(
      onTap: item.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            IconBadge(item.icon, item.color, size: 36, squircle: true),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(
                  color: item.destructive ? kDanger : c.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (!item.destructive)
              Icon(Icons.chevron_right_rounded, color: c.textSecondary),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
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
              onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                slideRoute(const LoginScreen()),
                (_) => false,
              ),
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
}

class _Item {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool destructive;
  const _Item(
    this.icon,
    this.label,
    this.color,
    this.onTap, {
    this.destructive = false,
  });
}
