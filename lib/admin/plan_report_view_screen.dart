import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutricare_client_management/admin/admin_profile_model.dart';
import 'package:nutricare_client_management/admin/admin_provider.dart';
import 'package:nutricare_client_management/admin/company_profile_master_screen.dart';
import 'package:nutricare_client_management/admin/habit_master_model.dart';
import 'package:nutricare_client_management/admin/labvital/global_service_provider.dart';
import 'package:nutricare_client_management/admin/plan_clinical_report.dart';
import 'package:nutricare_client_management/helper/diet_plan_pdf_generator.dart';
import 'package:nutricare_client_management/master/model/guidelines.dart';
import 'package:nutricare_client_management/modules/client/model/client_diet_plan_model.dart';
import 'package:nutricare_client_management/modules/client/model/client_model.dart';
import 'package:nutricare_client_management/modules/client/model/vitals_model.dart';
import 'dart:ui';

import 'package:nutricare_client_management/modules/client/screen/investigation_master_model.dart';
import 'package:nutricare_client_management/modules/client/screen/suppliment_master_model.dart';
import 'package:printing/printing.dart';

import '../master/model/diet_plan_item_model.dart';
final guidelineMasterProvider = StreamProvider<List<Guideline>>((ref) {
  return ref.watch(guidelineServiceProvider).streamAllActive();
});
final investigationMasterProvider = StreamProvider<List<InvestigationMasterModel>>((ref) {
  return ref.watch(investigationMasterServiceProvider).streamAllActive();
});
final supplementMasterProvider = StreamProvider<List<SupplimentMasterModel>>((ref) {
  return ref.watch(supplimentMasterServiceProvider).streamAllActive();
});
final habitMasterProvider = StreamProvider<List<HabitMasterModel>>((ref) {
  return ref.watch(habitMasterServiceProvider).streamActiveHabits();
});


class PlanReportViewScreen extends ConsumerWidget {
  final ClientModel? client;
  final ClientDietPlanModel plan;
  final VitalsModel? vitals;
  final bool isMasterPreview;

  const PlanReportViewScreen({
    super.key,
    this.client,
    required this.plan,
    this.vitals,
    this.isMasterPreview = true,
  });

// lib/modules/client/screen/plan_report_view_screen.dart

  @override
// lib/modules/client/screen/plan_report_view_screen.dart

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Watch the Providers (AsyncValue), NOT the Services directly
    final investigationsAsync = ref.watch(investigationMasterProvider);
    final guidelinesAsync = ref.watch(guidelineMasterProvider);
    final supplementsAsync = ref.watch(supplementMasterProvider);
    final habitsAsync = ref.watch(habitMasterProvider);

    final adminAsync = ref.watch(currentAdminProvider);
    final companyAsync = ref.watch(companyProfileProvider);

    // 2. Use a combined approach to avoid deep nesting
    final isLoading = investigationsAsync.isLoading ||
        guidelinesAsync.isLoading ||
        supplementsAsync.isLoading ||
        habitsAsync.isLoading;

    final hasError = investigationsAsync.hasError ||
        guidelinesAsync.hasError ||
        supplementsAsync.hasError ||
        habitsAsync.hasError;

    if (isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (hasError) return const Scaffold(body: Center(child: Text("Error loading master data")));

    // 3. Extract the data safely once loading is complete
    final invMaster = investigationsAsync.value ?? [];
    final guideMaster = guidelinesAsync.value ?? [];
    final suppMaster = supplementsAsync.value ?? [];
    final habitMaster = habitsAsync.value ?? [];
    final admin = adminAsync.value;
    final company = companyAsync.value;

    // 🎯 Mapping Logic: Convert IDs to Names
    final investigationNames = plan.investigationIds.map((id) =>
    invMaster.firstWhereOrNull((m) => m.id == id)?.name ?? id).toList();

    final guidelineNames = plan.guidelineIds.map((id) =>
    guideMaster.firstWhereOrNull((m) => m.id == id)?.name ?? id).toList();

    final habitNames = plan.assignedHabitIds.map((id) =>
    habitMaster.firstWhereOrNull((m) => m.id == id)?.name ?? id).toList();

    final Map<String, String> resolvedSupplements = {};
    plan.suplimentIdsMap.forEach((id, dosage) {
      final name = suppMaster.firstWhereOrNull((m) => m.id == id)?.name ?? id;
      resolvedSupplements[name] = dosage;
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, ref,admin), // Your existing header
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: PlanClinicalReport(
                  client: client,
                  plan: plan,
                  vitals: vitals,
                  company: company,
                  doctor: admin,
                  resolvedInvestigations: investigationNames,
                  resolvedGuidelines: guidelineNames,
                  resolvedSupplements: resolvedSupplements,
                  resolvedHabits: habitNames,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref,AdminProfileModel? admin) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(plan.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(isMasterPreview ? "Internal Review" : "Official Report",
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
          // lib/admin/plan_report_view_screen.dart

          if (isMasterPreview)
            ElevatedButton.icon(
              onPressed: () async {
                final dietitian = ref.read(currentAdminProvider).value;
                if (dietitian == null || client == null) return;

                final pdfBytes = await DietPlanPdfGenerator.generatePlanPdf(
                  vitals: vitals,
                  clientPlan: plan,
                  client: client!,
                  dietitianProfile: dietitian,
                  ref: ref,
                );

                await Printing.layoutPdf(
                  onLayout: (format) async => pdfBytes,
                  name: 'Diet_Plan_${client!.name}.pdf',
                );
              },
              icon: const Icon(Icons.picture_as_pdf, size: 18),
              label: const Text("EXPORT"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white),
            ),
        ],
      ),
    );
  }
}