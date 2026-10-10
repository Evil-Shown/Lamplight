import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';

/// Plain in-app Terms of Use. Placeholder copy: the university must review
/// and replace it before launch.
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) => const _LegalPage(
        title: 'Terms of use',
        sections: [
          _LegalSection(
            'Using Lamplight',
            'Lamplight lets members of the university reserve books, book '
                'study seats and see their loans. You agree to use it for '
                'your own account and to follow the library rules shown in '
                'the app.',
          ),
          _LegalSection(
            'Reservations and seats',
            'Reservations and seat bookings can expire or be released if '
                'you do not collect or check in on time. The library may '
                'cancel a booking when needed to run the service fairly.',
          ),
          _LegalSection(
            'Your account',
            'Keep your sign-in details private. Tell the library if you '
                'think someone else is using your account.',
          ),
          _LegalSection(
            'Changes',
            'These terms may change. Continued use after a change means you '
                'accept the new version.',
          ),
        ],
      );
}

/// Plain in-app Privacy notice. Placeholder copy: the university must review
/// and replace it before launch.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) => const _LegalPage(
        title: 'Privacy',
        sections: [
          _LegalSection(
            'What we keep',
            'Your name, email, optional phone number and student ID, plus '
                'your reservations, seat bookings, waitlist entries, loans '
                'and notifications.',
          ),
          _LegalSection(
            'Who can see it',
            'Library staff can see what they need to run the service. '
                'You can limit who sees your active reservations from the '
                'Profile tab.',
          ),
          _LegalSection(
            'Your choices',
            'From the Profile tab you can edit your details, download a '
                'copy of your data, or delete your account and the data '
                'held about it.',
          ),
          _LegalSection(
            'Reminders',
            'Reminders are scheduled on your device and can be switched off '
                'in Settings.',
          ),
        ],
      );
}

class _LegalSection {
  const _LegalSection(this.heading, this.body);

  final String heading;
  final String body;
}

class _LegalPage extends StatelessWidget {
  const _LegalPage({required this.title, required this.sections});

  final String title;
  final List<_LegalSection> sections;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: title,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenMargin,
          AppSpacing.sm,
          AppSpacing.screenMargin,
          AppSpacing.xxl,
        ),
        children: [
          const Callout(
            tone: CalloutTone.warning,
            icon: Icons.info_outline_rounded,
            message: 'Placeholder text. The university must review and '
                'replace this before launch.',
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          for (final s in sections) ...[
            Semantics(
              header: true,
              child: Text(s.heading, style: AppText.title(16)),
            ),
            const SizedBox(height: 6),
            Text(
              s.body,
              style: AppText.body(14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ],
      ),
    );
  }
}
