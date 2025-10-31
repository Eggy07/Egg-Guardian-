import 'package:flutter/material.dart';
import 'theme_controller.dart';
import './screens/egg_reminder_page.dart';
import './screens/dashboard_page.dart';
import './screens/settings_page.dart';
import './screens/live_feed_page.dart';
import './screens/egg_manager_page.dart';
import './screens/login_page.dart';

void main() {
  runApp(const EggApp());
}

class EggApp extends StatelessWidget {
  const EggApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Wrap MaterialApp with ValueListenableBuilder to listen for theme changes
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.themeMode,
      builder: (context, themeMode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Egg Guardian',
          theme: ThemeData(
            primaryColor: const Color(0xFFFFC400),
            scaffoldBackgroundColor: Colors.white,
            fontFamily: 'Roboto',
            brightness: Brightness.light,
          ),
          darkTheme: ThemeData(
            primaryColor: const Color(0xFFFFC400),
            scaffoldBackgroundColor: Colors.grey[900],
            fontFamily: 'Roboto',
            brightness: Brightness.dark,
            colorScheme: ColorScheme.dark(
              primary: const Color(0xFFFFC400),
              secondary: Colors.orangeAccent,
            ),
          ),
          themeMode: themeMode,
          home: const LoginPage(), // Start at login page
        );
      },
    );
  }
}

class MainPage extends StatefulWidget {
  final int userId;
  const MainPage({super.key, required this.userId});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Move the pages list here to access widget.userId
    final List<Widget> pages = [
      DashboardPage(userId: widget.userId),
      const LiveFeedPage(),
      const EggManagerPage(),
      const EggReminderPage(),
      SettingsPage(userId: widget.userId),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFC400),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.black45,
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Dashboard'),

            BottomNavigationBarItem(
              icon: Icon(Icons.remove_red_eye),
              label: 'Live Feed',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.list_alt),
              label: 'Egg Manager',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.remember_me),
              label: 'Reminder',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
