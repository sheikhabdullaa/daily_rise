import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'my_habit.dart';
import 'progress_screen.dart';
import 'profile_screen.dart';

class DailyRiseNavigation extends StatefulWidget {
  const DailyRiseNavigation({super.key});

  @override
  State<DailyRiseNavigation> createState() =>
      _DailyRiseNavigationState();
}

class _DailyRiseNavigationState extends State<DailyRiseNavigation> {
  static const Color background = Color(0xFF101A17);
  static const Color green = Color(0xFF91C7A2);
  static const Color border = Color(0xFF2B3C34);

  int _selectedIndex = 0;

  late final List<Widget> _screens = const [
    HomeScreen(),
    MyHabitsScreen(),
    ProgressScreen(),
    ProfileSettingsScreen(),
  ];

  void _onDestinationSelected(int index) {
    if (index < 0 || index >= _screens.length) {
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Ensure the selected index is always valid.
    final int safeIndex = _screens.isEmpty
        ? 0
        : _selectedIndex.clamp(0, _screens.length - 1);

    return Scaffold(
      backgroundColor: background,

      body: IndexedStack(
        index: safeIndex,
        children: _screens,
      ),

      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: background,
          border: Border(
            top: BorderSide(
              color: border,
              width: 0.8,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: NavigationBar(
            height: 67,
            backgroundColor: background,
            indicatorColor: green.withValues(alpha: 0.15),
            selectedIndex: safeIndex,
            onDestinationSelected: _onDestinationSelected,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.wb_sunny_outlined),
                selectedIcon: Icon(Icons.wb_sunny_rounded),
                label: 'Today',
              ),
              NavigationDestination(
                icon: Icon(Icons.checklist_rounded),
                selectedIcon: Icon(Icons.check_circle_rounded),
                label: 'My Habits',
              ),
              NavigationDestination(
                icon: Icon(Icons.show_chart_rounded),
                selectedIcon: Icon(Icons.insights_rounded),
                label: 'Progress',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
