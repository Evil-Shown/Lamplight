import 'package:flutter/material.dart';

import '../../core/feedback/app_feedback.dart';
import '../../core/navigation/app_route.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';
import '../help/help_screen.dart';
import 'value_proposition_screen.dart';

/// container-8 Settings.
///
/// Notification channels and reminders as switches, appearance, sound,
/// accessibility, then help and version.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final prefs = state.preferences;

    return AppScaffold(
      title: 'Settings',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenMargin,
          AppSpacing.sm,
          AppSpacing.screenMargin,
          AppSpacing.xxl,
        ),
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
                  SettingRow(
                    label: 'Email Notifications',
                    switchValue: prefs.emailEnabled,
                    onSwitchChanged: (v) => state.updatePreferences(
                      prefs.copyWith(emailEnabled: v),
                    ),
                  ),
                  const _RowDivider(),
                  SettingRow(
                    label: 'SMS Notifications',
                    switchValue: prefs.smsEnabled,
                    onSwitchChanged: (v) => state.updatePreferences(
                      prefs.copyWith(smsEnabled: v),
                    ),
                  ),
                  const _RowDivider(),
                  SettingRow(
                    label: 'Push Notifications',
                    switchValue: prefs.pushEnabled,
                    onSwitchChanged: (v) => state.updatePreferences(
                      prefs.copyWith(pushEnabled: v),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 10),
            child: SectionLabel('Reminders'),
          ),
          StaggeredEntrance(
            index: 1,
            child: SurfaceCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  SettingRow(
                    label: 'Reminders on this phone',
                    icon: Icons.notifications_active_outlined,
                    switchValue: prefs.remindersEnabled,
                    onSwitchChanged: (v) => state.updatePreferences(
                      prefs.copyWith(remindersEnabled: v),
                    ),
                  ),
                  const _RowDivider(),
                  SettingRow(
                    label: 'Before my session starts',
                    switchValue: prefs.reminderBeforeStart,
                    onSwitchChanged: prefs.remindersEnabled
                        ? (v) => state.updatePreferences(
                              prefs.copyWith(reminderBeforeStart: v),
                            )
                        : null,
                  ),
                  const _RowDivider(),
                  SettingRow(
                    label: 'Before pickup expires',
                    switchValue: prefs.reminderBeforeExpiry,
                    onSwitchChanged: prefs.remindersEnabled
                        ? (v) => state.updatePreferences(
                              prefs.copyWith(reminderBeforeExpiry: v),
                            )
                        : null,
                  ),
                  const _RowDivider(),
                  SettingRow(
                    label: 'Before a loan is due',
                    switchValue: prefs.loanReminders,
                    onSwitchChanged: prefs.remindersEnabled
                        ? (v) => state.updatePreferences(
                              prefs.copyWith(loanReminders: v),
                            )
                        : null,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 10),
            child: SectionLabel('Appearance'),
          ),
          StaggeredEntrance(
            index: 2,
            child: SurfaceCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const IconBadge(icon: Icons.dark_mode_outlined, size: 40),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Theme',
                                style:
                                    AppText.title(14.5, w: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(
                              'System follows your phone',
                              style: AppText.body(12,
                                  color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _ThemePicker(mode: state.themeMode),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 10),
            child: SectionLabel('Sound & haptics'),
          ),
          StaggeredEntrance(
            index: 3,
            child: SurfaceCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  SettingRow(
                    label: 'Interface sounds',
                    icon: Icons.volume_up_rounded,
                    switchValue: state.soundsEnabled,
                    onSwitchChanged: state.setSoundsEnabled,
                  ),
                  const _RowDivider(),
                  SettingRow(
                    label: 'Haptic feedback',
                    icon: Icons.vibration_rounded,
                    switchValue: state.hapticsEnabled,
                    onSwitchChanged: state.setHapticsEnabled,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 10),
            child: SectionLabel('Accessibility'),
          ),
          const StaggeredEntrance(
            index: 4,
            child: SurfaceCard(
              padding: EdgeInsets.zero,
              child: SettingRow(
                label: 'Text size',
                value: 'Follows system',
                icon: Icons.format_size_rounded,
                showChevron: false,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
            child: Text(
              'Library+ uses the text size and reduce-motion choices from '
              'your phone accessibility settings.',
              style: AppText.body(12, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 10),
            child: SectionLabel('Other settings'),
          ),
          StaggeredEntrance(
            index: 4,
            child: SurfaceCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  SettingRow(
                    label: 'Help & Support',
                    icon: Icons.help_outline_rounded,
                    onTap: () => AppRoute.push(context, const HelpScreen()),
                  ),
                  const _RowDivider(),
                  SettingRow(
                    label: 'About App',
                    value: 'v$kAppVersion',
                    icon: Icons.info_outline_rounded,
                    onTap: () => AppRoute.push(
                      context,
                      const ValuePropositionScreen(),
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

/// System / Light / Dark chooser for the app theme.
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
        children: [
          for (final entry in <(ThemeMode, IconData, String)>[
            (ThemeMode.system, Icons.brightness_auto_rounded, 'System'),
            (ThemeMode.light, Icons.light_mode_rounded, 'Light'),
            (ThemeMode.dark, Icons.dark_mode_rounded, 'Dark'),
          ])
            Expanded(
              child: _ThemePick(
                icon: entry.$2,
                label: entry.$3,
                selected: mode == entry.$1,
                onTap: () {
                  AppFeedback.select();
                  state.setThemeMode(entry.$1);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _ThemePick extends StatelessWidget {
  const _ThemePick({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppColors.textInverse : AppColors.textSecondary;
    return Semantics(
      button: true,
      selected: selected,
      label: '$label theme',
      excludeSemantics: true,
      child: PressScale(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: Curves.easeOutCubic,
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadii.full),
          ),
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            children: [
              Icon(icon, size: 16, color: fg),
              Text(label,
                  style: AppText.label(12, w: FontWeight.w600, color: fg)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, indent: 16, endIndent: 16);
}
