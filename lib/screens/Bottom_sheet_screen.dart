import 'package:daily_rise/screens/my_habit.dart';
import 'package:daily_rise/screens/profile_screen.dart';
import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'progress_screen.dart';

class DailyRiseNavigation extends StatefulWidget {
  const DailyRiseNavigation({super.key});

  @override
  State<DailyRiseNavigation> createState() => _DailyRiseNavigationState();
}

class _DailyRiseNavigationState extends State<DailyRiseNavigation> {
  static const Color background = Color(0xFF101A17);
  static const Color green = Color(0xFF91C7A2);
  static const Color muted = Color(0xFF9BAEA3);
  static const Color border = Color(0xFF2B3C34);

  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    MyHabitsScreen(),
    ProgressScreen(),
    ProfileSettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: background,
          border: Border(top: BorderSide(color: border, width: 0.8)),
        ),
        child: SafeArea(
          top: false,
          child: NavigationBar(
            height: 67,
            backgroundColor: background,
            indicatorColor: green.withValues(alpha: 0.15),
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
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
