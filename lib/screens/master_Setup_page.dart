import 'package:flutter/material.dart';
// Core App Screens
import 'package:nutricare_client_management/screens/package_list_page.dart';
import 'package:nutricare_client_management/screens/program_feature_master_screen.dart';
import 'package:nutricare_client_management/screens/vitals_history_page.dart';
import 'package:nutricare_client_management/screens/feature_config_master_screen.dart';
// 🎯 Integrated Library: The screen for creating diet plan templates



class MasterSetupPage extends StatelessWidget {
  const MasterSetupPage({super.key});

  // Helper method to navigate to a module
  void _navigateToModule(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (c) => page));
  }

  // Helper to create section headers
  Widget _buildSectionHeader(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey.shade800,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const Divider(height: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Setup & Configuration'),
        backgroundColor: Colors.blueGrey,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: <Widget>[

          // =======================================================
          // SECTION 1: MASTER DATA SETUP
          // =======================================================
          _buildSectionHeader(
              'Master Data Setup',
              'Manage core data entities that define service offerings and structure.'
          ),
          Card(
            elevation: 3,
            child: ListTile(
              leading: const Icon(Icons.star, color: Colors.red),
              title: const Text('Program Features Master'),
              subtitle: const Text('Create and manage reusable program features (e.g., specific plans, support levels).'),
              trailing: const Icon(Icons.arrow_forward_ios),
              // 🎯 Navigates to the new CRUD screen
              onTap: () => _navigateToModule(context, const ProgramFeatureMasterScreen()),
            ),
          ),
          // 1. Package Master
          Card(
            elevation: 3,
            child: ListTile(
              leading: const Icon(Icons.inventory_2_outlined, color: Colors.purple),
              title: const Text('Service Packages Master'),
              subtitle: const Text('Create, edit, and deactivate subscription packages.'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _navigateToModule(context, const PackageListPage()),
            ),
          ),
          const SizedBox(height: 10),

          // 2. Vitals Fields Master (Placeholder)
          Card(
            elevation: 3,
            child: ListTile(
              leading: const Icon(Icons.add_chart, color: Colors.teal),
              title: const Text('Vitals Fields Master'),
              subtitle: const Text('Define and categorize metrics for client tracking.'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // Placeholder navigation
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vitals Fields Master Module Coming Soon.')),
                );
              },
            ),
          ),
          const SizedBox(height: 10),

          // 3. Client Groups/Tags Master (Placeholder)
          Card(
            elevation: 3,
            child: ListTile(
              leading: const Icon(Icons.groups, color: Colors.amber),
              title: const Text('Client Groups & Tags Master'),
              subtitle: const Text('Manage tags for segmenting and filtering clients.'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // Placeholder navigation
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Client Group Master Module Coming Soon.')),
                );
              },
            ),
          ),
          const SizedBox(height: 10),

          // 4. Program Templates Master (Placeholder for growth)
          Card(
            elevation: 3,
            child: ListTile(
              leading: const Icon(Icons.fitness_center, color: Colors.red),
              title: const Text('Program Templates Master'),
              subtitle: const Text('Define standard training or diet templates.'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // Placeholder navigation
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Program Templates Module Coming Soon.')),
                );
              },
            ),
          ),

          // =======================================================
          // SECTION 2: DIET PLANNER SETUP
          // =======================================================
          _buildSectionHeader(
              'Diet Planner Setup',
              'Configure food items, recipes, and common diet template components.'
          ),

          // 5. INTEGRATED LIBRARY: Diet Plan Template Builder
          Card(
            elevation: 3,
            child: ListTile(
              leading: const Icon(Icons.format_list_bulleted, color: Colors.indigo),
              title: const Text('Diet Plan Template Builder'),
              subtitle: const Text('Access the integrated module to create reusable diet plans.'),
              trailing: const Icon(Icons.launch),
              // 🎯 Navigates directly to the external library's main screen
            //  onTap: () => _navigateToModule(context, const DietTemplateBuilderScreen()),
            ),
          ),
          const SizedBox(height: 10),

          // 6. Food Item Master (Placeholder)
          Card(
            elevation: 3,
            child: ListTile(
              leading: const Icon(Icons.restaurant_menu, color: Colors.green),
              title: const Text('Food Item Master'),
              subtitle: const Text('Manage nutritional data for individual food items.'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // Placeholder navigation
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Food Item Master Coming Soon.')),
                );
              },
            ),
          ),
          const SizedBox(height: 10),

          // 7. Recipe/Meal Master (Placeholder)
          Card(
            elevation: 3,
            child: ListTile(
              leading: const Icon(Icons.local_dining, color: Colors.orange),
              title: const Text('Recipe & Meal Master'),
              subtitle: const Text('Define reusable meal and recipe templates.'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // Placeholder navigation
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Recipe & Meal Master Coming Soon.')),
                );
              },
            ),
          ),

          // =======================================================
          // SECTION 3: MODULE CONFIGURATION
          // =======================================================
          _buildSectionHeader(
              'Module Configuration',
              'Globally enable/disable features and manage access controls.'
          ),

          // 8. Feature Toggles (CRUD Master List)
          Card(
            elevation: 3,
            child: ListTile(
              leading: const Icon(Icons.toggle_on, color: Colors.blue),
              title: const Text('Feature & Module Toggles'),
              subtitle: const Text('Manage the master list (CRUD) of global and client-specific features.'),
              trailing: const Icon(Icons.arrow_forward_ios),
              // Navigates to the Feature Configuration Master CRUD screen
              onTap: () => _navigateToModule(context,  FeatureConfigMasterScreen()),
            ),
          ),
        ],
      ),
    );
  }
}