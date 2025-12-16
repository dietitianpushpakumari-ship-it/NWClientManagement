import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:nutricare_client_management/master/screen/food_category_list_page.dart';
import 'package:nutricare_client_management/master/screen/food_item_list_page.dart';
import 'package:nutricare_client_management/master/screen/master_meal_name_list_page.dart';
import 'package:nutricare_client_management/master/screen/serving_unit_list_page.dart';

import '../../../master_diet_planner/diet_plan_category_list_page.dart';

class DietPlanMasterPage extends StatelessWidget {
  const DietPlanMasterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: Stack(
        children: [
          Positioned(top: -100, right: -100, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.teal.withOpacity(0.1), blurRadius: 80, spreadRadius: 30)]))),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, "Diet Plan Builder"),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    padding: const EdgeInsets.all(20),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.1,
                    children: [
                      // 🎯 GOAL CATEGORIES CARD
                      _buildCard(context, "Plan Categories", Icons.flag_circle, Colors.blueAccent, const DietPlanCategoryListPage()),

                      _buildCard(context, "Food Items", Icons.lunch_dining, Colors.orange, const FoodItemListPage()),
                      _buildCard(context, "Food Categories", Icons.category, Colors.green, const FoodCategoryListPage()),
                      _buildCard(context, "Meal Names", Icons.access_time, Colors.blue, const MasterMealNameListPage()),
                      _buildCard(context, "Serving Units", Icons.scale, Colors.teal, const ServingUnitListPage()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, String title, IconData icon, Color color, Widget page) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))]),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 28)),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Row(
        children: [
          GestureDetector(onTap: () => Navigator.pop(context), child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]), child: const Icon(Icons.arrow_back, size: 20))),
          const SizedBox(width: 16),
          Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
        ],
      ),
    );
  }
}