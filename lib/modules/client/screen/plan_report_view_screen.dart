import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutricare_client_management/admin/admin_provider.dart';
import 'package:nutricare_client_management/modules/client/model/client_model.dart';
import 'package:nutricare_client_management/modules/client/model/client_diet_plan_model.dart';
import 'package:nutricare_client_management/helper/diet_plan_pdf_generator.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';

class PlanReportViewScreen extends ConsumerWidget {
  final ClientModel? client; // Made nullable for master preview simplicity
  final ClientDietPlanModel plan;
  final bool isMasterPreview; // 🎯 NEW: Flag to control rendering mode

  const PlanReportViewScreen({
    super.key,
    this.client, // Client can be null if it's a master preview
    required this.plan,
    this.isMasterPreview = false, // Defaults to PDF mode (false)
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // WATCH THE ADMIN PROFILE PROVIDER
    final adminAsync = ref.watch(currentAdminProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: Stack(
        children: [
          Positioned(top: -100, right: -100, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.1), blurRadius: 80, spreadRadius: 30)]))),
          SafeArea(
            child: Column(
              children: [
                // 🎯 MODIFIED HEADER: Pass context to manage UI elements
                _buildHeader(context),
                Expanded(
                  // Handle Loading State
                  child: adminAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => Center(child: Text("Error loading profile: $err")),
                    data: (adminProfile) {
                      if (adminProfile == null) return const Center(child: Text("Admin profile not found."));

                      // 🎯 FIX: CONDITIONAL RENDERING
                      if (isMasterPreview) {
                        return _PlanQuickPreview(plan: plan);
                      }

                      // Original SLOW PDF preview (used when isMasterPreview is false)
                      return PdfPreview(
                        allowSharing: true,
                        allowPrinting: true,
                        canChangePageFormat: false,
                        canDebug: false,
                        // PASS PROFILE TO GENERATOR
                        build: (format) => DietPlanPdfGenerator.generatePlanPdf(
                            clientPlan: plan,
                            client: client!, // Client is guaranteed non-null in non-master preview mode
                            dietitianProfile: adminProfile,
                            ref: ref
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
    final title = isMasterPreview ? "Master Plan Preview" : "PDF Report Preview";
    final subTitle = isMasterPreview ? client?.name ?? "Template" : "PDF Report Preview";
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
                  Text(subTitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              )),
              // Show a clear button to switch to PDF mode if in Master Preview
              if (isMasterPreview)
                Tooltip(
                  message: "View PDF (Slower)",
                  child: IconButton(
                      icon: Icon(Icons.picture_as_pdf, color: Colors.red.shade700),
                      // Navigation logic to open a new instance in PDF mode (optional, but professional)
                      onPressed: () {
                        Navigator.of(context).pushReplacement(MaterialPageRoute(
                            builder: (_) => PlanReportViewScreen(plan: plan, client: client, isMasterPreview: false)
                        ));
                      }
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }
}

// 🎯 NEW: Lightweight UI for fast preview
class _PlanQuickPreview extends StatelessWidget {
  final ClientDietPlanModel plan;

  const _PlanQuickPreview({required this.plan});

  @override
  Widget build(BuildContext context) {
    // Only show essential plan structure for a quick, non-PDF rendering.
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Template Name:", style: Theme.of(context).textTheme.titleSmall),
          Text(plan.name, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          Text("Description:", style: Theme.of(context).textTheme.titleSmall),
          Text(plan.description.isNotEmpty ? plan.description : 'No description provided.', style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 24),

          // Display Cycle Type
          Text(
            plan.days.length > 1 ? "PLAN CYCLE: 7-Day Weekly" : "PLAN CYCLE: Single Day Fixed",
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
          ),
          const Divider(),

          // Display Meals/Days
          ...plan.days.asMap().entries.map((dayEntry) {
            final day = dayEntry.value;
            return Padding(
              // Increased padding for separation
              padding: const EdgeInsets.only(bottom: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Day Name Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      day.dayName.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.indigo),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Meal Details
                  ...day.meals.map((meal) {
                    if (meal.items.isEmpty) return const SizedBox.shrink(); // Skip empty meals

                    return Padding(
                      padding: const EdgeInsets.only(left: 8.0, bottom: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Meal Name (Breakfast, Lunch, etc.)
                          Text(
                            "${meal.mealName} (${meal.items.length} items):",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.teal),
                          ),
                          const SizedBox(height: 6),

                          // Food Items List (FIX: Added detail listing)
                          ...meal.items.asMap().entries.map((itemEntry) {
                            final item = itemEntry.value;
                            return Padding(
                              padding: const EdgeInsets.only(left: 16.0, bottom: 4.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Food Item Name and Quantity/Unit
                                  Text(
                                    "${itemEntry.key + 1}. ${item.foodItemName} (${item.quantity} ${item.unit})",
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  // Alternatives
                                  // Assumes item.alternatives is List<String>
                                  if (item.alternatives != null && item.alternatives.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8.0, top: 2.0),
                                      child: Text(
                                        "Alternatives: ${item.alternatives.join(', ')}",
                                        style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey.shade700),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }).toList(),
                          const SizedBox(height: 8),
                          const Divider(height: 1),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            );
          }),
          const SizedBox(height: 24),

          // Display Guidelines Summary
          Text("Assigned Guidelines (${plan.guidelineIds.length}):", style: Theme.of(context).textTheme.titleSmall),
          if (plan.guidelineIds.isEmpty)
            const Text("No guidelines assigned."),

        ],
      ),
    );
  }
}