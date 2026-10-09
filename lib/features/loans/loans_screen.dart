import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart'
    show AppNavInset, AppPolicy, AppTouchTarget;
import '../../core/feedback/app_feedback.dart';
import '../../core/navigation/app_route.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../models/models.dart';
import '../books/book_search_screen.dart';

/// "2 days overdue", "Due today", "Due tomorrow", "Due in 3 days".
String loanDueLabel(Loan loan, DateTime now) {
  if (loan.isReturned) return 'Returned';
  if (loan.isOverdueAt(now)) {
    final days = now.difference(loan.dueAt).inDays;
    if (days < 1) return 'Overdue today';
    return '$days ${days == 1 ? 'day' : 'days'} overdue';
  }
  final left = loan.dueAt.difference(now);
  final days = left.inDays;
  if (days < 1) return 'Due today';
  if (days == 1) return 'Due tomorrow';
  return 'Due in $days days';
}

/// "LKR 150.00".
String formatFine(num amount, String currency) =>
    '$currency ${amount.toStringAsFixed(2)}';

/// Loans grouped for display. Pure, so it is easy to test.
class LoanSections {
  LoanSections(Iterable<Loan> loans, DateTime now)
      : overdue = [],
        dueSoon = [],
        active = [],
        returned = [] {
    const soon = Duration(days: AppPolicy.loanReminderLeadDays);
    final sorted = loans.toList()..sort((a, b) => a.dueAt.compareTo(b.dueAt));
    for (final l in sorted) {
      if (l.isReturned) {
        returned.add(l);
      } else if (l.isOverdueAt(now)) {
        overdue.add(l);
      } else if (l.dueAt.difference(now) <= soon) {
        dueSoon.add(l);
      } else {
        active.add(l);
      }
    }
    returned.sort(
        (a, b) => (b.returnedAt ?? b.dueAt).compareTo(a.returnedAt ?? a.dueAt));
  }

  final List<Loan> overdue;
  final List<Loan> dueSoon;
  final List<Loan> active;
  final List<Loan> returned;

  int get outCount => overdue.length + dueSoon.length + active.length;
}

/// The student's loans: summary, then Overdue / Due soon / Active /
/// Returned, each with a Renew action where it makes sense.
class LoansScreen extends StatelessWidget {
  const LoansScreen({super.key});

  @override
  Widget build(BuildContext context) => const _LoansView();
}

class _LoansView extends StatefulWidget {
  const _LoansView();

  @override
  State<_LoansView> createState() => _LoansViewState();
}

class _LoansViewState extends State<_LoansView> {
  final Set<String> _renewing = {};

