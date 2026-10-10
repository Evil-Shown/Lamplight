import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/feedback/app_feedback.dart';
import '../../core/navigation/app_route.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../models/models.dart';
import '../help/help_screen.dart';
import '../loans/loans_screen.dart';
import '../notifications/notifications_screen.dart';
import '../staff/admin/staff_management_screen.dart';
import '../settings/settings_screen.dart';

/// The word the user must type to confirm deleting their account.
const String kDeleteConfirmWord = 'DELETE';

/// The Profile tab.
///
/// Identity card, loans, the privacy switch, data export and deletion,
/// shortcuts to notifications, settings and help, plus sign-out.
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
    final notice = state.roleNotice;
    final staff = state.isStaff;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenMargin,
            AppSpacing.xl,
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
                    foregroundColor: AppColors.isDark
                        ? const Color(0xFFFBBF24)
                        : AppColors.primary,
                  ),
                  child: const Text('Dismiss'),
                ),
              ),
            ],
            StaggeredEntrance(
              child: Text(staff ? 'Account' : 'Profile',
                  style: AppText.title(30, w: FontWeight.w800, ls: -0.8)),
            ),
            const SizedBox(height: 18),
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
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 10),
                child: SectionLabel('Library'),
              ),
              StaggeredEntrance(
                index: 2,
                child: SurfaceCard(
                  padding: EdgeInsets.zero,
                  child: SettingRow(
                    label: 'My loans',
                    icon: Icons.menu_book_outlined,
                    value: overdue > 0 ? '$overdue overdue' : null,
                    valueColor: overdue > 0 ? AppColors.error : null,
                    onTap: () => AppRoute.push(context, const LoansScreen()),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sectionGap),
            ],
            if (state.isAdmin) ...[
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 10),
                child: SectionLabel('Administration'),
              ),
              StaggeredEntrance(
                index: 2,
                child: SurfaceCard(
                  padding: EdgeInsets.zero,
                  child: SettingRow(
                    label: 'Staff management',
                    icon: Icons.admin_panel_settings_outlined,
                    onTap: () => AppRoute.push(
                        context, const StaffManagementScreen()),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sectionGap),
            ],
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 10),
              child: SectionLabel('Privacy'),
            ),
            StaggeredEntrance(
              index: 3,
              child: SurfaceCard(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!staff) ...[
                      SettingRow(
                        label: 'Staff-only visibility',
                        icon: Icons.visibility_off_outlined,
                        switchValue: profile.reservationsVisibleToStaffOnly,
                        onSwitchChanged: (v) =>
                            _setVisibility(context, state, v),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(66, 0, 16, 14),
                        child: Text(
                          'Only library staff can see your active reservations.',
                          style: AppText.body(
                            12.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const Divider(height: 1, indent: 66, endIndent: 16),
                    ],
                    SettingRow(
                      label: 'Download my data',
                      icon: Icons.download_rounded,
                      onTap: () => showGlassSheet<void>(
                        context,
                        builder: (_) => const ExportDataSheet(),
                      ),
                    ),
                    if (!staff) ...[
                      const Divider(height: 1, indent: 66, endIndent: 16),
                      SettingRow(
                        label: 'Delete my account',
                        icon: Icons.delete_outline_rounded,
                        valueColor: AppColors.error,
                        onTap: () => _deleteAccount(context, state),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 10),
              child: SectionLabel('Quick links'),
            ),
            StaggeredEntrance(
              index: 4,
              child: SurfaceCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    SettingRow(
                      label: 'Notifications',
                      icon: Icons.notifications_none_rounded,
                      onTap: () => AppRoute.push(
                        context,
                        const NotificationsScreen(),
                      ),
                    ),
                    const Divider(height: 1, indent: 66, endIndent: 16),
                    SettingRow(
                      label: 'Settings',
                      icon: Icons.settings_outlined,
                      onTap: () => AppRoute.push(
                        context,
                        const SettingsScreen(),
                      ),
                    ),
                    const Divider(height: 1, indent: 66, endIndent: 16),
                    SettingRow(
                      label: 'Help & support',
                      icon: Icons.help_outline_rounded,
                      onTap: () => AppRoute.push(context, const HelpScreen()),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            StaggeredEntrance(
              index: 5,
              child: PrimaryButton(
                label: 'Sign out',
                icon: Icons.logout_rounded,
                tone: ButtonTone.danger,
                onPressed: () async {
                  // M01: destructive actions always confirm with the
                  // consequence spelled out.
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

class _IdentityCard extends StatelessWidget {
  const _IdentityCard(
      {required this.profile, required this.onEdit, this.roleLabel});

  final UserProfile profile;
  final String? roleLabel;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      radius: AppRadii.xl,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      child: Row(
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
                    18,
                    w: FontWeight.w700,
                  ),
                ),
                if (roleLabel != null) ...[
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: StatusPill(
                      label: roleLabel!,
                      color: AppColors.primary,
                      compact: true,
                    ),
                  ),
                ],
                if (profile.studentId.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    profile.studentId,
                    style: AppText.body(
                      12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 3),
                Text(
                  profile.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body(
                    12,
                    color: AppColors.textFaint,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Edit profile',
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            onPressed: onEdit,
            icon: Icon(Icons.edit_outlined, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// Profile photo with an initials fallback while loading or on failure.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final initial = profile.name.trim().isEmpty
        ? '?'
        : profile.name.trim().substring(0, 1).toUpperCase();
    final fallback = Text(
      initial,
      style: AppText.title(
        22,
        w: FontWeight.w800,
        color: AppColors.textInverse,
      ),
    );
    final url = profile.photoUrl;
    return Semantics(
      label: 'Profile photo of ${profile.name}',
      image: true,
      child: Container(
        width: 64,
        height: 64,
        alignment: Alignment.center,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppGradients.brand,
          boxShadow: AppShadows.ambient,
          border: Border.all(color: AppGlass.rim, width: 1.5),
        ),
        child: (url == null || url.isEmpty)
            ? fallback
            : Image.network(
                url,
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => fallback,
                loadingBuilder: (_, child, progress) =>
                    progress == null ? child : fallback,
              ),
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
          Text('Edit profile', style: AppText.title(20, w: FontWeight.w700)),
          const SizedBox(height: AppSpacing.base),
          if (_saveError != null) ...[
            Callout(
              tone: CalloutTone.danger,
              icon: Icons.error_outline_rounded,
              message: _saveError!,
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Full name',
              errorText: _nameError,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Phone (optional)',
              errorText: _phoneError,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _studentId,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
            decoration: InputDecoration(
              labelText: 'Student ID (optional)',
              errorText: _idError,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: _saving ? 'Saving…' : 'Save changes',
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
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
                  style: AppText.title(
                    22,
                    w: FontWeight.w800,
                    color: AppColors.primary,
                    ls: -0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text('Books held',
                    style: AppText.label(12, w: FontWeight.w600, color: AppColors.textSecondary)),
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
                  style: AppText.title(
                    22,
                    w: FontWeight.w800,
                    color: AppColors.accent,
                    ls: -0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text('Seats booked',
                    style: AppText.label(12, w: FontWeight.w600, color: AppColors.textSecondary)),
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
                  style: AppText.title(
                    22,
                    w: FontWeight.w800,
                    color: AppColors.cyan,
                    ls: -0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text('Waiting',
                    style: AppText.label(12, w: FontWeight.w600, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
