import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 🎯 Import
import 'package:nutricare_client_management/admin/admin_provider.dart'; // 🎯 Import
import 'package:nutricare_client_management/modules/client/model/client_model.dart';
import 'package:nutricare_client_management/modules/client/model/client_diet_plan_model.dart';
import 'package:nutricare_client_management/helper/diet_plan_pdf_generator.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';

class PlanReportViewScreen extends ConsumerWidget { // 🎯 Changed to ConsumerWidget
  final ClientModel client;
  final ClientDietPlanModel plan;

  const PlanReportViewScreen({super.key, required this.client, required this.plan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🎯 WATCH THE ADMIN PROFILE PROVIDER
    // This is already loaded by the dashboard, so it should be instant.
    final adminAsync = ref.watch(currentAdminProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: Stack(
        children: [
          Positioned(top: -100, right: -100, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.1), blurRadius: 80, spreadRadius: 30)]))),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  // 🎯 Handle Loading State
                  child: adminAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => Center(child: Text("Error loading profile: $err")),
                    data: (adminProfile) {
                      if (adminProfile == null) return const Center(child: Text("Admin profile not found."));
//return Container();
                     return PdfPreview(
                        allowSharing: true,
                        allowPrinting: true,
                        canChangePageFormat: false,
                        canDebug: false,
                        // 🎯 PASS PROFILE TO GENERATOR
                        build: (format) => DietPlanPdfGenerator.generatePlanPdf(
                            clientPlan: plan,
                            client: client,
                            dietitianProfile: adminProfile,ref: ref
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1)))),
          child: Row(
            children: [
              GestureDetector(onTap: () => Navigator.pop(context), child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]), child: const Icon(Icons.arrow_back, size: 20))),
              const SizedBox(width: 16),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(plan.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text("PDF Report Preview", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              )),
            ],
          ),
        ),
      ),
    );
  }
}