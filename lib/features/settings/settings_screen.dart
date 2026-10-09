import 'package:flutter/material.dart';

import '../../core/feedback/app_feedback.dart';
import '../../core/navigation/app_route.dart';
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
          // Reminders are not implemented in the backend this cycle
          // (audit gap FR16): shown disabled with an honest label.
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 10),
            child: SectionLabel('Reminders (coming soon)'),
          ),
          StaggeredEntrance(
            index: 1,
            child: SurfaceCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  SettingRow(label: 'Before my session starts', switchValue: prefs.reminderBeforeStart, onSwitchChanged: null),
                  const _RowDivider(),
                  SettingRow(label: 'Before pickup expires', switchValue: prefs.reminderBeforeExpiry, onSwitchChanged: null),
                  const _RowDivider(),
                  SettingRow(label: 'Waitlist updates', switchValue: prefs.waitlistUpdates, onSwitchChanged: null),
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
            child: SectionLabel('Other settings'),
          ),
          StaggeredEntrance(
            index: 4,
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
                  const _RowDivider(),
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
                  const _RowDivider(),
                  SettingRow(
                    label: 'About App',
                    value: 'v1.4.2',
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
                AppFeedback.select();
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
          duration: AppMotion.fast,
          curve: Curves.easeOutCubic,
          width: 36,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadii.full),
            border: selected
                ? Border.all(color: AppColors.primarySoft, width: 3)
                : Border.all(color: AppColors.border),
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

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, indent: 16, endIndent: 16);
}
