import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ledger_widgets.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../models/models.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  NotificationPreferences _prefs = const NotificationPreferences();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Notifications', style: AppText.serif(22))),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          const Eyebrow('DELIVERY CHANNELS'),
          const SizedBox(height: AppSpacing.sm),
          SoftCard(
            elevated: true,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _ToggleTile(
                  icon: Icons.notifications_active_rounded,
                  title: 'Push notifications',
                  subtitle: 'Instant alerts on your device',
                  value: _prefs.pushEnabled,
                  onChanged: (v) =>
                      setState(() => _prefs = _prefs.copyWith(pushEnabled: v)),
                ),
                const Divider(height: 1, indent: 66),
                _ToggleTile(
                  icon: Icons.mail_outline_rounded,
                  title: 'Email',
                  subtitle: 'Reservation summaries and reminders',
                  value: _prefs.emailEnabled,
                  onChanged: (v) =>
                      setState(() => _prefs = _prefs.copyWith(emailEnabled: v)),
                ),
                const Divider(height: 1, indent: 66),
                _ToggleTile(
                  icon: Icons.sms_outlined,
                  title: 'SMS',
                  subtitle: 'Text message alerts',
                  value: _prefs.smsEnabled,
                  onChanged: (v) =>
                      setState(() => _prefs = _prefs.copyWith(smsEnabled: v)),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Eyebrow('REMINDERS'),
          const SizedBox(height: AppSpacing.sm),
          SoftCard(
            elevated: true,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _ToggleTile(
                  icon: Icons.alarm_rounded,
                  title: 'Before reservation starts',
                  subtitle: '15 minutes before your booking',
                  value: _prefs.reminderBeforeStart,
                  onChanged: (v) => setState(
                      () => _prefs = _prefs.copyWith(reminderBeforeStart: v)),
                ),
                const Divider(height: 1, indent: 66),
                _ToggleTile(
                  icon: Icons.update_rounded,
                  title: 'Before reservation expires',
                  subtitle: '30 minutes before pickup or booking ends',
                  value: _prefs.reminderBeforeExpiry,
                  onChanged: (v) => setState(
                      () => _prefs = _prefs.copyWith(reminderBeforeExpiry: v)),
                ),
                const Divider(height: 1, indent: 66),
                _ToggleTile(
                  icon: Icons.hourglass_top_rounded,
                  title: 'Waitlist updates',
                  subtitle: 'When you move up or a spot opens',
                  value: _prefs.waitlistUpdates,
                  onChanged: (v) => setState(
                      () => _prefs = _prefs.copyWith(waitlistUpdates: v)),
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
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: IconBadge(icon: icon, size: 40),
      title: Text(title, style: AppText.sans(14.5, w: FontWeight.w700)),
      subtitle: Text(
        subtitle,
        style: AppText.sans(12.5, color: AppColors.textSecondary),
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
