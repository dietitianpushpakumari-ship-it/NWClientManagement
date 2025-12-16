// lib/screens/dash/master_Setup_page.dart

import 'package:flutter/material.dart';
import 'package:nutricare_client_management/admin/labvital/lab_test_config_list_screen.dart';
import 'package:nutricare_client_management/master/model/master_constants.dart';
import 'package:nutricare_client_management/admin/master_sub_module_screen.dart';
import 'package:nutricare_client_management/admin/company_profile_master_screen.dart';
import 'dart:ui';
import 'package:nutricare_client_management/admin/master_data_uploader_screen.dart';
import 'package:nutricare_client_management/modules/master/screen/master_diet_plan_list_screen.dart';
import 'package:nutricare_client_management/screens/package_list_page.dart';

class MasterModule {
  final String title;
  final Color color;
  final List<Map<String, dynamic>> masters;
  const MasterModule({required this.title, required this.color, required this.masters});
}

// Data definition (Retained structure, only Clinical Masters modified)
final List<MasterModule> _masterModules = const [
  // 1. PACKAGE MANAGEMENT MODULE
  MasterModule(
    title: 'Plan & Package Masters',
    color: Colors.teal,
    masters: [
      {
        'title': 'Package Master',
        'entity': MasterEntity.entity_packages,
        'icon': Icons.card_giftcard,
        'color': Colors.teal,
      },
      {
        'title': 'Program Feature Master',
        'entity': MasterEntity.entity_packagefeature,
        'icon': Icons.featured_play_list,
        'color': Colors.teal,
      },
      {
        'title': 'Package Inclusions',
        'entity': MasterEntity.entity_packageInclusion,
        'icon': Icons.check_circle_outline,
        'color': Colors.teal,
      },
      {
        'title': 'Package Categories',
        'entity': MasterEntity.entity_packageCategory,
        'icon': Icons.category_sharp,
        'color': Colors.teal,
      },
      {
        'title': 'Target Conditions',
        'entity': MasterEntity.entity_packageTargetCondition,
        'icon': Icons.medical_information,
        'color': Colors.teal,
      },
    ],
  ),

  // 2. DIET PLAN MODULE
  MasterModule(
    title: 'Diet Plan Masters',
    color: Colors.indigo,
    masters: [
      {
        'title': 'Master Diet Plans',
        'entity': 'NAV_MASTER_DIET_PLANS',
        'icon': Icons.restaurant_menu,
        'color': Colors.indigo,
      },
      {
        'title': 'Diet Plan Categories',
        'entity': MasterEntity.entity_DietPlanCategories,
        'icon': Icons.category,
        'color': Colors.indigo,
      },
      {
        'title': 'Meal Names',
        'entity': MasterEntity.entity_MealNames,
        'icon': Icons.access_time,
        'color': Colors.indigo,
      },
      {
        'title': 'Serving Units',
        'entity': MasterEntity.entity_ServingUnits,
        'icon': Icons.line_weight,
        'color': Colors.indigo,
      },
      {
        'title': 'Guidelines',
        'entity': MasterEntity.entity_Guidelines,
        'icon': Icons.list_alt,
        'color': Colors.indigo,
      },
    ],
  ),

  // 3. FOOD/RECIPE MASTERS
  MasterModule(
    title: 'Food & Recipe Masters',
    color: Colors.orange,
    masters: [
      {
        'title': 'Food Item Master',
        'entity': MasterEntity.entity_FoodItem,
        'icon': Icons.fastfood,
        'color': Colors.orange,
      },
      {
        'title': 'Food Category Master',
        'entity': MasterEntity.entity_FoodCategory,
        'icon': Icons.category,
        'color': Colors.orange,
      },
    ],
  ),

  // 4. CLINICAL MASTERS (Lab Config added here)
  MasterModule(
    title: 'Clinical & Health Masters',
    color: Colors.blue,
    masters: [
      // 🎯 NEW: Lab Configuration Master Screen
      {
        'title': 'Lab Configuration',
        'entity': 'NAV_LAB_CONFIG', // Custom navigation key
        'icon': Icons.settings,
        'color': Colors.redAccent, // Distinct color for config
      },
      {
        'title': 'Diagnosis Master',
        'entity': MasterEntity.entity_Diagnosis,
        'icon': Icons.local_hospital,
        'color': Colors.blue,
      },
      {
        'title': 'Disease Master',
        'entity': MasterEntity.entity_disease,
        'icon': Icons.medical_services,
        'color': Colors.blue,
      },
      {
        'title': 'Investigation Master',
        'entity': MasterEntity.entity_Investigation,
        'icon': Icons.science,
        'color': Colors.blue,
      },
      {
        'title': 'Supplement Master',
        'entity': MasterEntity.entity_supplement,
        'icon': Icons.add_box,
        'color': Colors.blue,
      },
      {
        'title': 'Lifestyle Habit Master',
        'entity': MasterEntity.entity_LifestyleHabit,
        'icon': Icons.self_improvement,
        'color': Colors.blue,
      },
      {
        'title': 'Clinical Notes Structure',
        'entity': MasterEntity.entity_Clinicalnotes,
        'icon': Icons.notes,
        'color': Colors.blue,
      },
      {
        'title': 'Clinical Complaints',
        'entity': MasterEntity.entity_Complaint,
        'icon': Icons.psychology,
        'color': Colors.blue,
      },
      {
        'title': 'Food Allergies',
        'entity': MasterEntity.entity_allergy,
        'icon': Icons.warning_amber,
        'color': Colors.blue,
      },
      {
        'title': 'GI Symptoms',
        'entity': MasterEntity.entity_giSymptom,
        'icon': Icons.sick,
        'color': Colors.blue,
      },
    ],
  ),

  // 5. Simple Dropdown Masters
  MasterModule(
    title: 'Simple Dropdown Masters',
    color: Colors.deepPurple,
    masters: [
      {
        'title': 'Develop Habits',
        'entity': MasterEntity.entity_develop_habits,
        'icon': Icons.star_rate,
        'color': Colors.deepPurple,
      },
      {
        'title': 'Water Intake Options',
        'entity': MasterEntity.entity_waterIntake,
        'icon': Icons.local_drink,
        'color': Colors.deepPurple,
      },
      {
        'title': 'Caffeine Source',
        'entity': MasterEntity.entity_caffeineSource,
        'icon': Icons.coffee,
        'color': Colors.deepPurple,
      },
      {
        'title': 'Activity Levels',
        'entity': MasterEntity.entity_ActivityLevels,
        'icon': Icons.directions_run,
        'color': Colors.deepPurple,
      },
      {
        'title': 'Sleep Quality',
        'entity': MasterEntity.entity_SleepQuality,
        'icon': Icons.bed,
        'color': Colors.deepPurple,
      },
      {
        'title': 'Menstrual Status',
        'entity': MasterEntity.entity_MenstrualStatus,
        'icon': Icons.female,
        'color': Colors.deepPurple,
      },
      {
        'title': 'Food Habits Options',
        'entity': MasterEntity.entity_foodHabitsOptions,
        'icon': Icons.favorite,
        'color': Colors.deepPurple,
      },
    ],
  ),
];


