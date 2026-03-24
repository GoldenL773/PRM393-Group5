import 'package:flutter/material.dart';
import 'package:goldfit_frontend/features/home/home_screen.dart';
import 'package:provider/provider.dart';
import 'package:goldfit_frontend/shared/providers/app_state.dart';
import 'package:goldfit_frontend/features/wardrobe/wardrobe_screen.dart';
import 'package:goldfit_frontend/features/try_on/try_on_screen.dart';
import 'package:goldfit_frontend/features/planner/planner_screen.dart';
import 'package:goldfit_frontend/features/insights/insights_screen.dart';


/// Root navigation structure with bottom navigation bar
/// Manages navigation between 5 main screens: Home, Wardrobe, Try-On, Planner, Insights
/// Uses IndexedStack to preserve screen state during navigation
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  // Removed local _currentIndex to use AppState.currentTab

  // Main screens for bottom navigation
  final List<Widget> _screens = const [
    HomeScreen(),
    WardrobeScreen(),
    TryOnScreen(),
    PlannerScreen(),
    InsightsScreen(),
  ];

  void _onTabTapped(int index) {
    context.read<AppState>().setTab(index);
  }

  @override
  Widget build(BuildContext context) {
    final currentTab = context.watch<AppState>().currentTab;

    return Scaffold(
      body: IndexedStack(
        index: currentTab,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentTab,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.checkroom_outlined),
            activeIcon: Icon(Icons.checkroom),
            label: 'Wardrobe',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Try-On',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today),
            label: 'Planner',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insights_outlined),
            activeIcon: Icon(Icons.insights),
            label: 'Insights',
          ),
        ],
      ),
    );
  }
}
