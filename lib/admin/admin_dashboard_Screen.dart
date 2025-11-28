import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nutricare_client_management/admin/admin_dashboard_home_screen.dart';
import 'package:nutricare_client_management/admin/admin_inbox_screen.dart';
import 'package:nutricare_client_management/admin/admin_more_screen.dart';
import 'package:nutricare_client_management/admin/all_meeting_screen.dart';

// 🎯 NOTE: I removed the 'Uploader' imports since we removed the App Bar buttons.
// You should move those upload actions to the "Master Setup" screen if you still need them.

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    AdminDashboardHomeScreen(), // Index 0: Home (Has its own Custom Header now)
    AllMeetingsScreen(),        // Index 1: Meetings
    AdminInboxScreen(),         // Index 2: Inbox
    Center(child: Text("Notifications (Coming Soon)")), // Index 3: Placeholder
    AdminMoreScreen()           // Index 4: More
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 🎯 FIX: Removed 'appBar' entirely.
      // The Home screen now draws its own premium header behind the status bar.

      body: _widgetOptions.elementAt(_selectedIndex),

      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_rounded),
            label: 'Schedule',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_rounded),
            label: 'Inbox',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_rounded),
            label: 'Alerts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded),
            label: 'More',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        onTap: _onItemTapped,
        elevation: 10,
        backgroundColor: Colors.white,
      ),
    );
  }
}