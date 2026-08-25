import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../models/models.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  NotificationPreferences _prefs = const NotificationPreferences();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text(
            'Delivery channels',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SoftCard(
            elevated: true,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _ToggleTile(
                  title: 'Push notifications',
                  subtitle: 'Instant alerts on your device',
                  value: _prefs.pushEnabled,
                  onChanged: (v) => setState(() => _prefs = _prefs.copyWith(pushEnabled: v)),
                ),
                const Divider(height: 1),
                _ToggleTile(
                  title: 'Email',
                  subtitle: 'Reservation summaries and reminders',
                  value: _prefs.emailEnabled,
                  onChanged: (v) => setState(() => _prefs = _prefs.copyWith(emailEnabled: v)),
                ),
                const Divider(height: 1),
                _ToggleTile(
                  title: 'SMS',
                  subtitle: 'Text message alerts',
                  value: _prefs.smsEnabled,
                  onChanged: (v) => setState(() => _prefs = _prefs.copyWith(smsEnabled: v)),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Reminders',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SoftCard(
            elevated: true,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _ToggleTile(
                  title: 'Before reservation starts',
                  subtitle: '15 minutes before your booking',
                  value: _prefs.reminderBeforeStart,
                  onChanged: (v) =>
                      setState(() => _prefs = _prefs.copyWith(reminderBeforeStart: v)),
                ),
                const Divider(height: 1),
                _ToggleTile(
                  title: 'Before reservation expires',
                  subtitle: '30 minutes before pickup or booking ends',
                  value: _prefs.reminderBeforeExpiry,
                  onChanged: (v) =>
                      setState(() => _prefs = _prefs.copyWith(reminderBeforeExpiry: v)),
                ),
                const Divider(height: 1),
                _ToggleTile(
                  title: 'Waitlist updates',
                  subtitle: 'When you move up or a spot opens',
                  value: _prefs.waitlistUpdates,
                  onChanged: (v) =>
                      setState(() => _prefs = _prefs.copyWith(waitlistUpdates: v)),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const AlertBanner(
            tone: AlertTone.info,
            icon: Icons.tune_rounded,
            message:
                'Mix channels however you like — push, email, and SMS work independently.',
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppColors.textSecondary),
      ),
      value: value,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
    );
  }
}
