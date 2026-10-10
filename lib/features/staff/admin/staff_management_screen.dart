import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart' show AppNavInset;
import '../../../core/feedback/app_feedback.dart';
import '../../../core/state/app_state.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../services/functions_service.dart';

/// One row of the staff allowlist as returned by `listStaff`.
class StaffMember {
  const StaffMember({
    required this.email,
    required this.hasAccount,
    this.displayName,
  });

  final String email;
  final bool hasAccount;
  final String? displayName;

  factory StaffMember.fromMap(Map<String, dynamic> m) {
    final name = (m['displayName'] as String?)?.trim();
    return StaffMember(
      email: ((m['email'] as String?) ?? '').trim().toLowerCase(),
      hasAccount: m['hasAccount'] == true,
      displayName: (name == null || name.isEmpty) ? null : name,
    );
  }
}

/// Returns an error message, or null when [email] is acceptable.
String? validateStaffEmail(String email) {
  final v = email.trim();
  if (v.isEmpty) return 'Enter an email address';
  if (v.length > 254 || !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v)) {
    return 'Enter a valid email address';
  }
  return null;
}

/// Admin-only management of the staff allowlist. Guarded by
/// [AppState.isAdmin] so it is safe even when pushed by mistake.
class StaffManagementScreen extends StatelessWidget {
  const StaffManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (!AppScope.of(context).isAdmin) {
      return const AppScaffold(
        title: 'Staff management',
        body: EmptyState(
          icon: Icons.lock_outline_rounded,
          title: 'Not available',
          message: 'Only administrators can manage staff access.',
        ),
      );
    }
    return const _StaffManagementBody();
  }
}

class _StaffManagementBody extends StatefulWidget {
  const _StaffManagementBody();

  @override
  State<_StaffManagementBody> createState() => _StaffManagementBodyState();
}

class _StaffManagementBodyState extends State<_StaffManagementBody> {
  final _emailController = TextEditingController();
  List<StaffMember>? _staff;
  String? _loadError;
  String? _fieldError;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String _message(Object e) {
    if (e is CallableFailure) {
      if (e.code == 'not-found' || e.code == 'unimplemented') {
        return 'This feature needs the latest server update.';
      }
      return e.message;
    }
    return 'Something went wrong. Please try again.';
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final rows = await FunctionsService.instance.listStaff();
      final list = [for (final r in rows) StaffMember.fromMap(r)]
        ..removeWhere((m) => m.email.isEmpty)
        ..sort((a, b) => a.email.compareTo(b.email));
      if (!mounted) return;
      setState(() {
        _staff = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = _message(e);
        _loading = false;
      });
    }
  }

  /// Writes the full list, then reloads. Returns true on success.
  Future<bool> _save(List<String> emails, String doneMessage) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      await FunctionsService.instance.setStaffAllowlist(emails);
      if (!mounted) return true;
      AppFeedback.success();
      messenger.showSnackBar(SnackBar(content: Text(doneMessage)));
      setState(() => _saving = false);
      await _load();
      return true;
    } catch (e) {
      if (!mounted) return false;
      AppFeedback.error();
      setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text(_message(e))));
      return false;
    }
  }

  Future<void> _add() async {
    final error = validateStaffEmail(_emailController.text);
    if (error != null) {
      setState(() => _fieldError = error);
      return;
    }
    final email = _emailController.text.trim().toLowerCase();
    final current = [for (final m in _staff ?? <StaffMember>[]) m.email];
    if (current.contains(email)) {
      setState(() => _fieldError = 'That email is already on the list');
      return;
    }
    setState(() => _fieldError = null);
    FocusScope.of(context).unfocus();
    final ok = await _save([...current, email], 'Added $email');
    if (ok && mounted) _emailController.clear();
  }

  Future<void> _remove(StaffMember member) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Remove staff access?',
      body: '${member.email} will lose staff access the next time they '
          'sign in.',
      confirmLabel: 'Remove',
    );
    if (!confirmed || !mounted) return;
    final next = [
      for (final m in _staff ?? <StaffMember>[])
        if (m.email != member.email) m.email,
    ];
    await _save(next, 'Removed ${member.email}');
  }

  @override
  Widget build(BuildContext context) {
    final staff = _staff;
    return AppScaffold(
      title: 'Staff management',
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(AppSpacing.base, AppSpacing.sm,
              AppSpacing.base, AppNavInset.bottom),
          children: [
            Text(
              'A person gets staff access the next time they sign in with a '
              'verified email.',
              style: AppText.body(13.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.base),
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SectionLabel('Add staff email'),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    enabled: !_saving,
                    onSubmitted: (_) => _add(),
                    onChanged: (_) {
                      if (_fieldError != null) {
                        setState(() => _fieldError = null);
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'name@example.com',
                      errorText: _fieldError,
                      prefixIcon:
                          const Icon(Icons.alternate_email_rounded, size: 20),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  PrimaryButton(
                    label: _saving ? 'Saving…' : 'Add staff email',
                    icon: Icons.person_add_alt_1_rounded,
                    onPressed:
                        _saving || _loading || _loadError != null ? null : _add,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 10),
              child: SectionLabel('Staff'),
            ),
            if (_loading && staff == null)
              const Column(
                children: [
                  SkeletonCard(height: 72),
                  SizedBox(height: AppSpacing.sm),
                  SkeletonCard(height: 72),
                ],
              )
            else if (_loadError != null)
              ErrorState(message: _loadError!, onRetry: _load)
            else if (staff == null || staff.isEmpty)
              const EmptyState(
                icon: Icons.badge_outlined,
                title: 'No staff yet',
                message: 'Add an email above to give someone staff access.',
              )
            else
              for (final member in staff) ...[
                _StaffRow(
                  member: member,
                  onRemove: _saving ? null : () => _remove(member),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
          ],
        ),
      ),
    );
  }
}

class _StaffRow extends StatelessWidget {
  const _StaffRow({required this.member, required this.onRemove});

  final StaffMember member;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final color = member.hasAccount ? AppColors.success : AppColors.warning;
    return SurfaceCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (member.displayName != null)
                  Text(
                    member.displayName!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.title(15, w: FontWeight.w700),
                  ),
                Text(
                  member.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: member.displayName != null
                      ? AppText.body(13, color: AppColors.textSecondary)
                      : AppText.title(15, w: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.sm),
                StatusPill(
                  label: member.hasAccount ? 'Signed up' : 'Not signed up yet',
                  color: color,
                  compact: true,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remove ${member.email}',
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            onPressed: onRemove,
            icon: Icon(Icons.person_remove_outlined, color: AppColors.error),
          ),
        ],
      ),
    );
  }
}
