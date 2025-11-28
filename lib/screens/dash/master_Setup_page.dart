import 'dart:ui';
import 'package:flutter/material.dart';

// 🎯 Project Imports
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
// Note: ClinicalMasterScreen (Complaints/Allergies/Meds) can be added here if you have the import path.

class MasterSetupPage extends StatefulWidget {
  const MasterSetupPage({super.key});

  @override
  State<MasterSetupPage> createState() => _MasterSetupPageState();
}

class _MasterSetupPageState extends State<MasterSetupPage> {
  // Expansion State
  bool _isPackageExpanded = true;
  bool _isDietExpanded = false;
  bool _isClinicalExpanded = false;

  void _navigateTo(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE), // Premium Light Background
      body: Stack(
        children: [
          // 1. Ambient Background Glow
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 400, height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.05), blurRadius: 100, spreadRadius: 40),
                  BoxShadow(color: Colors.purple.withOpacity(0.05), blurRadius: 100, spreadRadius: 40, offset: const Offset(-50, 50)),
                ],
              ),
            ),
          ),

          Column(
            children: [
              // 2. Custom Glass Header
              _buildHeader(),

              // 3. Scrollable Content
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildSection(
                      title: "Package Management",
                      subtitle: "Features & Subscriptions",
                      icon: Icons.inventory_2_outlined,
                      color: Colors.deepPurple,
                      isExpanded: _isPackageExpanded,
                      onToggle: (v) => setState(() => _isPackageExpanded = v),
                      children: [
                        _buildTile("Program Features", "Define reusable service features", Icons.star_outline, Colors.amber, () => _navigateTo(const ProgramFeatureMasterScreen())),
                        _buildTile("Service Packages", "Create & manage subscription plans", Icons.card_giftcard, Colors.purple, () => _navigateTo(const PackageListPage())),
                      ],
                    ),
                    const SizedBox(height: 20),

                    _buildSection(
                      title: "Diet Planner Config",
                      subtitle: "Foods, Meals & Templates",
                      icon: Icons.restaurant_menu,
                      color: Colors.teal,
                      isExpanded: _isDietExpanded,
                      onToggle: (v) => setState(() => _isDietExpanded = v),
                      children: [
                        _buildTile("Food & Meal Database", "Manage food items and master meals", Icons.lunch_dining, Colors.orange, () => _navigateTo(const DietPlanMasterPage())),
                        _buildTile("Diet Templates", "Pre-set meal plan templates", Icons.copy_all, Colors.teal, () => _navigateTo(const MasterDietPlanListScreen())),
                        _buildTile("Guidelines", "Global diet instructions", Icons.rule, Colors.blueGrey, () => _navigateTo(const GuidelineListPage())),
                      ],
                    ),
                    const SizedBox(height: 20),

                    _buildSection(
                      title: "Clinical & Medical",
                      subtitle: "Diagnosis, Labs & Habits",
                      icon: Icons.medical_services_outlined,
                      color: Colors.redAccent,
                      isExpanded: _isClinicalExpanded,
                      onToggle: (v) => setState(() => _isClinicalExpanded = v),
                      children: [
                        _buildTile("Diagnosis Master", "Clinical conditions list", Icons.local_hospital, Colors.red, () => _navigateTo(const DiagnosisListPage())),
                        _buildTile("Lab Investigations", "Tests and biomarkers", Icons.science, Colors.blue, () => _navigateTo(const InvestigationMasterScreen())),
                        _buildTile("Supplementation", "Vitamins and minerals", Icons.medication, Colors.green, () => _navigateTo(const SupplementationMasterScreen())),
                        _buildTile("Disease Management", "Chronic conditions master", Icons.healing, Colors.pink, () => _navigateTo(const DiseaseMasterListScreen())),
                        _buildTile("Daily Habits", "Lifestyle tracking habits", Icons.check_circle_outline, Theme.of(context).colorScheme.primary, () => _navigateTo(const HabitMasterScreen())),
                      ],
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- WIDGET HELPERS ---

  Widget _buildHeader() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 20,
            bottom: 20,
            left: 20,
            right: 20,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1))),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                  ),
                  child: const Icon(Icons.arrow_back, size: 20, color: Colors.black87),
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Master Setup", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A))),
                    Text("Configure system-wide data", style: TextStyle(fontSize: 13, color: Colors.grey)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(.1), shape: BoxShape.circle),
                child: Icon(Icons.settings, color: Theme.of(context).colorScheme.primary),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isExpanded,
    required ValueChanged<bool> onToggle,
    required List<Widget> children,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isExpanded ? color.withOpacity(0.15) : Colors.black.withOpacity(0.03),
            blurRadius: isExpanded ? 20 : 10,
            offset: const Offset(0, 5),
          )
        ],
        border: Border.all(color: isExpanded ? color.withOpacity(0.3) : Colors.transparent),
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () => onToggle(!isExpanded),
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(20),
              bottom: Radius.circular(isExpanded ? 0 : 20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
                        Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ),
          ),

          // Children
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: isExpanded
                ? Column(
              children: [
                Divider(height: 1, color: Colors.grey.shade100, indent: 20, endIndent: 20),
                const SizedBox(height: 8),
                ...children,
                const SizedBox(height: 16),
              ],
            )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildTile(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87)),
                  Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade300),
          ],
        ),
      ),
    );
  }
}