  Future<void> _renew(Loan loan) async {
    if (_renewing.contains(loan.id)) return;
    final state = AppScope.read(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _renewing.add(loan.id));
    try {
      await state.renewLoan(loan.id);
      AppFeedback.success();
      messenger.showSnackBar(
        SnackBar(content: Text('Renewed "${loan.title}"')),
      );
    } catch (e) {
      AppFeedback.error();
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _renewing.remove(loan.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final now = DateTime.now();
    final sections = LoanSections(state.loans, now);
    final status = state.syncStatus;
    final failed =
        status == SyncStatus.permissionDenied || status == SyncStatus.error;
    final loading = !state.isHydrated && state.loans.isEmpty;
    final fines = sections.overdue
        .followedBy(sections.dueSoon)
        .followedBy(sections.active)
        .fold<num>(0, (t, l) => t + l.fineAccrued);
    final currency =
        state.loans.isEmpty ? 'LKR' : state.loans.first.fineCurrency;

    Widget content;
    if (failed && state.loans.isEmpty) {
      content = ErrorState(
        message: state.lastError?.message ??
            'We could not load your loans just now.',
        onRetry: state.refresh,
      );
    } else if (loading) {
      content = const Column(
        children: [
          SkeletonCard(height: 110),
          SizedBox(height: AppSpacing.md),
          SkeletonCard(height: 110),
          SizedBox(height: AppSpacing.md),
          SkeletonCard(height: 110),
        ],
      );
    } else if (state.loans.isEmpty) {
      content = EmptyState(
        icon: Icons.menu_book_outlined,
        title: 'No loans yet',
        message: 'Books you borrow from the library will show up here, with '
            'due dates and renewals.',
        actionLabel: 'Browse books',
        onAction: () => AppRoute.push(
          context,
          const AppScaffold(title: 'Books', body: BookSearchScreen()),
        ),
      );
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SummaryCard(
            active: sections.outCount,
            overdue: sections.overdue.length,
            fines: formatFine(fines, currency),
          ),
          _Section(
            title: 'Overdue',
            icon: Icons.error_outline_rounded,
            loans: sections.overdue,
            now: now,
            renewing: _renewing,
            onRenew: _renew,
          ),
          _Section(
            title: 'Due soon',
            icon: Icons.schedule_rounded,
            loans: sections.dueSoon,
            now: now,
            renewing: _renewing,
            onRenew: _renew,
          ),
          _Section(
            title: 'Active',
            icon: Icons.auto_stories_outlined,
            loans: sections.active,
            now: now,
            renewing: _renewing,
            onRenew: _renew,
          ),
          _Section(
            title: 'Returned',
            icon: Icons.check_circle_outline_rounded,
            loans: sections.returned,
            now: now,
            renewing: _renewing,
            onRenew: _renew,
          ),
        ],
      );
    }

    return AppScaffold(
      title: 'My Loans',
      body: Column(
        children: [
          ConnectivityBanner(lastSyncedAt: state.lastSyncedAt),
          Expanded(
            child: RefreshIndicator(
              onRefresh: state.refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm,
                    AppSpacing.lg, AppNavInset.bottom),
                children: [content],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.active,
    required this.overdue,
    required this.fines,
  });

  final int active;
  final int overdue;
  final String fines;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '$active active loans, $overdue overdue, fines $fines',
      child: ExcludeSemantics(
        child: GlassSurface(
          radius: AppRadii.xl,
          padding: const EdgeInsets.all(AppSpacing.base),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            runSpacing: AppSpacing.md,
            spacing: AppSpacing.base,
            children: [
              _Stat(label: 'Active', value: '$active'),
              _Stat(
                label: 'Overdue',
                value: '$overdue',
                color: overdue > 0 ? AppColors.error : null,
              ),
              _Stat(label: 'Fines', value: fines),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label.toUpperCase(),
            style: AppText.overline(10.5, color: AppColors.textFaint)),
        const SizedBox(height: 2),
        Text(value,
            style: AppText.display(22, w: FontWeight.w800, color: color)),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.loans,
    required this.now,
    required this.renewing,
    required this.onRenew,
  });

  final String title;
  final IconData icon;
  final List<Loan> loans;
  final DateTime now;
  final Set<String> renewing;
  final ValueChanged<Loan> onRenew;

  @override
  Widget build(BuildContext context) {
    if (loans.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.xl),
        SectionHeader(title: '$title (${loans.length})'),
        const SizedBox(height: AppSpacing.md),
        for (final loan in loans) ...[
          _LoanCard(
            loan: loan,
            now: now,
            busy: renewing.contains(loan.id),
            onRenew: () => onRenew(loan),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _LoanCard extends StatelessWidget {
  const _LoanCard({
    required this.loan,
    required this.now,
    required this.busy,
    required this.onRenew,
  });

  final Loan loan;
  final DateTime now;
  final bool busy;
  final VoidCallback onRenew;

  @override
  Widget build(BuildContext context) {
    final overdue = loan.isOverdueAt(now);
    final returned = loan.isReturned;
    final soon = !overdue &&
        !returned &&
        loan.dueAt.difference(now) <=
            const Duration(days: AppPolicy.loanReminderLeadDays);
    final (color, icon) = returned
        ? (AppColors.neutral, Icons.check_circle_outline_rounded)
        : overdue
            ? (AppColors.error, Icons.error_outline_rounded)
            : soon
                ? (AppColors.warning, Icons.schedule_rounded)
                : (AppColors.success, Icons.check_rounded);
    final renewed = loan.renewals == 0
        ? 'Not renewed yet'
        : 'Renewed ${loan.renewals} ${loan.renewals == 1 ? 'time' : 'times'}';

    return FrostedCard(
      tint: color.withValues(alpha: 0.12),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            image: true,
            label: 'Cover of ${loan.title}',
            excludeSemantics: true,
            child: BookCover(
              title: loan.title,
              color: loan.coverColor,
              width: 52,
              height: 74,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loan.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.title(15, w: FontWeight.w700),
                ),
                Text(
                  loan.author,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body(12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.sm),
                StatusPill(
                  label: loanDueLabel(loan, now),
                  color: color,
                  icon: icon,
                  compact: true,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  renewed,
                  style: AppText.body(12, color: AppColors.textSecondary),
                ),
                if (loan.fineAccrued > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'Fine: ${formatFine(loan.fineAccrued, loan.fineCurrency)}',
                      style: AppText.label(12.5,
                          w: FontWeight.w700, color: AppColors.error),
                    ),
                  ),
                if (!returned) ...[
                  const SizedBox(height: AppSpacing.md),
                  _RenewButton(
                    busy: busy,
                    onPressed: onRenew,
                    title: loan.title,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RenewButton extends StatelessWidget {
  const _RenewButton({
    required this.busy,
    required this.onPressed,
    required this.title,
  });

  final bool busy;
  final VoidCallback onPressed;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: !busy,
      label: busy ? 'Renewing $title' : 'Renew $title',
      excludeSemantics: true,
      onTap: busy ? null : onPressed,
      child: OutlinedButton(
        onPressed: busy
            ? null
            : () {
                AppFeedback.tap();
                onPressed();
              },
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, AppTouchTarget.minSize),
          shape: const StadiumBorder(),
        ),
        child: busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Renew'),
      ),
    );
  }
}
