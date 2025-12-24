// lib/admin/plan_document_component.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nutricare_client_management/admin/admin_profile_model.dart';
import 'package:nutricare_client_management/admin/company_profile_model.dart';
import 'package:nutricare_client_management/master/model/diet_plan_item_model.dart';
import 'package:nutricare_client_management/modules/client/model/client_diet_plan_model.dart';
import 'package:nutricare_client_management/modules/client/model/client_model.dart';
import 'package:nutricare_client_management/modules/client/model/vitals_model.dart';

class PlanDocumentComponent extends StatelessWidget {
  final ClientDietPlanModel plan;
  final ClientModel? client;
  final AdminProfileModel? doctor;
  final CompanyProfileModel? company;
  final VitalsModel? vitals; // 🎯 Ensure vitals is passed

  const PlanDocumentComponent({
    super.key,
    required this.plan,
    this.client,
    this.doctor,
    this.company,
    this.vitals,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProfessionalHeader(), // 🎯 Photo removed
        const Divider(height: 30, thickness: 1.5),

        // 1. Patient clinical information
        _buildSectionHeader("CLINICAL ASSESSMENT & HISTORY"),
        _buildClinicalProfile(),
        const SizedBox(height: 24),

        // 2. Lifestyle & Habits
        _buildSectionHeader("LIFESTYLE & BEHAVIORAL DATA"),
        _buildLifestyleHabits(),
        const SizedBox(height: 24),

        // 3. Anthropometric & Vitals Profile (From Vitals Model)
        _buildSectionHeader("ANTHROPOMETRICS & LAB PROFILE"),
        _buildAnthropometricsGrid(),
        const SizedBox(height: 32),

        // 4. Meal Schedule
        _buildSectionHeader("CUSTOMIZED NUTRITION SCHEDULE"),
        _buildMealSchedule(),

        const SizedBox(height: 50),
        _buildFooter(),
      ],
    );
  }

  // --- Professional Text-Only Header ---
  Widget _buildProfessionalHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(company?.name?.toUpperCase() ?? "LABVITAL CLINIC",
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.indigo, letterSpacing: 1.2)),
        const SizedBox(height: 4),
        Text(doctor?.fullName ?? "Practitioner Name",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(company?.address ?? "Clinic Location",
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }

  // --- Clinical Profile (Complaints, Diagnosis, History, Medications) ---
  // lib/admin/plan_document_component.dart

  // --- Clinical Profile (Complaints, Diagnosis, History, Medications, Allergies) ---
// lib/admin/plan_document_component.dart

  Widget _buildClinicalProfile() {
    // 🎯 Helper to convert Map<String, String> to a readable string
    String formatMedications(Map<String, String>? meds) {
      if (meds == null || meds.isEmpty) return 'None';
      return meds.entries
          .map((e) => "${e.key} (${e.value})")
          .join(', ');
    }

    // 🎯 Helper for Food Allergies List
    String formatAllergies(List<String>? allergies) {
      if (allergies == null || allergies.isEmpty) return 'None';
      return allergies.join(', ');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoRow("Chief Complaints", plan.complaints),
        _infoRow("Diagnosis", plan.diagnosisIds.join(', ')),
        _infoRow("Clinical History", plan.clinicalNotes),

        // 🎯 FIX: Use the formatter for the Medications Map
        _infoRow(
            "Existing Medications",
            formatMedications(vitals?.prescribedMedications)
        ),

        // 🎯 FIX: Use the formatter for the Allergies List
        _infoRow(
            "Food Allergies",
            formatAllergies(vitals?.foodAllergies)
        ),
      ],
    );
  }
  // --- Lifestyle Habits Section ---
