// lib/admin/plan_clinical_report.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nutricare_client_management/admin/admin_profile_model.dart';
import 'package:nutricare_client_management/admin/company_profile_model.dart';
import 'package:nutricare_client_management/master/model/diet_plan_item_model.dart';
import 'package:nutricare_client_management/modules/client/model/client_diet_plan_model.dart';
import 'package:nutricare_client_management/modules/client/model/client_model.dart';
import 'package:nutricare_client_management/modules/client/model/vitals_model.dart';

class PlanClinicalReport extends StatelessWidget {
  final ClientDietPlanModel plan;
  final ClientModel? client;
  final VitalsModel? vitals;
  final CompanyProfileModel? company;
  final AdminProfileModel? doctor;
  final List<String> resolvedInvestigations;
  final List<String> resolvedGuidelines;
  final List<String> resolvedHabits; // 🎯 Added
  final Map<String, String> resolvedSupplements;
  const PlanClinicalReport({

    super.key,
    required this.resolvedInvestigations,
    required this.resolvedGuidelines,
    required this.resolvedHabits,
    required this.resolvedSupplements,
    required this.plan,
    this.client,
    this.vitals,
    this.company,
    this.doctor,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailedHeader(),
          const SizedBox(height: 12),
          _buildPatientBrief(), // 🎯 NEW: Premium Patient Banner
          const Divider(height: 48, thickness: 1.5, color: Colors.indigo),

          if (plan.isProvisional) _buildProvisionalBadge(),

          _buildPremiumSection(
            title: "CLINICAL ASSESSMENT",
            icon: Icons.assignment_ind,
            child: _buildClinicalProfile(),
          ),

          _buildPremiumSection(
            title: "LIFESTYLE GOALS & HABITS",
            icon: Icons.auto_graph,
            child: Column(
              children: [
                _buildLifestyleGoalsGrid(),
                if (resolvedHabits.isNotEmpty) _buildHabitChips(),
              ],
            ),
          ),

          _buildPremiumSection(
            title: "TREATMENT INTERVENTIONS",
            icon: Icons.medication_liquid,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (resolvedInvestigations.isNotEmpty)
                  _buildInterventionRow("Requested Investigations", resolvedInvestigations.join(', '), Icons.biotech),
                _buildInterventionSection("Supplementation Strategy", resolvedSupplements),
                _buildInterventionSection("Clinical Guidelines", resolvedGuidelines),
              ],
            ),
          ),

          const SizedBox(height: 16),
          _buildSectionHeader("CUSTOMIZED NUTRITION SCHEDULE"),
          _buildMealSchedule(), // 🎯 Standard diet grid remains robust

          const SizedBox(height: 40),
          _buildDisclaimerSection(),
          const SizedBox(height: 40),
          _buildPractitionerSignature(),
          const SizedBox(height: 32),
          _buildFooter(),
        ],
      ),
    );
  }
  Widget _buildPatientBrief() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _briefItem("PATIENT", client?.name ?? "N/A"),
          _briefItem("AGE/GENDER", "${client?.age ?? 'N/A'} / ${client?.gender ?? 'N/A'}"),
          _briefItem("ID", client?.id.substring(0, 8).toUpperCase() ?? "N/A"),
          _briefItem("DATE", DateFormat('dd/MM/yy').format(DateTime.now())),
        ],
      ),
    );
  }

  Widget _briefItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.indigo)),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87)),
      ],
    );
  }

  // --- 🎯 NEW: Reusable Premium Section Wrapper ---
  Widget _buildPremiumSection({required String title, required IconData icon, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: Colors.indigo),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.indigo, letterSpacing: 1.2)),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  // Update _buildInterventionRow for premium look
  Widget _buildInterventionRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: Colors.blueGrey),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(TextSpan(children: [
              TextSpan(text: "$label: ", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              TextSpan(text: value, style: const TextStyle(fontSize: 13)),
            ])),
          ),
        ],
      ),
    );
  }


  // --- 🎯 NEW: Detailed Header (Clinic Phone, Doctor Credentials) ---
