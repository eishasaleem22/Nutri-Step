import 'package:flutter/material.dart';
import 'package:flutter_projects/screens/profile_screen.dart';
import 'package:flutter_projects/screens/progress_screen.dart';
import 'dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _screens = <Widget>[
    DashboardScreen(),
    ProgressScreen(),
    ProfileScreen(),
  ];

  static final List<String> _titles = <String>[
    'Dashboard',
    'Progress',
    'Profile',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final gradient = LinearGradient(
      colors: [colorScheme.primary, colorScheme.secondary],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: _screens[_selectedIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          selectedItemColor: colorScheme.primary,
          unselectedItemColor: colorScheme.onSurface.withOpacity(0.6),
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedLabelStyle: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w400,
          ),
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(
              icon: _selectedIndex == 0
                  ? ShaderMask(
                shaderCallback: (bounds) => gradient
                    .createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
                child: Icon(Icons.dashboard, size: 28, color: colorScheme.onPrimary),
              )
                  : Icon(Icons.dashboard, size: 28),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: _selectedIndex == 1
                  ? ShaderMask(
                shaderCallback: (bounds) => gradient
                    .createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
                child: Icon(Icons.bar_chart, size: 28, color: colorScheme.onPrimary),
              )
                  : Icon(Icons.bar_chart, size: 28),
              label: 'Progress',
            ),
            BottomNavigationBarItem(
              icon: _selectedIndex == 2
                  ? ShaderMask(
                shaderCallback: (bounds) => gradient
                    .createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
                child: Icon(Icons.person, size: 28, color: colorScheme.onPrimary),
              )
                  : Icon(Icons.person, size: 28),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}