// lib/admin/plan_document_component.dart

  // --- Lifestyle Habits Section ---
  Widget _buildLifestyleHabits() {
    // 🎯 Helper to format Maps (Caffeine, Water, etc.) into a String
    String formatMap(Map<String, String>? data) {
      if (data == null || data.isEmpty) return 'None';
      return data.entries
          .map((e) => "${e.key}: ${e.value}")
          .join(', ');
    }

    return Wrap(
      spacing: 24,
      runSpacing: 12,
      children: [
        _habitItem("Water Intake", "${plan.dailyWaterGoal}L/Day", Icons.water_drop),
        _habitItem("Activity Level", vitals?.activityType ?? 'N/A', Icons.bolt),
        _habitItem("Sleep Quality", vitals?.sleepQuality ?? 'N/A', Icons.bedtime),

        // 🎯 FIX: Convert int stressLevel to String
        _habitItem(
            "Stress Level",
            vitals?.stressLevel?.toString() ?? 'N/A',
            Icons.psychology
        ),

        // 🎯 FIX: Format caffeineIntake Map to String
        _habitItem(
            "Caffeine",
            formatMap(vitals?.caffeineIntake),
            Icons.coffee
        ),

        _habitItem("Menstrual Status", vitals?.menstrualStatus ?? 'N/A', Icons.female),
      ],
    );
  }

  // --- Helper for Habit Items ---
  Widget _habitItem(String label, String value, IconData icon) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16, color: Colors.teal),
      const SizedBox(width: 8),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          // 🎯 Added ConstrainedBox to prevent text overflow for long map strings
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 150),
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    ],
  );

  // --- Anthropometrics Grid (Weight, IBW, BMI, BP, etc.) ---
  Widget _buildAnthropometricsGrid() {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 3,
      childAspectRatio: 2.5,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _vitalTile("Weight", "${vitals?.weightKg ?? '--'} kg"),
        _vitalTile("Height", "${vitals?.heightCm ?? '--'} cm"),
        _vitalTile("BMI", vitals?.bmi?.toStringAsFixed(1) ?? '--'),
        _vitalTile("Waist", "${vitals?.waistCm ?? '--'} cm"),
        _vitalTile("Hip", "${vitals?.hipCm ?? '--'} cm"),
        _vitalTile("IBW (Ideal)", "${vitals?.idealBodyWeightKg ?? '--'} kg"),
        _vitalTile("Blood Pressure", "${vitals?.bloodPressureSystolic ?? '--'}/${vitals?.bloodPressureDiastolic ?? '--'}"),
        _vitalTile("Heart Rate", "${vitals?.heartRate ?? '--'} bpm"),
      ],
    );
  }

  // --- Sorted Meal Schedule ---
  Widget _buildMealSchedule() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: plan.days.length,
      itemBuilder: (context, index) {
        final day = plan.days[index];
        // 🎯 Sort meals by order flag
        final sortedMeals = List<DietPlanMealModel>.from(day.meals)
          ..sort((a, b) => a.order.compareTo(b.order));

        return Column(
          children: sortedMeals.map((meal) {
            if (meal.items.isEmpty) return const SizedBox.shrink();
            return _buildMealBlock(day.dayName, meal);
          }).toList(),
        );
      },
    );
  }

  Widget _buildMealBlock(String dayName, DietPlanMealModel meal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: const BorderRadius.vertical(top: Radius.circular(12))),
            child: Row(
              children: [
                Text(dayName.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.indigo)),
                const Text(" • "),
                Text(meal.mealName.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
              ],
            ),
          ),
          ...meal.items.map((item) => _buildFoodItemRow(item)),
        ],
      ),
    );
  }

  Widget _buildFoodItemRow(DietPlanItemModel item) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.foodItemName, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text("Qty: ${item.quantity} ${item.unit}", style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
          // 🎯 Display alternative food quantities
          if (item.alternatives.isNotEmpty)
            ...item.alternatives.map((alt) => Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text("OR: ${alt.foodItemName} (${alt.quantity} ${alt.unit})",
                  style: const TextStyle(fontSize: 12, color: Colors.teal, fontStyle: FontStyle.italic)),
            )),
        ],
      ),
    );
  }

  // --- Helper Methods ---
  Widget _buildSectionHeader(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 12, top: 8),
    child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.indigo, letterSpacing: 1.1)),
  );

  Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text.rich(TextSpan(children: [
      TextSpan(text: "$label: ", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      TextSpan(text: value.isEmpty ? "N/A" : value, style: const TextStyle(fontSize: 13)),
    ])),
  );


  Widget _vitalTile(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 10, color: Colors.blueGrey)),
      Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
    ],
  );

  Widget _buildFooter() => Center(
    child: Text("Generated on ${DateFormat('dd MMM yyyy').format(DateTime.now())} • Powered by LabVital EHR",
        style: const TextStyle(fontSize: 10, color: Colors.grey)),
  );
}