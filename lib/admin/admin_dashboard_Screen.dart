import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nutricare_client_management/admin/admin_dashboard_home_screen.dart';
import 'package:nutricare_client_management/admin/admin_inbox_screen.dart';
import 'package:nutricare_client_management/admin/admin_more_screen.dart';
import 'package:nutricare_client_management/admin/all_meeting_screen.dart';
import 'package:nutricare_client_management/admin/services/library_uploader.dart';
import 'package:nutricare_client_management/admin/services/quiz_uploader.dart';

import 'custom_gradient_app_bar.dart';

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
    AdminDashboardHomeScreen(), // Index 0: Home
    AllMeetingsScreen(),
    AdminInboxScreen(),
    Text("On development"),
    // Index 1: Payments
    // ClientLedgerOverviewScreen(),         // Index 2: Client
    //MasterSetupPage(),            // Index 3: Planner
    AdminMoreScreen()
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
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
        appBar: _selectedIndex == 0
            ? CustomGradientAppBar(
        //  centerTitle: false,
          title: const Text('Nutricare Wellness Planner'),
        //  backgroundColor: colorScheme.primary,
          //foregroundColor: colorScheme.onPrimary,
          // --- CHANGES HERE ---
        //  elevation: 10, // Add a visible shadow
          //shadowColor: Colors.black45, // Make the shadow distinct
          // --- END OF CHANGES ---
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications),
              onPressed: () {
                // TODO: Implement logic to show notifications screen/dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notifications button pressed')),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.cloud_upload),
              onPressed: () async {
                await LibraryUploader().uploadLibrary();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Library Updated!")));


              },
                // Inside CoachTab build method or any other screen

            ),

            IconButton(
              icon: Icon(Icons.cloud_upload),
              onPressed: () async {
                await QuizUploader().uploadQuizBank();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Quiz Bank Uploaded!")));
              },
            )
          ],
        )
            : null,

        // Display the screen corresponding to the selected index
        body:
        Center(
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
              label: 'More',
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