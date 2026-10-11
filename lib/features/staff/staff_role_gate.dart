import 'package:flutter/material.dart';
import '../../app_shell.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';
import 'staff_dashboard_screen.dart';

/// Temporary launch chooser between the student app and the staff module.
/// Placeholder for the authentication screen; remove once sign-in exists.
class StaffRoleGate extends StatelessWidget {
  const StaffRoleGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primary, AppColors.secondary],
                    ),
                    boxShadow: AppShadows.glow,
                  ),
                  child:
                      const Icon(Icons.local_library_rounded, color: Colors.white, size: 42),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  AppStrings.appName,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Who is using the app today?',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: AppSpacing.xl),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: _RoleCard(
                    icon: Icons.school_rounded,
                    color: AppColors.secondary,
                    title: 'Continue as Student',
                    subtitle: 'Search books, reserve seats, check in with QR',
                    onTap: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const AppShell()),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: _RoleCard(
                    icon: Icons.badge_rounded,
                    color: AppColors.primary,
                    title: 'Staff Portal',
                    subtitle: 'Manage reservations, waitlists and availability',
                    onTap: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const StaffDashboardScreen()),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Demo build — authentication will replace this screen.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textTertiary,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      elevated: true,
      onTap: onTap,
      child: Row(
        children: [
          IconBadge(icon: icon, color: color, size: 52),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13, height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const Icon(Icons.arrow_forward_rounded, color: AppColors.primary),
        ],
      ),
    );
  }
}
