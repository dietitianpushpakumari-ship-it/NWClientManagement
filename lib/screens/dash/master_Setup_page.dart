import 'package:flutter/material.dart';
import 'package:nutricare_client_management/admin/habit_master_screen.dart';
import 'package:nutricare_client_management/meal_planner/screen/InvestigationMasterScreen.dart';
import 'package:nutricare_client_management/meal_planner/screen/dash/diet_plan_master_dashboard.dart';
import 'package:nutricare_client_management/meal_planner/screen/disease_master_list_screen.dart';
import 'package:nutricare_client_management/meal_planner/screen/guideline_list_page.dart';
import 'package:nutricare_client_management/modules/client/screen/supplementation_master_screen.dart';
import 'package:nutricare_client_management/modules/master/screen/diagonosis_master_screen.dart';
import 'package:nutricare_client_management/modules/master/screen/master_diet_plan_list_screen.dart';
import 'package:nutricare_client_management/screens/package_list_page.dart';
import 'package:nutricare_client_management/screens/program_feature_master_screen.dart';
import 'package:nutricare_client_management/admin/custom_gradient_app_bar.dart';

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

  void _navigateToModule(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (c) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50, // Soft background
      appBar: CustomGradientAppBar(
        title: const Text('Setup & Configuration'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: <Widget>[
            // --- SECTION 1: PACKAGE PLANNER ---
            _buildSectionCard(
              context,
              title: 'Package Planner',
              subtitle: 'Manage packages & features',
              icon: Icons.inventory_2_rounded,
              color: Colors.deepPurple,
              isExpanded: _isPackagePlannerExpanded,
              onExpansionChanged: (val) => setState(() => _isPackagePlannerExpanded = val),
              children: [
                _buildModuleItem(
                  context,
                  title: 'Program Features',
                  subtitle: 'Define reusable features',
                  icon: Icons.star_rounded,
                  color: Colors.amber.shade700,
                  onTap: () => _navigateToModule(context, const ProgramFeatureMasterScreen()),
                ),
                _buildModuleItem(
                  context,
                  title: 'Service Packages',
                  subtitle: 'Create subscription plans',
                  icon: Icons.card_giftcard_rounded,
                  color: Colors.purple.shade700,
                  onTap: () => _navigateToModule(context, const PackageListPage()),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // --- SECTION 2: DIET PLANNER SETUP ---
            _buildSectionCard(
              context,
              title: 'Diet Planner Setup',
              subtitle: 'Configure food items & templates',
              icon: Icons.restaurant_menu_rounded,
              color: Colors.green,
              isExpanded: _isDietPlannerExpanded,
              onExpansionChanged: (val) => setState(() => _isDietPlannerExpanded = val),
              children: [
                _buildModuleItem(
                  context,
                  title: 'Diet Plan Master Builder',
                  subtitle: 'Setup base data (Foods, Meals)',
                  icon: Icons.build_circle_rounded,
                  color: Colors.indigo,
                  onTap: () => _navigateToModule(context, const DietPlanMasterPage()),
                ),
                _buildModuleItem(
                  context,
                  title: 'Meal Templates',
                  subtitle: 'Create reusable plan templates',
                  icon: Icons.copy_all_rounded,
                  color: Colors.teal,
                  onTap: () => _navigateToModule(context, const MasterDietPlanListScreen()),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // --- SECTION 3: LAB VITALS & MEDICAL ---
            _buildSectionCard(
              context,
              title: 'Lab Vitals & Medical',
              subtitle: 'Diagnosis, Labs & Supplements',
              icon: Icons.medical_services_rounded,
              color: Colors.redAccent,
              isExpanded: _isLabVitalsExpanded,
              onExpansionChanged: (val) => setState(() => _isLabVitalsExpanded = val),
              children: [
                _buildModuleItem(
                  context,
                  title: 'Diagnosis Master',
                  subtitle: 'Manage clinical diagnoses',
                  icon: Icons.local_hospital_rounded,
                  color: Colors.red,
                  onTap: () => _navigateToModule(context, const DiagnosisListPage()),
                ),
                _buildModuleItem(
                  context,
                  title: 'Investigations',
                  subtitle: 'Lab tests & panels',
                  icon: Icons.science_rounded,
                  color: Colors.blue,
                  onTap: () => _navigateToModule(context, const InvestigationMasterScreen()),
                ),
                _buildModuleItem(
                  context,
                  title: 'Supplementation',
                  subtitle: 'Vitamins & Supplements list',
                  icon: Icons.medication_rounded,
                  color: Colors.orange,
                  onTap: () => _navigateToModule(context, const SupplementationMasterScreen()),
                ),
                _buildModuleItem(
                  context,
                  title: 'Guidelines',
                  subtitle: 'Global diet guidelines',
                  icon: Icons.rule_rounded,
                  color: Colors.blueGrey,
                  onTap: () => _navigateToModule(context, const GuidelineListPage()),
                ),
                _buildModuleItem(
                  context,
                  title: 'Disease Conditions',
                  subtitle: 'Manage disease master list',
                  icon: Icons.coronavirus_rounded, // Or Icons.sick
                  color: Colors.deepOrange,
                  onTap: () => _navigateToModule(context, const DiseaseMasterListScreen()),
                ),
                _buildModuleItem(
                  context,
                  title: 'Habit Master',
                  subtitle: 'Manage Habits list',
                  icon: Icons.coronavirus_rounded, // Or Icons.sick
                  color: Colors.deepOrange,
                  onTap: () => _navigateToModule(context, const HabitMasterScreen()),
                ),
              ],
            ),

            // Bottom Spacing
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- 1. Section Card Widget ---
  Widget _buildSectionCard(
      BuildContext context, {
        required String title,
        required String subtitle,
        required IconData icon,
        required Color color,
        required bool isExpanded,
        required ValueChanged<bool> onExpansionChanged,
        required List<Widget> children,
      }) {
    return Card(
      elevation: 4,
      shadowColor: color.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        // Remove default divider lines from ExpansionTile
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: isExpanded,
          onExpansionChanged: onExpansionChanged,
          backgroundColor: Colors.white,
          collapsedBackgroundColor: Colors.white,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

          // Header Icon
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),

          // Header Text
          title: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey.shade800,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),

          // Custom Arrow
          trailing: AnimatedRotation(
            turns: isExpanded ? 0.5 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey.shade400, size: 28),
          ),

          // Module Items
          children: [
            // A subtle separator line
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Divider(height: 1, color: Colors.grey.shade100),
            ),
            ...children,
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // --- 2. Module Item Widget ---
  Widget _buildModuleItem(
      BuildContext context, {
        required String title,
        required String subtitle,
        required IconData icon,
        required Color color,
        required VoidCallback onTap,
      }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            // Smaller icon container for items
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 22, color: color),
            ),
            const SizedBox(width: 16),

            // Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),

            // Arrow
            Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey.shade300),
          ],
        ),
      ),
    );
  }
}