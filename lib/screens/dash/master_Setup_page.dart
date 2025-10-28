import 'package:flutter/material.dart';
import 'package:nutricare_client_management/meal_planner/screen/InvestigationMasterScreen.dart' show InvestigationMasterScreen;
import 'package:nutricare_client_management/meal_planner/screen/dash/diet_plan_master_dashboard.dart';
import 'package:nutricare_client_management/meal_planner/screen/disease_master_list_screen.dart';
import 'package:nutricare_client_management/meal_planner/screen/guideline_list_page.dart';
import 'package:nutricare_client_management/modules/client/screen/supplementation_master_screen.dart' show SupplementationMasterScreen;
import 'package:nutricare_client_management/modules/master/screen/diagonosis_master_screen.dart';
import 'package:nutricare_client_management/modules/master/screen/master_diet_plan_list_screen.dart' show MasterDietPlanListScreen;
import 'package:nutricare_client_management/screens/package_list_page.dart';
import 'package:nutricare_client_management/screens/program_feature_master_screen.dart';


class MasterSetupPage extends StatefulWidget {
  const MasterSetupPage({super.key});

  @override
  State<MasterSetupPage> createState() => _MasterSetupPageState();
}

class _MasterSetupPageState extends State<MasterSetupPage> {
  // State variables to control the expansion of each section
  bool _isPackagePlannerExpanded = true;
  bool _isDietPlannerExpanded = true;
  bool _isLabVitalsExpanded = true;

  // Helper method to navigate to a module
  void _navigateToModule(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (c) => page));
  }

  // Helper to build a standard module tile item with background
  Widget _buildModuleTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 1, horizontal: 0),
      // 🎯 List Item Background: Light Grey
      decoration: BoxDecoration(
        color: Colors.grey.shade100, // Slightly darker than the header
        border: Border.all(color: Colors.grey.shade200, width: 0.5),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.only(left: 30, right: 16), // Indent content for hierarchy
        leading: Icon(icon, color: color),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  // REVISED: Helper to build a collapsible section with clear header separation
  Widget _buildCollapsibleSection({
    required String title,
    required String subtitle,
    required bool isExpanded,
    required ValueChanged<bool> onExpansionChanged,
    required List<Widget> children,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. PRIMARY HEADER (Visually distinct with background color)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.only(top: 24.0, bottom: 12.0, left: 16, right: 16),
          color: Colors.blueGrey.shade50,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.blueGrey.shade800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const Divider(height: 16, thickness: 1.5),
            ],
          ),
        ),

        // 2. EXPANSION TILE CONTAINER (The collapsible list)
        Container(
          // 🎯 Expansion Tile Header Background: White
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 0,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          margin: const EdgeInsets.only(bottom: 16, top: 0, left: 16, right: 16),
          child: ExpansionTile(
            initiallyExpanded: isExpanded,
            onExpansionChanged: onExpansionChanged,
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),

            // Icon and title for the collapsible action
            leading: Icon(icon, color: color),
            title: Text(
              '${title} Modules',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.blueGrey.shade700,
              ),
            ),
            // The children here will use the slightly darker background defined in _buildModuleTile
            children: children,
          ),
        ),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Setup & Configuration'),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
      ),
      // Set a general background for the screen
      body: Container(
        color: Colors.grey.shade100,
        child: ListView(
          padding: const EdgeInsets.only(top: 0),
          children: <Widget>[

            // =======================================================
            // SECTION 1: PACKAGE PLANNER (COLLAPSIBLE)
            // =======================================================
            _buildCollapsibleSection(
              title: 'Package Planner',
              subtitle: 'Manage master data for package creations and features.',
              icon: Icons.inventory_2,
              color: Colors.purple,
              isExpanded: _isPackagePlannerExpanded,
              onExpansionChanged: (expanded) => setState(() => _isPackagePlannerExpanded = expanded),
              children: [
                _buildModuleTile(
                  icon: Icons.star,
                  color: Colors.red,
                  title: 'Program Features Master',
                  subtitle: 'Create and manage reusable program features.',
                  onTap: () => _navigateToModule(context, const ProgramFeatureMasterScreen()),
                ),
                _buildModuleTile(
                  icon: Icons.inventory_2_outlined,
                  color: Colors.purple,
                  title: 'Service Packages Master',
                  subtitle: 'Create, edit, and deactivate subscription packages.',
                  onTap: () => _navigateToModule(context, const PackageListPage()),
                ),
              ],
            ),

            // =======================================================
            // SECTION 2: DIET PLANNER SETUP (COLLAPSIBLE)
            // =======================================================
            _buildCollapsibleSection(
              title: 'Diet Planner Setup',
              subtitle: 'Configure food items, and common diet template components.',
              icon: Icons.fastfood,
              color: Colors.green,
              isExpanded: _isDietPlannerExpanded,
              onExpansionChanged: (expanded) => setState(() => _isDietPlannerExpanded = expanded),
              children: [
                _buildModuleTile(
                  icon: Icons.format_list_bulleted,
                  color: Colors.indigo,
                  title: 'Diet Plan Master Builder',
                  subtitle: 'Access the master data to create reusable diet plans.',
                  onTap: () => _navigateToModule(context, const DietPlanMasterPage()),
                ),
                _buildModuleTile(
                  icon: Icons.restaurant_menu,
                  color: Colors.green,
                  title: 'Meal Template',
                  subtitle: 'Manage Meal Template (List of master plans).',
                  onTap: () => _navigateToModule(context, const MasterDietPlanListScreen()),
                ),
              ],
            ),

            // =======================================================
            // SECTION 3: LAB VITALS & MEDICAL (COLLAPSIBLE)
            // =======================================================
            _buildCollapsibleSection(
              title: 'Lab Vitals & Medical',
              subtitle: 'Manage master lists for Diagnosis, Investigations, and Supplements.',
              icon: Icons.local_hospital,
              color: Colors.red.shade700,
              isExpanded: _isLabVitalsExpanded,
              onExpansionChanged: (expanded) => setState(() => _isLabVitalsExpanded = expanded),
              children: [
                _buildModuleTile(
                  icon: Icons.medical_services,
                  color: Colors.blue,
                  title: 'Diagnosis',
                  subtitle: 'Manage the master diagnosis list.',
                  onTap: () => _navigateToModule(context, DiagnosisListPage()),
                ),
                _buildModuleTile(
                  icon: Icons.rule,
                  color: Colors.blue,
                  title: 'Guidelines',
                  subtitle: 'Manage the master list of global guidelines.',
                  onTap: () => _navigateToModule(context, GuidelineListPage()),
                ),
                _buildModuleTile(
                  icon: Icons.science,
                  color: Colors.blue,
                  title: 'Investigations',
                  subtitle: 'Manage the master list of lab investigation names.',
                  onTap: () => _navigateToModule(context, InvestigationMasterScreen()),
                ),
                _buildModuleTile(
                  icon: Icons.medication_liquid,
                  color: Colors.blue,
                  title: 'Supplementation',
                  subtitle: 'Manage the master list of supplements.',
                  onTap: () => _navigateToModule(context, SupplementationMasterScreen()),
                ),
                _buildModuleTile(
                  icon: Icons.masks,
                  color: Colors.blue,
                  title: 'Disease',
                  subtitle: 'Manage the master list of diseases/conditions.',
                  onTap: () => _navigateToModule(context, DiseaseMasterListScreen()),
                ),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}