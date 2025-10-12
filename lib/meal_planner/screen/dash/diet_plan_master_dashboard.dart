import 'package:flutter/material.dart';
import 'package:nutricare_client_management/master_diet_planner/master_diet_plan_list%20screen.dart';
import 'package:nutricare_client_management/meal_planner/screen/diet_plan_category_list.dart';
import 'package:nutricare_client_management/meal_planner/screen/diet_plan_history_page.dart';
import 'package:nutricare_client_management/meal_planner/screen/food_category_list_page.dart';
import 'package:nutricare_client_management/meal_planner/screen/food_item_list_page.dart';
import 'package:nutricare_client_management/meal_planner/screen/guideline_list_page.dart';
import 'package:nutricare_client_management/meal_planner/screen/master_diet_plan_entry_page.dart';
import 'package:nutricare_client_management/meal_planner/screen/master_diet_plan_list_page.dart';
import 'package:nutricare_client_management/meal_planner/screen/serving_unit_list_page.dart';
import 'package:nutricare_client_management/meal_planner/service/food_item_service.dart';

// 🎯 Placeholder Screens - You will replace these with your actual form pages
class PlaceholderFormPage extends StatelessWidget {
  final String title;
  const PlaceholderFormPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          'This is the entry form for: $title',
          style: const TextStyle(fontSize: 18, color: Colors.blueGrey),
        ),
      ),
    );
  }
}

// --- The Master Dashboard Page ---
class DietPlanMasterPage extends StatelessWidget {
  const DietPlanMasterPage({super.key});

  // Helper method to navigate
  void _navigateToModule(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (c) => page));
  }

  // Helper method to build a beautiful list item
  Widget _buildMasterCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Widget targetPage,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Card(
        // Beautiful UI: Raised card with soft rounded corners
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: InkWell( // Provides the beautiful ripple effect on tap
          borderRadius: BorderRadius.circular(10),
          onTap: () => _navigateToModule(context, targetPage),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            // Prominent, colored icon area
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 28,
              ),
            ),
            title: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                subtitle,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diet Plan Master Setup'),
        backgroundColor: Colors.teal, // Calming color for nutrition
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.only(bottom: 20.0),
            child: Text(
              'Food Categories',
              style: TextStyle(fontSize: 15, color: Colors.grey),
            ),
          ),

          // 1. Diet Templates Master
          _buildMasterCard(
            context: context,
            title: 'Serving units',
            subtitle: 'Create standard, reusable diet plans (e.g., Keto, Vegan, Maintenance).',
            icon: Icons.restaurant_menu,
            iconColor: Colors.green.shade600,
            targetPage: const ServingUnitListPage(),
          ),

          // 2. Meal Items Master
          _buildMasterCard(
            context: context,
            title: 'Food Categories',
            subtitle: 'Manage common ingredients and basic single-item meal entries.',
            icon: Icons.dinner_dining,
            iconColor: Colors.amber.shade700,
            targetPage: const FoodCategoryListPage()),

          // 3. Recipe & Prep Master
          _buildMasterCard(
            context: context,
            title: 'Diet Plan categories',
            subtitle: 'Define detailed cooking recipes with steps and nutritional info.',
            icon: Icons.book_online,
            iconColor: Colors.red.shade400,
            targetPage: const DietPlanCategoryListPage(),
          ),

          // 4. Exclusion Master
          _buildMasterCard(
            context: context,
            title: 'Master food items',
            subtitle: 'Manage a global list of allergens, intolerances, and foods to avoid.',
            icon: Icons.no_food,
            iconColor: Colors.blueGrey.shade700,
            targetPage: const FoodItemListPage(),
          ),

          _buildMasterCard(
            context: context,
            title: 'Guidelines',
            subtitle: 'Manage a global list of allergens, intolerances, and foods to avoid.',
            icon: Icons.no_food,
            iconColor: Colors.blueGrey.shade700,
            targetPage: const GuidelineListPage(),
          ),
          _buildMasterCard(
            context: context,
            title: 'Master meal routine',
            subtitle: 'Manage a global list of allergens, intolerances, and foods to avoid.',
            icon: Icons.no_food,
            iconColor: Colors.blueGrey.shade700,
            targetPage: const PlaceholderFormPage(title: 'Exclusion Entry'),
          ),
          _buildMasterCard(
            context: context,
            title: 'Master meal plan',
            subtitle: 'Manage a global list of allergens, intolerances, and foods to avoid.',
            icon: Icons.no_food,
            iconColor: Colors.blueGrey.shade700,
            targetPage: const MasterDietPlanEntryPage_old(),
          ),

          _buildMasterCard(
            context: context,
            title: 'Master meal plan history',
            subtitle: 'Manage a global list of allergens, intolerances, and foods to avoid.',
            icon: Icons.no_food,
            iconColor: Colors.blueGrey.shade700,
            targetPage: const MasterDietPlanListScreen(),
          ),

        ],
      ),
    );
  }
}