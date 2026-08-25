import 'package:flutter/material.dart';
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
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.inkDeep,
          border: Border(
            top: BorderSide(color: AppColors.gold.withValues(alpha: 0.28)),
          ),
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            backgroundColor: AppColors.inkDeep,
            surfaceTintColor: Colors.transparent,
            indicatorColor: AppColors.gold.withValues(alpha: 0.16),
            indicatorShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              final selected = states.contains(WidgetState.selected);
              return AppText.sans(
                11,
                w: selected ? FontWeight.w700 : FontWeight.w500,
                ls: 0.2,
                color: selected
                    ? AppColors.gold
                    : AppColors.paper.withValues(alpha: 0.38),
              );
            }),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              final selected = states.contains(WidgetState.selected);
              return IconThemeData(
                size: 23,
                color: selected
                    ? AppColors.gold
                    : AppColors.paper.withValues(alpha: 0.38),
              );
            }),
          ),
          child: NavigationBar(
            height: 76,
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
      ),
    );
  }
}