// lib/admin/plan_clinical_report.dart

  Widget _buildDetailedHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Clinic Branding Section
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                company?.name?.toUpperCase() ?? "CLINIC NAME",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.indigo,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                company?.address ?? "Clinic Address Not Provided",
                style: const TextStyle(fontSize: 10, color: Colors.blueGrey, height: 1.3),
              ),
              if (company?.contactPhone != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.phone, size: 10, color: Colors.indigo),
                      const SizedBox(width: 4),
                      Text(
                        "Tel: ${company!.contactPhone}",
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        // Practitioner Credentials Section
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              doctor?.fullName ?? "Practitioner",
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 2),
            Text(
              "${doctor?.designation ?? ''} | ${doctor?.qualifications?.join(', ') ?? ''}",
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.indigo),
            ),
            if (doctor?.regdNo != null && doctor!.regdNo!.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  "Reg No: ${doctor!.regdNo}",
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    color: Colors.indigo,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  // --- 🎯 NEW: Provisional Badge & Watermark ---
  Widget _buildProvisionalBadge() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(4)),
      child: const Text("PROVISIONAL REPORT - Subject to Clinical Review",
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.brown)),
    );
  }

  Widget _buildProvisionalWatermark() {
    return Positioned.fill(
      child: Center(
        child: Opacity(
          opacity: 0.05,
          child: Transform.rotate(
            angle: -0.5,
            child: const Text("PROVISIONAL",
                style: TextStyle(fontSize: 80, fontWeight: FontWeight.bold, color: Colors.black)),
          ),
        ),
      ),
    );
  }

  // --- 🎯 NEW: Practitioner Signature Block ---
  Widget _buildPractitionerSignature() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(width: 150, child: Divider(thickness: 1, color: Colors.black)),
        Text(doctor?.fullName ?? "", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        Text(doctor?.designation ?? "", style: const TextStyle(fontSize: 10)),
        if (doctor?.regdNo != null)
          Text("Reg No: ${doctor!.regdNo}", style: const TextStyle(fontSize: 9, color: Colors.grey)),
      ],
    );
  }
  Widget _buildDisclaimerSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.02),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.1)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.gavel, size: 14, color: Colors.red),
              SizedBox(width: 8),
              Text("MEDICAL DISCLAIMER",
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red)),
            ],
          ),
          SizedBox(height: 6),
          Text(
            "This plan is a clinical recommendation based on your current health assessment and is intended for nutritional guidance only. It does not replace professional medical advice, diagnosis, or treatment. Always seek the advice of your physician regarding any medical condition. In case of an emergency, contact your local healthcare provider immediately.",
            style: TextStyle(fontSize: 10, color: Colors.black87, height: 1.4),
          ),
        ],
      ),
    );
  }
  // --- 🎯 NEW: Lifestyle Goals Grid (Water, Sleep, Steps, etc.) ---
  Widget _buildLifestyleGoalsGrid() {
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      children: [
        _goalTile("Activity Type", vitals?.activityType ?? "General Exercise", Icons.directions_run),
        //_goalTile("Daily Step Goal", "${vitals?. ?? '8000'}", Icons.shutter_speed),
        _goalTile("Water Intake", "${vitals?.waterIntake ?? '3'} Liters", Icons.water_drop),
        _goalTile("Sleep Pattern", vitals?.sleepQuality ?? "7-8 Hours", Icons.bedtime),
      ],
    );
  }

  Widget _goalTile(String label, String value, IconData icon) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.indigo.shade300),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey)),
                Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildHabitChips() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("DAILY HABITS TO DEVELOP",
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: resolvedHabits.map((habitName) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.teal.withOpacity(0.2)),
              ),
              child: Text(habitName, style: const TextStyle(fontSize: 11, color: Colors.teal, fontWeight: FontWeight.w600)),
            )).toList(),
          ),
        ],
      ),
    );
  }
  // --- 🎯 NEW: Habits Section ---
  Widget _buildHabitSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("DAILY HABITS TO DEVELOP",
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: plan.assignedHabitIds.map((habit) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.teal.withOpacity(0.2)),
              ),
              child: Text(habit, style: const TextStyle(fontSize: 11, color: Colors.teal)),
            )).toList(),
          ),
        ],
      ),
    );
  }

  // --- 🎯 NEW: Intervention Section (Supplements/Guidelines) ---
  Widget _buildInterventionSection(String title, dynamic data) {
    List<String> items = [];
    if (data is Map) {
      data.forEach((k, v) => items.add("$k: $v"));
    } else if (data is List) {
      items = List<String>.from(data);
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
          const SizedBox(height: 4),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text("• $item", style: const TextStyle(fontSize: 13, height: 1.4)),
          )),
        ],
      ),
    );
  }
  // --- UI Helpers ---


  // ... (Keep existing _buildProfessionalHeader, _buildClinicalProfile, _buildVitalsGrid, _buildMealSchedule, _buildFooter) ...

  Widget _buildProfessionalHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(company?.name?.toUpperCase() ?? "CLINIC NAME",
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.indigo)),
        Text(doctor?.fullName ?? "Practitioner Name",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(company?.address ?? "Address Not Provided",
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildSectionHeader(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.indigo, letterSpacing: 1.1)),
  );

  Widget _buildInfoRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text.rich(TextSpan(children: [
      TextSpan(text: "$label: ", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      TextSpan(text: value.isEmpty ? "N/A" : value, style: const TextStyle(fontSize: 13)),
    ])),
  );

