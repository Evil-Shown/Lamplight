import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_constants.dart' show AppPolicy;
import '../../core/feedback/app_feedback.dart';
import '../../core/navigation/app_route.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';
import 'legal_screens.dart';

/// Where members reach the library. Placeholder until the real address is
/// confirmed by the library.
const String kLibraryContactEmail = 'library@university.edu';

/// Shown on the Help screen; keep in step with pubspec.yaml.
const String kAppVersion = '1.0.0';

/// One question and answer in the help list.
class FaqEntry {
  const FaqEntry(this.question, this.answer);

  final String question;
  final String answer;
}

/// The help content. Numbers come from [AppPolicy] so the answers cannot
/// drift from the rules the app uses.
List<FaqEntry> buildFaq() => [
      const FaqEntry(
        'How do I book a seat?',
        'Open the Seats tab, pick a floor and a free seat, choose a time '
            'and confirm. Your booking appears under Bookings with a QR code.',
      ),
      const FaqEntry(
        'How long do I have to check in?',
        'You have ${AppPolicy.checkInGraceMinutes} minutes after your '
            'session starts to scan in. After that the seat is released so '
            'others can use it.',
      ),
      const FaqEntry(
        'What is the pickup deadline for a reserved book?',
        'Each reservation shows its pickup-by time and the pickup location. '
            'If you miss it the reservation expires and the book goes back '
            'to the shelf or the next person. You get a reminder '
            '${AppPolicy.pickupReminderLeadHours} hours before.',
      ),
      const FaqEntry(
        'How does the waitlist work?',
        'When every copy is out you can join the waitlist. When a copy is '
            'free you are offered it, and the offer has a deadline. Accept '
            'it in time or the offer moves to the next person.',
      ),
      const FaqEntry(
        'What if I miss a waitlist offer?',
        'The offer expires and the next member is offered the copy. You can '
            'join the waitlist again, but you go to the back of the queue.',
      ),
      const FaqEntry(
        'Can I renew a loan?',
        'Open My loans in Profile and choose Renew. The library decides how '
            'many renewals are allowed and may refuse one if someone is '
            'waiting for the book. You get a reminder '
            '${AppPolicy.loanReminderLeadDays} days before it is due.',
      ),
      const FaqEntry(
        'How are fines calculated?',
        'Fines build up on overdue loans and are shown on the loan itself. '
            'The library sets the rate. Return or renew on time to avoid '
            'them, and ask at the desk if a fine looks wrong.',
      ),
      const FaqEntry(
        'My QR code will not scan.',
        'Raise your screen brightness, hold the phone steady about 20 cm '
            'from the scanner and clean the screen. If it still fails, ask '
            'the desk to look up your booking by name.',
      ),
      const FaqEntry(
        'Can I use the app offline?',
        'You can see data that was already saved on your phone, and a '
            'banner tells you when you are offline. Booking, reserving and '
            'renewing need a connection, so they will not work until you '
            'are back online.',
      ),
      const FaqEntry(
        'I am not getting notifications.',
        'Check Settings: reminders and the push channel must be on. Also '
            'check that your phone allows notifications for Library+. A '
            'session reminder arrives ${AppPolicy.seatReminderLeadMinutes} '
            'minutes before it starts.',
      ),
      const FaqEntry(
        'Who can see my reservations?',
        'By default only library staff can see your active reservations. '
            'You can change this with the Staff-only visibility switch in '
            'the Profile tab.',
      ),
      const FaqEntry(
        'How do I download or delete my data?',
        'In the Profile tab choose Download my data to copy a full export, '
            'or Delete my account to erase the account and the data held '
            'about it. Deleting cannot be undone.',
      ),
      const FaqEntry(
        'I signed in as staff but only see student features.',
        'Staff access is granted by the library, not chosen on the sign-in '
            'screen. If your account should have it, ask the library to '
            'add your email to the staff list, then sign in again.',
      ),
    ];

/// Returns the entries whose question or answer contains every word typed.
List<FaqEntry> filterFaq(List<FaqEntry> all, String query) {
  final words = query
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .toList();
  if (words.isEmpty) return all;
  return [
    for (final e in all)
      if (words.every((w) =>
          e.question.toLowerCase().contains(w) ||
          e.answer.toLowerCase().contains(w)))
        e,
  ];
}

/// Help & Support: searchable FAQ, contact details, version and legal links.
class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final _faq = buildFaq();
  String _query = '';

  Future<void> _copyEmail() async {
    await Clipboard.setData(const ClipboardData(text: kLibraryContactEmail));
    AppFeedback.success();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Email address copied')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final results = filterFaq(_faq, _query);
    return AppScaffold(
      title: 'Help & support',
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenMargin,
          AppSpacing.sm,
          AppSpacing.screenMargin,
          AppSpacing.xxl,
        ),
        children: [
          TextField(
            onChanged: (v) => setState(() => _query = v),
            style: AppText.body(15),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search help',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: AppColors.surfaceMuted,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadii.lg),
                borderSide: BorderSide(color: AppColors.border),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 10),
            child: SectionLabel('Frequently asked'),
          ),
          if (results.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Text(
                'No answers match "$_query". Try fewer words, or contact the '
                'library below.',
                style: AppText.body(14, color: AppColors.textSecondary),
              ),
            )
          else
            SurfaceCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var i = 0; i < results.length; i++) ...[
                    if (i > 0) const Divider(height: 1, indent: 16),
                    Theme(
                      data: Theme.of(context)
                          .copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        title: Text(
                          results[i].question,
                          style: AppText.title(14.5, w: FontWeight.w600),
                        ),
                        childrenPadding:
                            const EdgeInsets.fromLTRB(16, 0, 16, 14),
                        expandedAlignment: Alignment.centerLeft,
                        children: [
                          Text(
                            results[i].answer,
                            style: AppText.body(
                              13.5,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.sectionGap),
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 10),
            child: SectionLabel('Contact the library'),
          ),
          SurfaceCard(
            padding: EdgeInsets.zero,
            child: SettingRow(
              label: kLibraryContactEmail,
              value: 'Copy',
              icon: Icons.mail_outline_rounded,
              showChevron: false,
              onTap: _copyEmail,
            ),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 10),
            child: SectionLabel('About'),
          ),
          SurfaceCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                const SettingRow(
                  label: 'App version',
                  value: kAppVersion,
                  icon: Icons.info_outline_rounded,
                  showChevron: false,
                ),
                const Divider(height: 1, indent: 66, endIndent: 16),
                SettingRow(
                  label: 'Terms of use',
                  icon: Icons.description_outlined,
                  onTap: () => AppRoute.push(context, const TermsScreen()),
                ),
                const Divider(height: 1, indent: 66, endIndent: 16),
                SettingRow(
                  label: 'Privacy',
                  icon: Icons.privacy_tip_outlined,
                  onTap: () => AppRoute.push(context, const PrivacyScreen()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
