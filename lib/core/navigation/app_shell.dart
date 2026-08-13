import 'package:flutter/material.dart';

import '../../features/calls/presentation/screens/home_screen.dart';
import '../../features/chat/presentation/screens/chat_list_screen.dart';
import '../../features/contacts/presentation/screens/contacts_list_screen.dart';
import '../../features/home/presentation/screens/home_dashboard_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';

/// Top-level app shell shown after successful authentication.
///
/// Wires the 5 bottom-navigation tabs. Each tab owns its own Scaffold/
/// AppBar (matching the pattern already used by the existing Contacts and
/// Calls screens), so this widget itself stays a thin IndexedStack host —
/// no shared global AppBar to keep in sync, and no changes required to
/// Contacts' or Calls' internal logic to embed them here.
///
/// Deliberately built so later phases (Chat, notifications) can replace
/// individual tab bodies without touching this file's structure.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const _tabs = [
    HomeDashboardScreen(),
    ChatListScreen(),
    ContactsListScreen(),
    HomeScreen(), // existing calls screen, unmodified logic
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: _tabs,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'الرئيسية',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'المحادثات',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.contacts_outlined),
            activeIcon: Icon(Icons.contacts),
            label: 'جهات الاتصال',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.call_outlined),
            activeIcon: Icon(Icons.call),
            label: 'المكالمات',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'الملف الشخصي',
          ),
        ],
      ),
    );
  }
}