// lib/admin/plan_clinical_report.dart

  Widget _buildClinicalProfile() {
    final bool isFemale = client?.gender?.toLowerCase() == 'female';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.indigo.shade100),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Primary Vitals Row
          Row(
            children: [
              _vitalItem("WEIGHT", "${vitals?.weightKg ?? '--'} kg"),
              _vitalItem("HEIGHT", "${vitals?.heightCm ?? '--'} cm"),
              _vitalItem("BMI", "${vitals?.bmi ?? '--'}", isBold: true),
              _vitalItem("IBW", "${vitals?.idealBodyWeightKg ?? '--'} kg"),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          // Secondary Markers Row
          Row(
            children: [
              _vitalItem("BLOOD PRESSURE", "${vitals?.bloodPressureSystolic} / ${vitals?.bloodPressureSystolic}"  ?? "Normal"),
              _vitalItem("FOOD HABIT", vitals?.foodHabit ?? "Not Set"),
              _vitalItem("ACTIVITY", vitals?.activityType ?? "Sedentary"),
              if (isFemale) _vitalItem("MENSTRUAL STATUS", vitals?.menstrualStatus ?? "Regular"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _vitalItem(String label, String value, {bool isBold = false}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade700)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
                fontSize: 12,
                fontWeight: isBold ? FontWeight.w900 : FontWeight.w600,
                color: isBold ? Colors.indigo : Colors.black87
            ),
          ),
        ],
      ),
    );
  }

  String _formatMap(Map<String, String>? data) {
    if (data == null || data.isEmpty) return 'None';
    return data.entries.map((e) => "${e.key}: ${e.value}").join(', ');
  }

  Widget _buildMealSchedule() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: plan.days.length,
      itemBuilder: (context, index) {
        final day = plan.days[index];
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
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.grey.shade50,
            child: Text("${dayName.toUpperCase()} • ${meal.mealName.toUpperCase()}",
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.indigo)),
          ),
          ...meal.items.map((item) => ListTile(
            title: Text(item.foodItemName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Qty: ${item.quantity} ${item.unit}", style: const TextStyle(fontSize: 12)),
                if (item.alternatives.isNotEmpty)
                  ...item.alternatives.map((alt) => Text("OR: ${alt.foodItemName} (${alt.quantity} ${alt.unit})",
                      style: const TextStyle(fontSize: 11, color: Colors.teal, fontStyle: FontStyle.italic))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildFooter() => Center(
    child: Text("Generated on ${DateFormat('dd MMM yyyy').format(DateTime.now())} • Powered by LabVital",
        style: const TextStyle(fontSize: 9, color: Colors.grey)),
  );
}