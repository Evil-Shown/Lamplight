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
            child: SectionLabel('Appearance'),
          ),
          StaggeredEntrance(
            index: 1,
            child: SurfaceCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const IconBadge(icon: Icons.dark_mode_outlined, size: 40),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Theme',
                            style: AppText.title(14.5, w: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(
                          'Light, dark, or follow the system',
                          style: AppText.body(
                              12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  _ThemePicker(mode: state.themeMode),
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
            index: 2,
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
      onChanged: (v) {
        Haptics.selection();
        onChanged(v);
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      title: Text(label, style: AppText.body(14.5)),
    );
  }
}

/// Compact Light / Dark / System chooser for the app theme.
class _ThemePicker extends StatelessWidget {
  const _ThemePicker({required this.mode});

  final ThemeMode mode;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surfaceSunken,
        borderRadius: BorderRadius.circular(AppRadii.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final entry in <(ThemeMode, IconData, String)>[
            (ThemeMode.light, Icons.light_mode_rounded, 'Light'),
            (ThemeMode.dark, Icons.dark_mode_rounded, 'Dark'),
          ])
            _ThemePick(
              icon: entry.$2,
              tooltip: entry.$3,
              selected: mode == entry.$1,
              onTap: () {
                Haptics.selection();
                state.setThemeMode(entry.$1);
              },
            ),
        ],
      ),
    );
  }
}

class _ThemePick extends StatelessWidget {
  const _ThemePick({
    required this.icon,
    required this.tooltip,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: PressScale(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          width: 36,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadii.full),
            boxShadow: selected ? AppShadows.glow(AppColors.primary) : null,
          ),
          child: Icon(
            icon,
            size: 16,
            color: selected ? AppColors.textInverse : AppColors.textFaint,
          ),
        ),
      ),
    );
  }
}
