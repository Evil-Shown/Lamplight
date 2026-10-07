import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/state/app_state.dart';
import 'core/theme/app_theme.dart';
import 'features/account/account_screen.dart';
import 'features/books/book_search_screen.dart';
import 'features/home/home_screen.dart';
import 'features/reservations/reservations_screen.dart';
import 'features/seats/seat_map_screen.dart';
import 'features/staff/staff_dashboard_screen.dart';

/// Tab indices, shared so screens can jump between them by name.
class AppTab {
  AppTab._();

  static const home = 0;
  static const seats = 1;
  static const books = 2;
  static const bookings = 3;
  static const profile = 4;
}

/// The role-aware shell with a floating glass navigation bar.
///
/// The prototype ships two destination sets: `Home · Seats · Books ·
/// Bookings · Profile` for students and `Home · Seats · Catalog ·
/// Bookings · Staff` for library staff, so the tab list is built from the
/// signed-in role rather than being fixed.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  static void switchTab(BuildContext context, int index) {
    context.findAncestorStateOfType<_AppShellState>()?.switchTo(index);
  }

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  void switchTo(int index) {
    if (index < 0 || index >= _destinations.length) return;
    if (index == _index) return;
    HapticFeedback.selectionClick();
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
    _Destination(Icons.home_outlined, Icons.home_rounded, 'Home'),
    _Destination(Icons.event_seat_outlined, Icons.event_seat_rounded, 'Seats'),
    _Destination(Icons.library_books_outlined, Icons.library_books_rounded,
        'Catalog'),
    _Destination(Icons.confirmation_number_outlined,
        Icons.confirmation_number_rounded, 'Bookings'),
    _Destination(Icons.badge_outlined, Icons.badge_rounded, 'Staff'),
  ];

  List<Widget> get _screens => isStaff
      ? const [
          StaffDashboardScreen(),
          SeatMapScreen(),
          BookSearchScreen(),
          ReservationsScreen(),
          StaffDashboardScreen(),
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

    return Scaffold(
      body: IndexedStack(index: safeIndex, children: screens),
      bottomNavigationBar: _GlassNavBar(
        destinations: destinations,
        selectedIndex: safeIndex,
        onSelected: switchTo,
        // The Home tab is a dark hero surface, so the bar flips to
        // dark glass to sit on it (mirrors the Stitch design).
        dark: safeIndex == AppTab.home,
      ),
    );
  }
}

/// A floating, frosted pill navigation bar. Detached from the screen edges
/// with a soft ambient shadow, a translucent surface, and a sliding
/// indicator glow behind the active destination.
class _GlassNavBar extends StatelessWidget {
  const _GlassNavBar({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    this.dark = false,
  });

  final List<_Destination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
        child: Container(
          height: 66,
          decoration: BoxDecoration(
            color: dark
                ? const Color(0xFF17202C).withValues(alpha: 0.92)
                : (AppColors.isDark
                    ? const Color(0xFF17202C).withValues(alpha: 0.92)
                    : const Color(0xFFFAF8F5).withValues(alpha: 0.95)),
            borderRadius: BorderRadius.circular(AppRadii.full),
            border: Border.all(
              color: dark
                  ? Colors.white.withValues(alpha: 0.12)
                  : (AppColors.isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : const Color(0xFFE2DDD3)),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1B1A17)
                    .withValues(alpha: dark || AppColors.isDark ? 0.40 : 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: AppColors.primary.withValues(
                    alpha: dark || AppColors.isDark ? 0.12 : 0.04),
                blurRadius: 30,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              for (var i = 0; i < destinations.length; i++)
                Expanded(
                  child: _GlassNavDestination(
                    destination: destinations[i],
                    selected: i == selectedIndex,
                    dark: dark,
                    onTap: () => onSelected(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassNavDestination extends StatelessWidget {
  const _GlassNavDestination({
    required this.destination,
    required this.selected,
    required this.onTap,
    this.dark = false,
  });

  final _Destination destination;
  final bool selected;
  final VoidCallback onTap;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final idle = dark ? Colors.white.withValues(alpha: 0.55) : AppColors.textFaint;

    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: selected ? 1 : 0),
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          builder: (context, t, child) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  if (t > 0)
                    Container(
                      width: 46,
                      height: 30,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadii.full),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primaryBright.withValues(alpha: 0.28 * t),
                            AppColors.accent.withValues(alpha: 0.18 * t),
                          ],
                        ),
                        border: Border.all(
                          color: AppColors.primaryBright
                              .withValues(alpha: 0.35 * t),
                        ),
                      ),
                    ),
                  Icon(
                    selected ? destination.selectedIcon : destination.icon,
                    size: 21 + 1.5 * t,
                    color: Color.lerp(idle, AppColors.primaryBright, t),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                destination.label,
                style: AppText.label(
                  10.5,
                  w: selected ? FontWeight.w700 : FontWeight.w500,
                  color: Color.lerp(idle, AppColors.primaryBright, t),
                ),
              ),
            ],
          ),
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
