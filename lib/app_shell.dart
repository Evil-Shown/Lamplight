import 'package:flutter/material.dart';

import 'core/navigation/app_route.dart';
import 'core/state/app_state.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/glass.dart';
import 'core/widgets/glass_dock.dart';
import 'core/widgets/shared_widgets.dart';
import 'features/account/account_screen.dart';
import 'features/books/book_search_screen.dart';
import 'features/home/home_screen.dart';
import 'features/reservations/reservations_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/seats/seat_map_screen.dart';
import 'features/staff/staff_dashboard_screen.dart';
import 'features/staff/staff_manage_screen.dart';
import 'features/staff/staff_scanner_screen.dart';

/// Tab indices, shared so screens can jump between them by name.
class AppTab {
  AppTab._();

  static const home = 0;
  static const seats = 1;
  static const books = 2;
  static const bookings = 3;
  static const profile = 4;

  // Staff shell: Dashboard, Scan, Manage, Account.
  static const scan = 1;
  static const manage = 2;
  static const staffAccount = 3;
}

/// Role-aware shell with a floating glass navigation dock.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  /// Switches tab; returns false when there is no shell above [context].
  static bool switchTab(BuildContext context, int index) {
    final shell = context.findAncestorStateOfType<_AppShellState>();
    shell?.switchTo(index);
    return shell != null;
  }

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowThemeHint());
  }

  /// One-time pointer to the theme setting, shown the first time the
  /// signed-in shell appears on this device.
  void _maybeShowThemeHint() {
    if (!mounted) return;
    final state = AppScope.of(context);
    if (state.themeHintSeen) return;
    state.markThemeHintSeen();
    showGlassSheet<void>(
      context,
      opaque: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  child: Icon(Icons.palette_outlined,
                      size: 24, color: AppColors.primary),
                ),
                const SizedBox(width: AppSpacing.base),
                Expanded(
                  child: Text('Light theme is on',
                      style: AppText.display(22, w: FontWeight.w700, ls: -0.3)),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.base),
            Text(
              'Prefer dark, or want it to follow your phone? '
              'Change the theme any time in Settings.',
              style: AppText.body(14.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: 'Got it',
              onPressed: () => Navigator.pop(sheetContext),
            ),
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              label: 'Open Settings',
              tone: ButtonTone.secondary,
              onPressed: () {
                Navigator.pop(sheetContext);
                if (mounted) AppRoute.push(context, const SettingsScreen());
              },
            ),
          ],
        ),
      ),
    );
  }

  void switchTo(int index) {
    if (index < 0 || index >= _destinations.length) return;
    if (index == _index) return;
    setState(() => _index = index);
  }

  List<_Destination> get _destinations => isStaff ? _staffTabs : _studentTabs;

  bool get isStaff => AppScope.of(context).isStaff;

  static const _studentTabs = <_Destination>[
    _Destination(Icons.home_outlined, Icons.home_rounded, 'Home'),
    _Destination(Icons.event_seat_outlined, Icons.event_seat_rounded, 'Seats'),
    _Destination(Icons.menu_book_outlined, Icons.menu_book_rounded, 'Books'),
    _Destination(Icons.confirmation_number_outlined,
        Icons.confirmation_number_rounded, 'Bookings'),
    _Destination(Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
  ];

  static const _staffTabs = <_Destination>[
    _Destination(
        Icons.dashboard_outlined, Icons.dashboard_rounded, 'Dashboard'),
    _Destination(
        Icons.qr_code_scanner_rounded, Icons.qr_code_scanner_rounded, 'Scan'),
    _Destination(Icons.tune_rounded, Icons.tune_rounded, 'Manage'),
    _Destination(Icons.person_outline_rounded, Icons.person_rounded, 'Account'),
  ];

  List<Widget> get _screens => isStaff
      ? const [
          StaffDashboardScreen(),
          StaffScannerScreen(embedded: true),
          StaffManageScreen(),
          AccountScreen(),
        ]
      : const [
          HomeScreen(),
          SeatMapScreen(),
          BookSearchScreen(),
          ReservationsScreen(),
          AccountScreen(),
        ];

  @override
  Widget build(BuildContext context) {
    final destinations = _destinations;
    final screens = _screens;
    final safeIndex = _index.clamp(0, destinations.length - 1);
    final dockDestinations = [
      for (final d in destinations)
        GlassDockDestination(
          icon: d.icon,
          selectedIcon: d.selectedIcon,
          label: d.label,
        ),
    ];

    final dockHeight = GlassDock.height +
        GlassDock.bottomInset +
        MediaQuery.paddingOf(context).bottom;

    return AuroraBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: AppMotion.tabFade,
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: KeyedSubtree(
                  key: ValueKey<int>(safeIndex),
                  child: Padding(
                    padding: EdgeInsets.only(bottom: dockHeight),
                    child: screens[safeIndex],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: GlassDock(
                selectedIndex: safeIndex,
                onSelected: switchTo,
                destinations: dockDestinations,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Destination {
  const _Destination(this.icon, this.selectedIcon, this.label);

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}
