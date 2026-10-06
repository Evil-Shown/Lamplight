import 'package:flutter/material.dart';

import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';
import 'value_proposition_screen.dart';

/// container-8 Settings.
///
/// Notification channels as switches, then the app-level rows: language,
/// help, and version.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final prefs = state.preferences;

    return AppScaffold(
      title: 'Settings',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 10),
            child: SectionLabel('Notification methods'),
          ),
          StaggeredEntrance(
            child: SurfaceCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _ToggleRow(
                    label: 'Email Notifications',
                    value: prefs.emailEnabled,
                    onChanged: (v) => state.updatePreferences(
                      prefs.copyWith(emailEnabled: v),
                    ),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _ToggleRow(
                    label: 'SMS Notifications',
                    value: prefs.smsEnabled,
                    onChanged: (v) => state.updatePreferences(
                      prefs.copyWith(smsEnabled: v),
                    ),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _ToggleRow(
                    label: 'Push Notifications',
                    value: prefs.pushEnabled,
                    onChanged: (v) => state.updatePreferences(
                      prefs.copyWith(pushEnabled: v),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 10),
            child: SectionLabel('Other settings'),
          ),
          StaggeredEntrance(
            index: 1,
            child: SurfaceCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  SettingRow(
                    label: 'App Language',
                    value: 'English',
                    icon: Icons.language_rounded,
                    onTap: () {},
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  SettingRow(
                    label: 'Help & Support',
                    icon: Icons.help_outline_rounded,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Email library@university.edu'),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  SettingRow(
                    label: 'About App',
                    value: 'v1.4.2',
                    icon: Icons.info_outline_rounded,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ValuePropositionScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      title: Text(label, style: AppText.body(14.5)),
    );
  }
}
