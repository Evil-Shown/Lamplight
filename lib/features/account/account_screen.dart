import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
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
    final initials =
        _profile.name.split(' ').map((n) => n[0]).take(2).join();

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppNavInset.bottom,
        ),
        children: [
          SoftCard(
            elevated: true,
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primaryLight, AppColors.primary],
                    ),
                    boxShadow: AppShadows.soft,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 24,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _profile.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _profile.studentId,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      Text(
                        _profile.email,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textTertiary,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _SectionTitle('Privacy'),
          SoftCard(
            elevated: true,
            padding: EdgeInsets.zero,
            child: SwitchListTile(
              title: const Text('Staff-only visibility', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text(
                'Only library staff can see your active reservations and bookings.',
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
          const _SectionTitle('Accessibility'),
          SoftCard(
            elevated: true,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Larger text', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Increases text size across the app'),
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
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('High contrast', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Stronger color contrast for readability'),
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
          const _SectionTitle('Quick links'),
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
                const Divider(height: 1),
                _LinkTile(
                  icon: Icons.hourglass_top_outlined,
                  title: 'Waitlist',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WaitlistScreen()),
                  ),
                ),
                const Divider(height: 1),
                _LinkTile(
                  icon: Icons.help_outline_rounded,
                  title: 'Help & support',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Help center coming soon — email library@university.edu'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const AlertBanner(
            tone: AlertTone.info,
            icon: Icons.touch_app_rounded,
            message: 'Interactive controls are sized for comfortable tapping (48dp+).',
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.1,
            ),
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
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
      onTap: onTap,
    );
  }
}
