import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nutricare_client_management/admin/admin_profile_model.dart';
import 'package:nutricare_client_management/admin/company_profile_model.dart';
import 'package:nutricare_client_management/modules/client/model/client_diet_plan_model.dart';
import 'package:nutricare_client_management/modules/client/model/client_model.dart';
import 'package:nutricare_client_management/modules/client/model/vitals_model.dart';

class PlanClinicalReport extends StatelessWidget {
  final ClientDietPlanModel plan;
  final ClientModel? client;
  final VitalsModel? vitals;
  final CompanyProfileModel? company;
  final AdminProfileModel? doctor;

  // Kept for compatibility, but logic primarily uses 'vitals' to match PDF
  final List<String> resolvedInvestigations;
  final List<String> resolvedGuidelines;
  final List<String> resolvedHabits;
  final Map<String, String> resolvedSupplements;

  const PlanClinicalReport({
    super.key,
    required this.plan,
    this.client,
    this.vitals,
    this.company,
    this.doctor,
    this.resolvedInvestigations = const [],
    this.resolvedGuidelines = const [],
    this.resolvedHabits = const [],
    this.resolvedSupplements = const {},
  });

  // --- LOGIC: SMART FORMATTER (Matched with PDF Generator) ---
  static String _smartFormat(Map<String, String>? map) {
    if (map == null || map.isEmpty) return "-";

    return map.entries.map((e) {
      final key = e.key.trim();
      final value = e.value.trim();

      if (value.toLowerCase() == "not specified" || value.isEmpty || value == "-") {
        return key;
      }
      return "$key - $value";
    }).join(", ");
  }

