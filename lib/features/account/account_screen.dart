import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app_shell.dart';
import '../../core/feedback/app_feedback.dart';
import '../../core/navigation/app_route.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../models/models.dart';
import '../help/help_screen.dart';
import '../journal/reading_journal_screen.dart';
import '../loans/loans_screen.dart';
import '../notifications/notifications_screen.dart';
import '../staff/admin/staff_management_screen.dart';
import '../settings/settings_screen.dart';

/// The word the user must type to confirm deleting their account.
const String kDeleteConfirmWord = 'DELETE';

/// The Profile tab.
///
/// Identity card, member pass, stats strip, library loans, privacy switches,
/// data export & deletion, shortcuts to settings and help, plus sign-out.
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _setVisibility(
      BuildContext context, AppState state, bool value) async {
    try {
      await state.updateProfile(reservationsVisibleToStaffOnly: value);
    } catch (_) {
      if (context.mounted) {
        AppFeedback.error();
        _snack(context, "Couldn't save that change. Check your connection.");
      }
    }
  }

  Future<void> _deleteAccount(BuildContext context, AppState state) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const DeleteAccountDialog(),
    );
    if (confirmed != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await state.deleteAccount();
      // Signed out: the app returns to the login screen.
    } catch (e) {
      AppFeedback.error();
      messenger.showSnackBar(SnackBar(content: Text(deleteFailureMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final profile = state.activeProfile;
    final overdue = state.overdueLoans.length;
    final activeLoansCount = state.activeLoans.length;
    final notice = state.roleNotice;
    final staff = state.isStaff;
    final isDark = AppColors.isDark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenMargin,
            AppSpacing.lg,
            AppSpacing.screenMargin,
            AppSpacing.scrollBottomInset,
          ),
          children: [
            // App-level cached-data banner (D-14).
            ConnectivityBanner(lastSyncedAt: state.lastSyncedAt),
            if (notice != null) ...[
              Callout(
                tone: CalloutTone.warning,
                icon: Icons.badge_outlined,
                title: 'Staff access',
                message: notice,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: state.clearRoleNotice,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(44, 44),
                    foregroundColor: isDark
                        ? const Color(0xFFFBBF24)
                        : AppColors.primary,
                  ),
                  child: const Text('Dismiss'),
                ),
              ),
            ],
            // Top Profile Header with Quick Theme Toggle
            StaggeredEntrance(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Text(
                              staff ? 'Account' : 'Profile',
                              style: AppText.title(28,
                                  w: FontWeight.w800, ls: -0.8),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.primary.withValues(alpha: 0.18)
                                    : const Color(0xFFFEF3C7),
                                borderRadius:
                                    BorderRadius.circular(AppRadii.full),
                                border: Border.all(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.35),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    staff
                                        ? Icons.badge_rounded
                                        : Icons.auto_stories_rounded,
                                    size: 11,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    staff ? 'STAFF' : 'MEMBER',
                                    style: AppText.overline(
                                      10,
                                      ls: 0.8,
                                      w: FontWeight.w800,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          staff
                              ? 'Campus staff & desk administration'
                              : 'Member identity & reading preferences',
                          style: AppText.body(13,
                              color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  _HeaderThemeToggle(
                    isDark: isDark,
                    onToggle: () {
                      AppFeedback.tap();
                      state.setThemeMode(
                        isDark ? ThemeMode.light : ThemeMode.dark,
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            StaggeredEntrance(
              index: 1,
              child: _IdentityCard(
                profile: profile,
                roleLabel: staff
                    ? (state.isAdmin ? 'Administrator' : 'Library staff')
                    : null,
                onEdit: () => showGlassSheet<void>(
                  context,
                  builder: (_) => EditProfileSheet(profile: profile),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            if (!staff) ...[
              const _MemberStats(),
              const SizedBox(height: AppSpacing.sectionGap),
              const _SectionHeader(
                label: 'Library & Reading',
                icon: Icons.local_library_outlined,
              ),
              StaggeredEntrance(
                index: 2,
                child: _ProfileCard(
                  child: Column(
                    children: [
                      SettingRow(
                        label: 'My loans',
                        subtitle: overdue > 0
                            ? '$overdue book overdue'
                            : (activeLoansCount > 0
                                ? '$activeLoansCount borrowed items'
                                : 'Borrowing history & renewals'),
                        icon: Icons.menu_book_rounded,
                        iconColor: const Color(0xFFD97706),
                        iconBgColor: const Color(0xFFFEF3C7),
                        trailing: overdue > 0
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3.5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.errorContainer,
                                  borderRadius:
                                      BorderRadius.circular(AppRadii.full),
                                ),
                                child: Text(
                                  '$overdue overdue',
                                  style: AppText.label(
                                    11.5,
                                    w: FontWeight.w700,
                                    color: AppColors.error,
                                  ),
                                ),
                              )
                            : (activeLoansCount > 0
                                ? Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF3C7),
                                      borderRadius: BorderRadius.circular(
                                          AppRadii.full),
                                    ),
                                    child: Text(
                                      '$activeLoansCount active',
                                      style: AppText.label(
                                        11.5,
                                        w: FontWeight.w700,
                                        color: const Color(0xFFD97706),
                                      ),
                                    ),
                                  )
                                : null),
                        onTap: () =>
                            AppRoute.push(context, const LoansScreen()),
                      ),
                      const _RowDivider(),
                      SettingRow(
                        label: 'Reading journal',
                        subtitle: 'Notes, reflections & passage quotes',
                        icon: Icons.edit_note_rounded,
                        iconColor: const Color(0xFF0D9488),
                        iconBgColor: const Color(0xFFCCFBF1),
                        onTap: () => AppRoute.push(
                            context, const ReadingJournalScreen()),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sectionGap),
            ],
            if (state.isAdmin) ...[
              const _SectionHeader(
                label: 'Administration',
                icon: Icons.admin_panel_settings_outlined,
              ),
              StaggeredEntrance(
                index: 2,
                child: _ProfileCard(
                  child: SettingRow(
                    label: 'Staff management',
                    subtitle: 'Manage librarian accounts & roles',
                    icon: Icons.admin_panel_settings_outlined,
                    iconColor: const Color(0xFF4F46E5),
                    iconBgColor: const Color(0xFFEEF2FF),
                    onTap: () => AppRoute.push(
                        context, const StaffManagementScreen()),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sectionGap),
            ],
            const _SectionHeader(
              label: 'Privacy & Security',
              icon: Icons.shield_outlined,
            ),
            StaggeredEntrance(
              index: 3,
              child: _ProfileCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!staff) ...[
                      SettingRow(
                        label: 'Staff-only visibility',
                        subtitle:
                            'Hide your reservations from other members',
                        icon: Icons.visibility_off_outlined,
                        iconColor: const Color(0xFF4F46E5),
                        iconBgColor: const Color(0xFFEEF2FF),
                        switchValue: profile.reservationsVisibleToStaffOnly,
                        onSwitchChanged: (v) =>
                            _setVisibility(context, state, v),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(68, 0, 16, 12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E293B)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(AppRadii.sm),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF334155).withValues(alpha: 0.6)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                size: 14,
                                color: AppColors.textFaint,
                              ),
                              const SizedBox(width: 7),
                              Expanded(
                                child: Text(
                                  'Only library staff can see your active seat bookings and desk holds.',
                                  style: AppText.body(
                                    11.5,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const _RowDivider(),
                    ],
                    SettingRow(
                      label: 'Download my data',
                      subtitle: 'Export reservations and history as JSON',
                      icon: Icons.file_download_outlined,
                      iconColor: const Color(0xFF0284C7),
                      iconBgColor: const Color(0xFFE0F2FE),
                      onTap: () => showGlassSheet<void>(
                        context,
                        builder: (_) => const ExportDataSheet(),
                      ),
                    ),
                    if (!staff) ...[
                      const _RowDivider(),
                      SettingRow(
                        label: 'Delete my account',
                        subtitle:
                            'Permanently erase your account and history',
                        icon: Icons.delete_outline_rounded,
                        iconColor: AppColors.error,
                        iconBgColor: AppColors.errorContainer,
                        labelColor: AppColors.error,
                        onTap: () => _deleteAccount(context, state),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            const _SectionHeader(
              label: 'Preferences & Support',
              icon: Icons.bolt_rounded,
            ),
            StaggeredEntrance(
              index: 4,
              child: _ProfileCard(
                child: Column(
                  children: [
                    SettingRow(
                      label: 'Notifications',
                      subtitle: 'Reminders & reservation status',
                      icon: Icons.notifications_none_rounded,
                      iconColor: const Color(0xFFD97706),
                      iconBgColor: const Color(0xFFFEF3C7),
                      trailing: state.unreadCount > 0
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3.5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius:
                                    BorderRadius.circular(AppRadii.full),
                              ),
                              child: Text(
                                '${state.unreadCount} new',
                                style: AppText.label(
                                  11.5,
                                  w: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : null,
                      onTap: () => AppRoute.push(
                        context,
                        const NotificationsScreen(),
                      ),
                    ),
                    const _RowDivider(),
                    SettingRow(
                      label: 'App settings',
                      subtitle: 'Themes, sound, haptics & accessibility',
                      icon: Icons.tune_rounded,
                      iconColor: const Color(0xFF475569),
                      iconBgColor: const Color(0xFFF1F5F9),
                      onTap: () => AppRoute.push(
                        context,
                        const SettingsScreen(),
                      ),
                    ),
                    const _RowDivider(),
                    SettingRow(
                      label: 'Help & support',
                      subtitle: 'FAQs, guidelines & desk contact',
                      icon: Icons.help_outline_rounded,
                      iconColor: const Color(0xFF059669),
                      iconBgColor: const Color(0xFFD1FAE5),
                      onTap: () => AppRoute.push(context, const HelpScreen()),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            StaggeredEntrance(
              index: 5,
              child: PressScale(
                onTap: () async {
                  final confirmed = await showConfirmDialog(
                    context,
                    title: 'Sign out of Lamplight?',
                    body: 'Your reservations stay saved. Data on this phone '
                        'is cleared and you return to the sign-in screen.',
                    confirmLabel: 'Sign out',
                    cancelLabel: 'Stay signed in',
                  );
                  if (confirmed && context.mounted) await state.signOut();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(
                      alpha: isDark ? 0.12 : 0.06,
                    ),
                    borderRadius: BorderRadius.circular(AppRadii.card),
                    border: Border.all(
                      color: AppColors.error.withValues(
                        alpha: isDark ? 0.35 : 0.22,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.logout_rounded,
                        size: 18,
                        color: AppColors.error,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Sign out',
                        style: AppText.title(
                          15,
                          w: FontWeight.w700,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Center(
              child: Text(
                'Lamplight Library • v$kAppVersion',
                style: AppText.label(11.5, color: AppColors.textFaint),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Turns a delete-account failure into something the user can act on.
String deleteFailureMessage(Object error) {
  final text = error.toString();
  if (text.contains('requires-recent-login')) {
    return 'For security, sign out and sign in again, then retry deleting '
        'your account.';
  }
  if (text.contains('network') || text.contains('unavailable')) {
    return 'No connection. Your account was not deleted. Try again online.';
  }
  return "We couldn't delete your account. Nothing was removed; please try "
      'again.';
}

/// Elegant surface card with solid crisp background, subtle border,
/// and soft drop shadow so items never wash out against nature backdrops.
class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.scheme.surfaceContainerLow.withValues(alpha: 0.97)
            : Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(
          color: isDark
              ? const Color(0xFF334155).withValues(alpha: 0.85)
              : const Color(0xFFE2E8F0),
        ),
        boxShadow: isDark
            ? AppGlass.shadows
            : [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: child,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            label.toUpperCase(),
            style: AppText.overline(
              11.5,
              ls: 1.2,
              w: FontWeight.w800,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 68,
      endIndent: 16,
      color: AppColors.isDark
          ? const Color(0xFF334155).withValues(alpha: 0.5)
          : const Color(0xFFE2E8F0),
    );
  }
}

class _HeaderThemeToggle extends StatelessWidget {
  const _HeaderThemeToggle({required this.isDark, required this.onToggle});

  final bool isDark;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: isDark ? 'Switch to light mode' : 'Switch to dark mode',
      child: PressScale(
        onTap: onToggle,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Icon(
            isDark ? Icons.light_mode_rounded : Icons.dark_mode_outlined,
            size: 20,
            color: isDark ? const Color(0xFFFBBF24) : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

void showDigitalPassSheet(
    BuildContext context, UserProfile profile, String? roleLabel) {
  AppFeedback.tap();
  showGlassSheet<void>(
    context,
    builder: (sheetContext) {
      final isDark = AppColors.isDark;
      final studentId = profile.studentId.isNotEmpty
          ? profile.studentId
          : 'STU-2026-8819';
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenMargin,
          AppSpacing.sm,
          AppSpacing.screenMargin,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  child: Icon(
                    Icons.badge_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Campus Library Pass',
                        style: AppText.title(18, w: FontWeight.w800),
                      ),
                      Text(
                        'Turnstile entry & circulation desk scan',
                        style: AppText.body(12,
                            color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? const [Color(0xFF1E293B), Color(0xFF0F172A)]
                      : const [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
                ),
                borderRadius: BorderRadius.circular(AppRadii.lg),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.auto_stories_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'LAMPLIGHT CAMPUS',
                        style: AppText.overline(
                          11.5,
                          ls: 1.2,
                          w: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      const Spacer(),
                      StatusPill(
                        label: roleLabel ?? 'ACTIVE SCHOLAR',
                        color: AppColors.primary,
                        compact: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: QrPassTile(
                      data: studentId,
                      size: 150,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    profile.name,
                    textAlign: TextAlign.center,
                    style: AppText.title(17, w: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSunken,
                      borderRadius: BorderRadius.circular(AppRadii.full),
                    ),
                    child: Text(
                      'ID: $studentId',
                      style: AppText.label(12,
                          w: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Done',
              onPressed: () => Navigator.pop(sheetContext),
            ),
          ],
        ),
      );
    },
  );
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({
    required this.profile,
    required this.onEdit,
    this.roleLabel,
  });

  final UserProfile profile;
  final String? roleLabel;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.scheme.surfaceContainerLow.withValues(alpha: 0.97)
            : Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(
          color: isDark
              ? const Color(0xFF334155).withValues(alpha: 0.90)
              : const Color(0xFFE2E8F0),
        ),
        boxShadow: isDark
            ? AppGlass.shadows
            : [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.xl),
        child: Stack(
          children: [
            // Ambient warm shimmer on top-right corner
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: isDark ? 0.20 : 0.12),
                      AppColors.primary.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.cardPadding),
              child: Column(
                children: [
                  Row(
                    children: [
                      _Avatar(profile: profile),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.title(
                                19,
                                w: FontWeight.w800,
                                ls: -0.3,
                              ),
                            ),
                            const SizedBox(height: 5),
                            if (roleLabel != null)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: StatusPill(
                                  label: roleLabel!,
                                  color: AppColors.primary,
                                  compact: true,
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.12),
                                  borderRadius:
                                      BorderRadius.circular(AppRadii.full),
                                  border: Border.all(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.25),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.school_rounded,
                                      size: 12,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        profile.studentId.isNotEmpty
                                            ? profile.studentId
                                            : 'Student Member',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppText.label(
                                          11.5,
                                          w: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.mail_outline_rounded,
                                  size: 13,
                                  color: AppColors.textFaint,
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    profile.email,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppText.body(
                                      12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      PressScale(
                        onTap: onEdit,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark
                                ? const Color(0xFF1E293B)
                                : const Color(0xFFF1F5F9),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Icon(
                            Icons.edit_rounded,
                            size: 18,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Digital campus pass shortcut
                  InkWell(
                    onTap: () =>
                        showDigitalPassSheet(context, profile, roleLabel),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              Icons.qr_code_2_rounded,
                              size: 16,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Digital Campus Pass',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.label(
                                12.5,
                                w: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF10B981),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Active',
                            style: AppText.label(
                              11.5,
                              w: FontWeight.w600,
                              color: const Color(0xFF10B981),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 16,
                            color: AppColors.textFaint,
                          ),
                        ],
                      ),
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
}

/// Profile photo with ring glow, initials fallback, and verified indicator.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final initial = profile.name.trim().isEmpty
        ? '?'
        : profile.name.trim().substring(0, 1).toUpperCase();
    final fallback = Container(
      width: 66,
      height: 66,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF59E0B),
            Color(0xFFD97706),
          ],
        ),
      ),
      child: Text(
        initial,
        style: AppText.title(
          25,
          w: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );

    final url = profile.photoUrl;
    final isDark = AppColors.isDark;

    return Semantics(
      label: 'Profile photo of ${profile.name}',
      image: true,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 70,
            height: 70,
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: isDark ? 0.6 : 0.45),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color:
                      AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipOval(
              child: (url == null || url.isEmpty)
                  ? fallback
                  : Image.network(
                      url,
                      width: 66,
                      height: 66,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => fallback,
                      loadingBuilder: (_, child, progress) =>
                          progress == null ? child : fallback,
                    ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
                border: Border.all(
                  color: isDark ? const Color(0xFF151D2A) : Colors.white,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 13,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet for editing name, phone and student ID.
class EditProfileSheet extends StatefulWidget {
  const EditProfileSheet({super.key, required this.profile});

  final UserProfile profile;

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

/// Returns an error message, or null when [name] is acceptable.
String? validateName(String name) {
  final v = name.trim();
  if (v.length < 2) return 'Enter your full name';
  if (v.length > 80) return 'That name is too long';
  return null;
}

/// Phone is optional; when given it needs 7 to 15 digits.
String? validatePhone(String phone) {
  final v = phone.trim();
  if (v.isEmpty) return null;
  if (!RegExp(r'^\+?[0-9 ()-]+$').hasMatch(v)) {
    return 'Use digits, spaces, + or -';
  }
  final digits = v.replaceAll(RegExp(r'\D'), '').length;
  if (digits < 7 || digits > 15) return 'Enter a valid phone number';
  return null;
}

/// Student ID is optional; when given it is 3 to 20 letters, digits or dashes.
String? validateStudentId(String id) {
  final v = id.trim();
  if (v.isEmpty) return null;
  if (!RegExp(r'^[A-Za-z0-9-]{3,20}$').hasMatch(v)) {
    return 'Use 3-20 letters, numbers or dashes';
  }
  return null;
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  late final _name = TextEditingController(text: widget.profile.name);
  late final _phone = TextEditingController(text: widget.profile.phone);
  late final _studentId =
      TextEditingController(text: widget.profile.studentId);
  String? _nameError;
  String? _phoneError;
  String? _idError;
  String? _saveError;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _studentId.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _nameError = validateName(_name.text);
      _phoneError = validatePhone(_phone.text);
      _idError = validateStudentId(_studentId.text);
      _saveError = null;
    });
    if (_nameError != null || _phoneError != null || _idError != null) {
      AppFeedback.error();
      return;
    }
    final state = AppScope.read(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _saving = true);
    try {
      await state.updateProfile(
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        studentId: _studentId.text.trim(),
      );
      AppFeedback.success();
      navigator.pop();
      messenger.showSnackBar(const SnackBar(content: Text('Profile saved')));
    } catch (_) {
      if (!mounted) return;
      AppFeedback.error();
      setState(() {
        _saving = false;
        _saveError = "Couldn't save your profile. Check your connection and "
            'try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenMargin,
        AppSpacing.sm,
        AppSpacing.screenMargin,
        AppSpacing.xl + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Icon(Icons.person_rounded,
                    color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Edit profile',
                        style: AppText.title(20, w: FontWeight.w800)),
                    Text(
                      'Update your name and university contact details',
                      style: AppText.body(12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_saveError != null) ...[
            Callout(
              tone: CalloutTone.danger,
              icon: Icons.error_outline_rounded,
              message: _saveError!,
            ),
            const SizedBox(height: 14),
          ],
          _FormFieldGroup(
            label: 'Full name',
            controller: _name,
            icon: Icons.person_outline_rounded,
            hint: 'Enter your full name',
            errorText: _nameError,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          _FormFieldGroup(
            label: 'Phone number',
            controller: _phone,
            icon: Icons.phone_outlined,
            hint: 'e.g. +94 77 123 4567',
            errorText: _phoneError,
            isOptional: true,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          _FormFieldGroup(
            label: 'Student ID',
            controller: _studentId,
            icon: Icons.badge_outlined,
            hint: 'e.g. IT21154820',
            errorText: _idError,
            isOptional: true,
            helperText:
                'Used for student identity at library check-in counters',
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: _saving ? 'Saving…' : 'Save changes',
            icon: Icons.check_rounded,
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
    );
  }
}

class _FormFieldGroup extends StatelessWidget {
  const _FormFieldGroup({
    required this.label,
    required this.controller,
    required this.icon,
    this.hint,
    this.errorText,
    this.helperText,
    this.isOptional = false,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final IconData icon;
  final String? hint;
  final String? errorText;
  final String? helperText;
  final bool isOptional;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: AppText.label(
                13,
                w: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            if (isOptional) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSunken,
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: Text(
                  'optional',
                  style: AppText.label(10.5,
                      color: AppColors.textSecondary, w: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 7),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            prefixIcon: Icon(icon, size: 20, color: AppColors.primary),
          ),
        ),
        if (helperText != null && errorText == null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              helperText!,
              style: AppText.body(11.5, color: AppColors.textFaint),
            ),
          ),
        ],
      ],
    );
  }
}

/// Sheet that fetches the account export and offers to copy it.
class ExportDataSheet extends StatefulWidget {
  const ExportDataSheet({super.key});

  @override
  State<ExportDataSheet> createState() => _ExportDataSheetState();
}

class _ExportDataSheetState extends State<ExportDataSheet> {
  Future<String>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= AppScope.read(context).exportAccountData();
  }

  Future<void> _copy(String json) async {
    await Clipboard.setData(ClipboardData(text: json));
    AppFeedback.success();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenMargin,
        AppSpacing.sm,
        AppSpacing.screenMargin,
        AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Your data', style: AppText.title(20, w: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            'Everything Lamplight holds about you, as text you can copy and '
            'keep.',
            style: AppText.body(13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.base),
          FutureBuilder<String>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snap.hasError) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Callout(
                      tone: CalloutTone.danger,
                      icon: Icons.error_outline_rounded,
                      message: "We couldn't prepare your data. Check your "
                          'connection and try again.',
                    ),
                    const SizedBox(height: 12),
                    PrimaryButton(
                      label: 'Try again',
                      tone: ButtonTone.secondary,
                      onPressed: () => setState(() {
                        _future = AppScope.read(context).exportAccountData();
                      }),
                    ),
                  ],
                );
              }
              final json = snap.data ?? '';
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    constraints: const BoxConstraints(maxHeight: 240),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSunken,
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        json,
                        style: AppText.body(12, color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.base),
                  PrimaryButton(
                    label: 'Copy to clipboard',
                    icon: Icons.copy_rounded,
                    onPressed: () => _copy(json),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Two-step account deletion: a warning, then typing [kDeleteConfirmWord].
/// Pops `true` only once the word matches and the user confirms.
class DeleteAccountDialog extends StatefulWidget {
  const DeleteAccountDialog({super.key});

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  final _controller = TextEditingController();
  bool _typing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _matches => _controller.text.trim() == kDeleteConfirmWord;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        _typing ? 'Type $kDeleteConfirmWord to confirm' : 'Delete your account?',
        style: AppText.title(19, w: FontWeight.w700),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _typing
                  ? 'This permanently erases your account, reservations, '
                      'bookings and loans history. It cannot be undone.'
                  : 'This permanently erases your account and the data held '
                      'about it. You may want to download your data first.',
              style: AppText.body(14, color: AppColors.textSecondary),
            ),
            if (_typing) ...[
              const SizedBox(height: 14),
              TextField(
                controller: _controller,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(labelText: kDeleteConfirmWord),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.isDark
                ? const Color(0xFFFBBF24)
                : AppColors.primary,
          ),
          child: const Text('Cancel'),
        ),
        if (!_typing)
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => setState(() => _typing = true),
            child: const Text('Continue'),
          )
        else
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: _matches ? () => Navigator.pop(context, true) : null,
            child: const Text('Delete account'),
          ),
      ],
    );
  }
}

/// A compact interactive stat strip under the identity card — the numbers a student
/// actually cares about with rich iconography and tap shortcuts.
class _MemberStats extends StatelessWidget {
  const _MemberStats();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Books held',
            value: state.activeReservations.length,
            icon: Icons.auto_stories_rounded,
            color: const Color(0xFFD97706),
            bgColor: const Color(0xFFFEF3C7),
            onTap: () => AppRoute.push(context, const LoansScreen()),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            label: 'Seats booked',
            value: state.bookings.length,
            icon: Icons.event_seat_rounded,
            color: const Color(0xFF0D9488),
            bgColor: const Color(0xFFCCFBF1),
            onTap: () => AppShell.switchTab(context, AppTab.bookings),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            label: 'In waitlist',
            value: state.waitlist.length,
            icon: Icons.hourglass_top_rounded,
            color: const Color(0xFF4F46E5),
            bgColor: const Color(0xFFE0E7FF),
            onTap: () => AppShell.switchTab(context, AppTab.bookings),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark;

    return PressScale(
      onTap: () {
        AppFeedback.tap();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.scheme.surfaceContainerLow.withValues(alpha: 0.97)
              : Colors.white,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
            color: isDark
                ? const Color(0xFF334155).withValues(alpha: 0.8)
                : const Color(0xFFE2E8F0),
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: color.withValues(alpha: 0.08),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isDark ? color.withValues(alpha: 0.2) : bgColor,
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  child: Icon(icon, size: 17, color: color),
                ),
                Icon(
                  Icons.arrow_outward_rounded,
                  size: 14,
                  color: AppColors.textFaint.withValues(alpha: 0.6),
                ),
              ],
            ),
            const SizedBox(height: 10),
            CountUp(
              value: value,
              style: AppText.title(
                22,
                w: FontWeight.w800,
                color: color,
                ls: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.label(
                11.5,
                w: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
