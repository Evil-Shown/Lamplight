import 'package:flutter/material.dart';

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

/// The role-aware bottom navigation.
///
/// The prototype ships two bars: `Home · Seats · Books · Bookings ·
/// Profile` for students and `Home · Seats · Catalog · Bookings · Staff`
/// for library staff, so the destination list is built from the signed-in
/// role rather than being fixed.
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
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: NavigationBar(
          selectedIndex: safeIndex,
          onDestinationSelected: switchTo,
          destinations: [
            for (final d in destinations)
              NavigationDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.selectedIcon),
                label: d.label,
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