  @override
  Widget build(BuildContext context) {
    // Fonts Styles mirroring PDF styles
    final headerStyle = TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.indigo.shade900);
    final subHeaderStyle = const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.indigo, letterSpacing: 1.1);
    final bodyStyle = const TextStyle(fontSize: 11, color: Colors.black87, height: 1.4);
    final smallStyle = TextStyle(fontSize: 10, color: Colors.grey.shade700);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🎯 PROVISIONAL BANNER
          if (plan.isProvisional)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(4)),
              child: Text(
                "PROVISIONAL DIET PLAN (DRAFT) - NOT FINALIZED",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.orange.shade900),
                textAlign: TextAlign.center,
              ),
            ),

          // --- 1. HEADER & PATIENT INFO ---
          _buildHeader(headerStyle),
          const SizedBox(height: 20),
          _buildPatientBanner(),
          const Divider(height: 30, thickness: 0.5),

          // --- 2. CLINICAL & INTERVENTION (Split View) ---
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Col: Clinical Profile (Flex 5)
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("CLINICAL PROFILE", style: subHeaderStyle),
                    const SizedBox(height: 12),
                    _buildClinicalProfile(bodyStyle),
                  ],
                ),
              ),
              const SizedBox(width: 30),
              // Right Col: Intervention & Rx (Flex 4)
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("INTERVENTION & RX", style: subHeaderStyle),
                    const SizedBox(height: 12),
                    _buildInterventionSection(bodyStyle, smallStyle),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          // --- 3. DIET PLAN GRID ---
          _buildDietPlanHeader(),
          const SizedBox(height: 12),
          _buildDietPlanContent(),

          const SizedBox(height: 40),
          _buildFooter(smallStyle),
        ],
      ),
    );
  }

  // --- BUILDERS ---

  Widget _buildHeader(TextStyle headerStyle) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(company?.name?.toUpperCase() ?? "NUTRICARE", style: headerStyle),
              if (company?.address != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(company!.address!, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(doctor?.fullName ?? "Doctor Name", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            Text(doctor?.designation ?? "", style: TextStyle(fontSize: 11, color: Colors.grey.shade800)),
            if (doctor?.regdNo != null)
              Text("Reg: ${doctor!.regdNo}", style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        )
      ],
    );
  }

  Widget _buildPatientBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("PATIENT: ${client?.name ?? 'Guest'} (${client?.age ?? '-'}y / ${client?.gender ?? '-'})",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          Text("DATE: ${DateFormat('dd MMM yyyy').format(DateTime.now())}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildClinicalProfile(TextStyle bodyStyle) {
    if (vitals == null) return Text("No clinical data available", style: bodyStyle);

    final diagnosis = _smartFormat(vitals!.nutritionDiagnoses);
    final complaints = _smartFormat(vitals!.clinicalComplaints);
    final history = _smartFormat(vitals!.medicalHistory);
    final investigations = (vitals!.labTestOrders.isNotEmpty)
        ? vitals!.labTestOrders.join(", ")
        : "-";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoRow("Diagnosis", diagnosis),
        _infoRow("Complaints", complaints),
        _infoRow("History", history),
        _infoRow("Investigation", investigations),
        const SizedBox(height: 12),
        Row(
          children: [
            _boxTag("BMI: ${vitals!.bmi.toStringAsFixed(1)}"),
            const SizedBox(width: 8),
            _boxTag("Weight: ${vitals!.weightKg}kg"),
            const SizedBox(width: 8),
            _boxTag("BP: ${vitals!.bloodPressureSystolic ?? '-'}/${vitals!.bloodPressureDiastolic ?? '-'}"),
          ],
        )
      ],
    );
  }

  Widget _buildInterventionSection(TextStyle bodyStyle, TextStyle smallStyle) {
    final List<Widget> items = [];

    // 1. Medications / Supplements
    if (vitals != null) {
      if (vitals!.medications.isNotEmpty) {
        items.addAll(vitals!.medications.map((m) {
          final List<String> parts = [];
          if (m.dosage.isNotEmpty) parts.add(m.dosage);
          if (m.frequency.isNotEmpty) parts.add(m.frequency);
          if (m.duration.isNotEmpty) parts.add(m.duration);
          if (m.instruction.isNotEmpty) parts.add(m.instruction);

          return _bulletPoint("${m.name}: ${parts.join(", ")}");
        }));
      } else if (vitals!.prescribedMedications.isNotEmpty) {
        items.add(Text(_smartFormat(vitals!.prescribedMedications), style: bodyStyle));
      } else {
        items.add(Text("No medication/supplements.", style: bodyStyle.copyWith(color: Colors.grey)));
      }
    }

    // 2. Guidelines
    if (vitals?.clinicalGuidelines != null && vitals!.clinicalGuidelines!.isNotEmpty) {
      items.add(const SizedBox(height: 12));
      items.add(const Text("GUIDELINES:", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.indigo)));
      items.add(const SizedBox(height: 4));

      vitals!.clinicalGuidelines!.entries.forEach((e) {
        String text;
        if (e.value == "Standard Protocol Advised" || e.value.isEmpty) {
          text = e.key;
        } else {
          text = "${e.key} - ${e.value}";
        }
        items.add(_bulletPoint(text));
      });
    }

    // 3. Follow Up
    if (vitals?.clinicalNotes != null && vitals!.clinicalNotes!['Next Review'] != null) {
      items.add(const SizedBox(height: 12));
      // 🎯 FIXED: Replaced 'style' with standard properties
      items.add(const Divider(color: Colors.grey, thickness: 0.5));
      items.add(Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          "FOLLOW UP: Review in ${vitals!.clinicalNotes!['Next Review']} ",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.red.shade900),
        ),
      ));
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: items);
  }

  // --- DIET PLAN ---

  Widget _buildDietPlanHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: plan.isProvisional ? Colors.orange.shade800 : Colors.indigo.shade900,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "NUTRITION PLAN: ${plan.name.toUpperCase()}",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
          ),
          if (plan.isProvisional) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
              child: Text("DRAFT", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange.shade900)),
            )
          ]
        ],
      ),
    );
  }

  Widget _buildDietPlanContent() {
    return Column(
      children: plan.days.map((day) {
        final activeMeals = day.meals.where((m) => m.items.isNotEmpty).toList();
        if (activeMeals.isEmpty) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Day Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                ),
                child: Text(day.dayName.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              // Meals Table
              ...activeMeals.map((meal) => Container(
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(meal.mealName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.indigo)),
                    const SizedBox(height: 6),
                    // Items
                    ...meal.items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Main Item
                          RichText(
                            text: TextSpan(
                              children: [
                                const TextSpan(text: "• ", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo, fontSize: 14)),
                                TextSpan(text: item.foodItemName, style: const TextStyle(color: Colors.black87, fontSize: 12)),
                                TextSpan(text: " (${item.quantity}${item.unit})", style: TextStyle(color: Colors.grey.shade700, fontSize: 11)),
                              ],
                            ),
                          ),
                          // Alternatives
                          if (item.alternatives.isNotEmpty)
                            ...item.alternatives.map((alt) => Padding(
                              padding: const EdgeInsets.only(left: 12, top: 2),
                              child: RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(text: "OR ", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade600, fontSize: 10)),
                                    TextSpan(text: alt.foodItemName, style: TextStyle(color: Colors.grey.shade800, fontSize: 11)),
                                    TextSpan(text: " (${alt.quantity}${alt.unit})", style: TextStyle(color: Colors.grey.shade600, fontSize: 10)),
                                  ],
                                ),
                              ),
                            )),
                        ],
                      ),
                    )),
                  ],
                ),
              )).toList(),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFooter(TextStyle smallStyle) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Generated by NutriCare", style: smallStyle),
            Column(
              children: [
                Container(width: 120, height: 1, color: Colors.black),
                const SizedBox(height: 4),
                Text("Signature", style: smallStyle),
              ],
            )
          ],
        ),
      ],
    );
  }

  // --- WIDGET HELPERS ---

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text("$label:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey.shade800)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12, height: 1.3))),
        ],
      ),
    );
  }

  Widget _bulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("• ", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo, fontSize: 14)),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12, height: 1.3))),
        ],
      ),
    );
  }

  Widget _boxTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }
}