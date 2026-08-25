import 'package:flutter/material.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'features/account/account_screen.dart';
import 'features/books/book_search_screen.dart';
import 'features/home/home_screen.dart';
import 'features/seats/seat_map_screen.dart';
import 'features/waitlist/waitlist_screen.dart';

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

  void switchTo(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _index,
        children: const [
          HomeScreen(),
          BookSearchScreen(),
          SeatMapScreen(),
          WaitlistScreen(),
          AccountScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(AppRadii.xl),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.medium,
        ),
        child: NavigationBar(
          height: 68,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          selectedIndex: _index,
          onDestinationSelected: switchTo,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book_rounded),
              label: 'Books',
            ),
            NavigationDestination(
              icon: Icon(Icons.event_seat_outlined),
              selectedIcon: Icon(Icons.event_seat_rounded),
              label: 'Seats',
            ),
            NavigationDestination(
              icon: Icon(Icons.hourglass_top_outlined),
              selectedIcon: Icon(Icons.hourglass_top_rounded),
              label: 'Waitlist',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Account',
            ),
          ],
        ),
      ),
    );
  }
}
