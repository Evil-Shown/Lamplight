import 'package:flutter/material.dart';

import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../models/models.dart';
import '../notifications/notifications_screen.dart';
import '../settings/settings_screen.dart';

/// The Profile tab.
///
/// Identity card, the privacy switch, shortcuts to notifications and
/// settings — plus sign-out, which returns to the login screen.
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final profile = state.activeProfile;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 28),
          children: [
            StaggeredEntrance(
              child: Text('Profile',
                  style: AppText.display(24, w: FontWeight.w700, ls: -0.5)),
            ),
            const SizedBox(height: 18),
            StaggeredEntrance(
              index: 1,
              child: _IdentityCard(profile: profile),
            ),
            const SizedBox(height: 24),
            const _MemberStats(),
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 10),
              child: SectionLabel('Privacy'),
            ),
            StaggeredEntrance(
              index: 2,
              child: SurfaceCard(
                padding: EdgeInsets.zero,
                child: SwitchListTile(
                  value: profile.reservationsVisibleToStaffOnly,
                  onChanged: (_) {},
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  title: Text('Staff-only visibility',
                      style: AppText.body(14.5)),
                  subtitle: Text(
                    'Only library staff can see your active reservations.',
                    style: AppText.body(12.5, color: AppColors.textSecondary),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 10),
              child: SectionLabel('Quick links'),
            ),
            StaggeredEntrance(
              index: 3,
              child: SurfaceCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    SettingRow(
                      label: 'Notifications',
                      icon: Icons.notifications_none_rounded,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      ),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    SettingRow(
                      label: 'Settings',
                      icon: Icons.settings_outlined,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      ),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    const SettingRow(
                      label: 'Help & support',
                      icon: Icons.help_outline_rounded,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            StaggeredEntrance(
              index: 4,
              child: PrimaryButton(
                label: 'Sign out',
                icon: Icons.logout_rounded,
                tone: ButtonTone.danger,
                onPressed: () => state.signOut(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppGradients.brand,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        boxShadow: AppShadows.primary,
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.18),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.28),
                width: 1.5,
              ),
            ),
            child: Text(
              profile.firstName.substring(0, 1).toUpperCase(),
              style: AppText.display(
                22,
                w: FontWeight.w800,
                color: AppColors.textInverse,
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.title(
                    16.5,
                    w: FontWeight.w700,
                    color: AppColors.textInverse,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  profile.studentId,
                  style: AppText.body(
                    12.5,
                    color: AppColors.textInverse.withValues(alpha: 0.78),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  profile.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body(
                    12,
                    color: AppColors.textInverse.withValues(alpha: 0.62),
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

/// A compact stat strip under the identity card — the numbers a student
/// actually cares about.
class _MemberStats extends StatelessWidget {
  const _MemberStats();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);

    return Row(
      children: [
        Expanded(
          child: SurfaceCard(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
            tint: AppColors.primary.withValues(alpha: 0.22),
            child: Column(
              children: [
                CountUp(
                  value: state.activeReservations.length,
                  style: AppText.display(
                    22,
                    w: FontWeight.w800,
                    color: AppColors.primary,
                    ls: -0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text('Books held',
                    style: AppText.body(11, color: AppColors.textFaint)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SurfaceCard(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
            tint: AppColors.accent.withValues(alpha: 0.22),
            child: Column(
              children: [
                CountUp(
                  value: state.bookings.length,
                  style: AppText.display(
                    22,
                    w: FontWeight.w800,
                    color: AppColors.accent,
                    ls: -0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text('Seats booked',
                    style: AppText.body(11, color: AppColors.textFaint)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SurfaceCard(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
            tint: AppColors.cyan.withValues(alpha: 0.22),
            child: Column(
              children: [
                CountUp(
                  value: state.waitlist.length,
                  style: AppText.display(
                    22,
                    w: FontWeight.w800,
                    color: AppColors.cyan,
                    ls: -0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text('Waiting',
                    style: AppText.body(11, color: AppColors.textFaint)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
