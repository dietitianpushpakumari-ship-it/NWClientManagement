import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:nutricare_client_management/modules/client/model/client_model.dart';
import 'package:nutricare_client_management/modules/client/model/client_diet_plan_model.dart';
import 'package:nutricare_client_management/helper/diet_plan_pdf_generator.dart';
import 'package:nutricare_client_management/admin/custom_gradient_app_bar.dart';



class PlanReportViewScreen extends StatelessWidget {
  final ClientModel client;
  final ClientDietPlanModel plan;

  const PlanReportViewScreen({
    super.key,
    required this.client,
    required this.plan,
  });

  // 🎯 PDF SHARE/PRINT LOGIC (Moved from list screen)
  Future<void> _exportPlanToPdf(BuildContext context) async {
    final clientName = client.name;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generating PDF...')),
    );

    try {
      // 🎯 Key change: Using PdfPreview widget to display and handle print/share
      await Printing.layoutPdf(
        name: '${clientName.replaceAll(' ', '_')}_${plan.name.replaceAll(' ', '_')}_DietPlan.pdf',
        onLayout: (PdfPageFormat format) async {
          // This calls your generator logic to produce the PDF data
          final pdfBytes = await DietPlanPdfGenerator.generatePlanPdf(clientPlan: plan, client: client);
          return pdfBytes;
        },
      );

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to generate/view PDF: $e'),
            backgroundColor: Colors.red
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: CustomGradientAppBar(
        title: Text('${client.name}\'s ${plan.name} Report'),
        actions: [
          // 🎯 Printing/Sharing action button
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'Share/Print Report',
            onPressed: () => _exportPlanToPdf(context),
          ),
        ],
      ),

      // 🎯 Use PdfPreview widget for mobile report view and print options
      body: SafeArea(
        child: PdfPreview(
          allowSharing: true,
          allowPrinting: true,
          canChangePageFormat: false, // Typically locked for a diet plan
          canDebug: false,
          //name: '${client.name.replaceAll(' ', '_')}_${plan.name.replaceAll(' ', '_')}_DietPlan.pdf',

          // This function will be called whenever the PDF needs to be generated (e.g., for preview)
          build: (PdfPageFormat format) => DietPlanPdfGenerator.generatePlanPdf(
            clientPlan: plan,
            client: client,
          ),
        ),
      ),
    );
  }
}