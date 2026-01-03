import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutricare_client_management/admin/admin_profile_model.dart';
import 'package:nutricare_client_management/admin/admin_provider.dart';
import 'package:nutricare_client_management/admin/company_profile_master_screen.dart';
import 'package:nutricare_client_management/admin/generic_master_model.dart';
import 'package:nutricare_client_management/admin/labvital/global_service_provider.dart';
import 'package:nutricare_client_management/admin/plan_clinical_report.dart';
import 'package:nutricare_client_management/helper/diet_plan_pdf_generator.dart';
import 'package:nutricare_client_management/modules/client/model/client_diet_plan_model.dart';
import 'package:nutricare_client_management/modules/client/model/client_model.dart';
import 'package:nutricare_client_management/modules/client/model/vitals_model.dart';
import 'package:printing/printing.dart';

// Providers
final guidelineMasterProvider = StreamProvider<List<GenericMasterModel>>((ref) {
  return ref.watch(guidelineServiceProvider).streamActiveItems();
});
final investigationMasterProvider = StreamProvider<List<GenericMasterModel>>((ref) {
  return ref.watch(investigationMasterServiceProvider).streamActiveItems();
});
final supplementMasterProvider = StreamProvider<List<GenericMasterModel>>((ref) {
  return ref.watch(supplimentMasterServiceProvider).streamActiveItems();
});
final habitMasterProvider = StreamProvider<List<GenericMasterModel>>((ref) {
  return ref.watch(habitMasterServiceProvider).streamActiveItems();
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Watch Providers
    final investigationsAsync = ref.watch(investigationMasterProvider);
    final habitsAsync = ref.watch(habitMasterProvider);
    final adminAsync = ref.watch(currentAdminProvider);
    final companyAsync = ref.watch(companyProfileProvider);

    // 2. Loading State
    final isLoading = investigationsAsync.isLoading || habitsAsync.isLoading;
    if (isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    // 3. Extract Data
    final invMaster = investigationsAsync.value ?? [];
    final habitMaster = habitsAsync.value ?? [];
    final admin = adminAsync.value;
    final company = companyAsync.value;

    // --- 🎯 DATA MAPPING LOGIC (Updated to use Vitals) ---

    // A. Investigations (From Vitals)
    // Maps IDs to Names if found in master, otherwise keeps original text
    final List<String> investigationNames = vitals?.labTestOrders.map((id) {
      final match = invMaster.firstWhereOrNull((m) => m.id == id);
      return match?.name ?? id;
    }).toList() ?? [];

    // B. Guidelines (From Vitals Map)
    // Now derived directly from the Vitals Map Keys since they are stored as Text/Names
    final List<String> guidelineNames = vitals?.clinicalGuidelines?.keys.toList() ?? [];

    // C. Habits (From Diet Plan)
    // Maps IDs to Names
    final List<String> habitNames = plan.assignedHabitIds.map((id) {
      final match = habitMaster.firstWhereOrNull((m) => m.id == id);
      return match?.name ?? id;
    }).toList();

    // D. Supplements (From Vitals Medications)
    // 🎯 FIX: Build map from Vitals Medications List instead of removed 'plan.suplimentIdsMap'
    final Map<String, String> resolvedSupplements = {};
    if (vitals != null && vitals!.medications.isNotEmpty) {
      for (var med in vitals!.medications) {
        resolvedSupplements[med.name] = med.dosage;
      }
    } else if (vitals != null && vitals!.prescribedMedications.isNotEmpty) {
      // Fallback for legacy Map structure
      resolvedSupplements.addAll(vitals!.prescribedMedications);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, ref, admin),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: PlanClinicalReport(
                  client: client,
                  plan: plan,
                  vitals: vitals,
                  company: company,
                  doctor: admin,
                  // Pass resolved lists
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

  Widget _buildHeader(BuildContext context, WidgetRef ref, AdminProfileModel? admin) {
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