import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ledger_widgets.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../data/mock/mock_data.dart';
import '../../models/models.dart';
import '../notifications/notification_settings_screen.dart';
import '../waitlist/waitlist_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  var _profile = MockData.userProfile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 84,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Eyebrow('MEMBER SINCE 2024'),
            const SizedBox(height: 3),
            Text('Account', style: AppText.serif(24)),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppNavInset.bottom,
        ),
        children: [
          MemberCard(
            name: _profile.name,
            studentId: _profile.studentId,
            email: _profile.email,
            validThru: 'Thru 2027',
          ),
          const SizedBox(height: AppSpacing.lg),
          const Eyebrow('PRIVACY'),
          const SizedBox(height: AppSpacing.sm),
          SoftCard(
            elevated: true,
            padding: EdgeInsets.zero,
            child: SwitchListTile(
              secondary:
                  const IconBadge(icon: Icons.privacy_tip_outlined, size: 40),
              title: Text('Staff-only visibility',
                  style: AppText.sans(14.5, w: FontWeight.w700)),
              subtitle: Text(
                'Only library staff can see your active reservations and bookings.',
                style: AppText.sans(12.5,
                    color: AppColors.textSecondary, height: 1.35),
              ),
              value: _profile.reservationsVisibleToStaffOnly,
              onChanged: (v) => setState(
                () => _profile = UserProfile(
                  name: _profile.name,
                  studentId: _profile.studentId,
                  email: _profile.email,
                  reservationsVisibleToStaffOnly: v,
                  largeText: _profile.largeText,
                  highContrast: _profile.highContrast,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Eyebrow('ACCESSIBILITY'),
          const SizedBox(height: AppSpacing.sm),
          SoftCard(
            elevated: true,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                SwitchListTile(
                  secondary:
                      const IconBadge(icon: Icons.format_size_rounded, size: 40),
                  title: Text('Larger text',
                      style: AppText.sans(14.5, w: FontWeight.w700)),
                  subtitle: Text(
                    'Increases text size across the app',
                    style: AppText.sans(12.5, color: AppColors.textSecondary),
                  ),
                  value: _profile.largeText,
                  onChanged: (v) => setState(
                    () => _profile = UserProfile(
                      name: _profile.name,
                      studentId: _profile.studentId,
                      email: _profile.email,
                      reservationsVisibleToStaffOnly:
                          _profile.reservationsVisibleToStaffOnly,
                      largeText: v,
                      highContrast: _profile.highContrast,
                    ),
                  ),
                ),
                const Divider(height: 1, indent: 66),
                SwitchListTile(
                  secondary:
                      const IconBadge(icon: Icons.contrast_rounded, size: 40),
                  title: Text('High contrast',
                      style: AppText.sans(14.5, w: FontWeight.w700)),
                  subtitle: Text(
                    'Stronger color contrast for readability',
                    style: AppText.sans(12.5, color: AppColors.textSecondary),
                  ),
                  value: _profile.highContrast,
                  onChanged: (v) => setState(
                    () => _profile = UserProfile(
                      name: _profile.name,
                      studentId: _profile.studentId,
                      email: _profile.email,
                      reservationsVisibleToStaffOnly:
                          _profile.reservationsVisibleToStaffOnly,
                      largeText: _profile.largeText,
                      highContrast: v,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Eyebrow('QUICK LINKS'),
          const SizedBox(height: AppSpacing.sm),
          SoftCard(
            elevated: true,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _LinkTile(
                  icon: Icons.notifications_outlined,
                  title: 'Notification settings',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationSettingsScreen(),
                    ),
                  ),
                ),
                const Divider(height: 1, indent: 66),
                _LinkTile(
                  icon: Icons.hourglass_top_outlined,
                  title: 'Waitlist',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WaitlistScreen()),
                  ),
                ),
                const Divider(height: 1, indent: 66),
                _LinkTile(
                  icon: Icons.help_outline_rounded,
                  title: 'Help & support',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Help center coming soon — email library@university.edu'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Center(
            child: Eyebrow('LIBRARY+ · EST. 2024'),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: IconBadge(icon: icon, size: 40),
      title: Text(title, style: AppText.sans(14.5, w: FontWeight.w700)),
      trailing:
          const Icon(Icons.chevron_right_rounded, color: AppColors.textFaint),
      onTap: onTap,
    );
  }
}