class MasterSetupPage extends StatelessWidget {
  const MasterSetupPage({super.key});

  Widget _buildCustomHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 10, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1A1A1A), size: 20),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
                'Master Data Setup',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A)
                )
            ),
          ),
          const Icon(Icons.tune, color: Colors.indigo, size: 30),
        ],
      ),
    );
  }

  // NEW: Reusable widget to build an individual master item card inside the ExpansionTile
  Widget _buildMasterItem(BuildContext context, Map<String, dynamic> master, Color moduleColor) {
    // Determine target screen based on entity type
    Widget targetScreen;
    if (master['entity'] == 'NAV_MASTER_DIET_PLANS') {
      targetScreen = const MasterDietPlanListScreen();
    } else if (master['entity'] == MasterEntity.entity_packages) {
      targetScreen = const PackageListPage();
      // 🎯 NEW NAVIGATION LOGIC
    } else if (master['entity'] == 'NAV_LAB_CONFIG') {
      targetScreen = const LabTestConfigListScreen();
    } else {
      // Fallback for generic master data screens
      targetScreen = MasterDataSubModuleScreen(
        moduleTitle: master['title'] as String,
        masters: [master],
        color: moduleColor,
      );
    }

    final color = master['color'] as Color? ?? moduleColor;
    final title = master['title'] as String;
    final icon = master['icon'] as IconData;

    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => targetScreen));
      },
      child: Card(
        color: color.withOpacity(0.05), // Lighter background than the module card itself
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  // NEW: Function to create an ExpansionTile for a module
  Widget _buildModuleGroup(BuildContext context, MasterModule module) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Theme( // Use a distinct Theme for the ExpansionTile border/color
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false, // Start collapsed
          collapsedIconColor: module.color,
          iconColor: module.color,
          backgroundColor: Colors.white, // Ensure tile background is white
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          title: Text(
            module.title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: module.color,
            ),
          ),
          children: module.masters.map((master) {
            // Pass the module's color for consistent styling of the sub-items
            return _buildMasterItem(context, master, module.color);
          }).toList(),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildCustomHeader(context),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [

                  // Dedicated tiles (remain outside the expansion logic)
                  const CompanyProfileTile(),
                  const SizedBox(height: 20),
                  const MasterUploaderTile(),
                  const SizedBox(height: 20),

                  // Existing master modules (Now using ExpansionTile structure)
                  ..._masterModules.map((module) => _buildModuleGroup(context, module)).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// Tile for the Company Profile (Singleton) (Retained)
class CompanyProfileTile extends StatelessWidget {
  const CompanyProfileTile({super.key});

  @override
  Widget build(BuildContext context) {
    const color = Colors.blueGrey;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Company Profile Master',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const Divider(),
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CompanyProfileMasterScreen(),
              ),
            );
          },
          child: Card(
            color: color.withOpacity(0.1),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.business_center, color: color),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Manage Your Company Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Tile for the Master Data Uploader (Singleton Utility) (Retained)
class MasterUploaderTile extends StatelessWidget {
  const MasterUploaderTile({super.key});

  @override
  Widget build(BuildContext context) {
    const color = Colors.purple;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Data Utility Tools',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const Divider(),
        InkWell(
          onTap: () {
            // DIRECT NAVIGATION to the Master Data Uploader screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const MasterDataUploaderScreen(),
              ),
            );
          },
          child: Card(
            color: color.withOpacity(0.1),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.upload_file, color: color),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Bulk Data Uploader',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}