import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nutricare_client_management/admin/admin_account_page.dart';
import 'package:nutricare_client_management/admin/admin_dashboard_home_screen.dart';
import 'package:nutricare_client_management/admin/all_meeting_screen.dart';
import 'package:nutricare_client_management/pages/admin/client_ledger_overview_screen.dart';
import 'package:nutricare_client_management/screens/dash/master_Setup_page.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});


  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final  _admin = FirebaseAuth.instance.currentUser ?? 'admin';
  int _selectedIndex = 0; // Index of the currently selected tab

  // List of all screens corresponding to the BottomNavigationBar items
  static const List<Widget> _widgetOptions = <Widget>[
    AdminDashboardHomeScreen(),
    AllMeetingsScreen(),// Index 0: Home
    Text("On development"),
    Text("On development"),
    // Index 1: Payments
   // ClientLedgerOverviewScreen(),         // Index 2: Client
    //MasterSetupPage(),            // Index 3: Planner
    AdminAccountPage()
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    // The AuthWrapper in main.dart will automatically detect the sign-out
    // and navigate back to LoginChoiceScreen.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The AppBar can be customized or hidden based on the current tab
      appBar: AppBar(
        title: const Text('NutriCare Admin'),
        actions: [
          // Keeping the Logout button accessible
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),

      // Display the screen corresponding to the selected index
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),

      // --- BOTTOM NAVIGATION BAR ---
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.payment),
            label: 'Activity Tracker',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Posts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_note),
            label: 'Notification',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Accounts',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.indigo, // Highlight the current tab
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed, // Use fixed type for 5 items
        onTap: _onItemTapped,
      ),
    );
  }
}