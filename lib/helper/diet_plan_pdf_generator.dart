import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutricare_client_management/master/model/diet_plan_item_model.dart';
import 'package:nutricare_client_management/modules/client/model/client_diet_plan_model.dart';
import 'package:nutricare_client_management/modules/client/model/client_model.dart';
import 'package:nutricare_client_management/modules/client/model/vitals_model.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../admin/admin_profile_model.dart';

class DietPlanPdfGenerator {
  static Future<Uint8List> generatePlanPdf({
    required ClientDietPlanModel clientPlan,
    required VitalsModel? vitals,
    required ClientModel client,
    required AdminProfileModel dietitianProfile,
    required WidgetRef ref,
  }) async {
    final pdf = pw.Document();

    // 🎯 Fix Helvetica Error: Load Google Fonts for full Unicode support
    final regularFont = await PdfGoogleFonts.openSansRegular();
    final boldFont = await PdfGoogleFonts.openSansBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return [
            _buildPdfHeader(dietitianProfile, boldFont, regularFont),
            pw.SizedBox(height: 15),
            _buildPatientBanner(client, boldFont, regularFont),
            pw.Divider(thickness: 1, color: PdfColors.indigo, height: 20),

            _buildPdfSectionTitle("CLINICAL ASSESSMENT", boldFont),
            _buildClinicalVitalsGrid(vitals, boldFont, regularFont),

            _buildPdfSectionTitle("LIFESTYLE SUMMARY", boldFont),
            _buildLifestyleSummary(vitals!, boldFont, regularFont),

            pw.SizedBox(height: 25),
            pw.Center(
              child: pw.Text(
                "NUTRITION SCHEDULE: ${clientPlan.name.toUpperCase()}",
                style: pw.TextStyle(font: boldFont, fontSize: 12, color: PdfColors.indigo900),
              ),
            ),
            pw.SizedBox(height: 10),

            // 🎯 THE CRITICAL FIX: Direct spread into the build list
            ...clientPlan.days.expand((day) => [
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 15, bottom: 5),
                child: pw.Text(
                  "DAY ${clientPlan.days.indexOf(day) + 1}: ${day.dayName}",
                  style: pw.TextStyle(font: boldFont, fontSize: 10, color: PdfColors.indigo700),
                ),
              ),
              ...day.meals.where((m) => m.items.isNotEmpty).map((meal) => pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 4),
                    child: pw.Text(meal.mealName, style: pw.TextStyle(font: boldFont, fontSize: 8.5)),
                  ),
                  _buildMealTable(meal, boldFont, regularFont),
                  pw.SizedBox(height: 6),
                ],
              )),
            ]),

            pw.SizedBox(height: 40),
            _buildPdfSignature(dietitianProfile, boldFont, regularFont),
          ];
        },
      ),
    );

    return pdf.save();
  }

  // --- 1. Header Method ---
  static pw.Widget _buildPdfHeader(AdminProfileModel admin, pw.Font bold, pw.Font reg) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(admin.companyName?.toUpperCase() ?? "CLINIC",
                style: pw.TextStyle(font: bold, fontSize: 16, color: PdfColors.indigo)),
         //   pw.Text(admin.c ?? "", style: pw.TextStyle(font: reg, fontSize: 8)),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(admin.fullName ?? "", style: pw.TextStyle(font: bold, fontSize: 10)),
            pw.Text(admin.designation ?? "", style: pw.TextStyle(font: reg, fontSize: 8)),
            if (admin.regdNo != null)
              pw.Text("Reg: ${admin.regdNo}", style: pw.TextStyle(font: reg, fontSize: 7)),
          ],
        ),
      ],
    );
  }

  // --- 2. Patient Banner Method ---
  static pw.Widget _buildPatientBanner(ClientModel client, pw.Font bold, pw.Font reg) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: const pw.BoxDecoration(color: PdfColors.indigo50),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          _bannerItem("PATIENT", client.name, bold, reg),
          _bannerItem("AGE/SEX", "${client.age}/${client.gender}", bold, reg),
          _bannerItem("ID", client.id.substring(0, 8).toUpperCase(), bold, reg),
        ],
      ),
    );
  }

  static pw.Widget _bannerItem(String label, String val, pw.Font bold, pw.Font reg) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: pw.TextStyle(font: bold, fontSize: 6, color: PdfColors.indigo)),
        pw.Text(val, style: pw.TextStyle(font: bold, fontSize: 9)),
      ],
    );
  }

  // --- 3. Lifestyle Summary Method ---
  static pw.Widget _buildLifestyleSummary(VitalsModel vitals, pw.Font bold, pw.Font reg) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text("Activity: ${vitals.activityType ?? 'N/A'}",
            style: pw.TextStyle(font: reg, fontSize: 9)),
        pw.SizedBox(height: 4),
        pw.Text("Dietary Habit: ${vitals.foodHabit ?? 'N/A'}",
            style: pw.TextStyle(font: reg, fontSize: 9)),
      ],
    );
  }

  // --- 4. Signature Method ---
// --- 4. Signature Method (Corrected) ---
  static pw.Widget _buildPdfSignature(AdminProfileModel admin, pw.Font bold, pw.Font reg) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Column(
          children: [
            // 🎯 FIX: Move border inside pw.BoxDecoration
            pw.Container(
                width: 120,
                decoration: const pw.BoxDecoration(
                    border: pw.Border(
                        bottom: pw.BorderSide(width: 0.5, color: PdfColors.black)
                    )
                )
            ),
            pw.SizedBox(height: 5),
            pw.Text(admin.fullName ?? "", style: pw.TextStyle(font: bold, fontSize: 9)),
            pw.Text("Consultant ${admin.designation ?? ''}", style: pw.TextStyle(font: reg, fontSize: 7)),
          ],
        ),
      ],
    );
  }
  // --- Helper Table Logic (Already provided but included for completeness) ---
  static pw.Widget _buildMealTable(DietPlanMealModel meal, pw.Font bold, pw.Font reg) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey100),
          children: [
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text("Item", style: pw.TextStyle(font: bold, fontSize: 8))),
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text("Qty", style: pw.TextStyle(font: bold, fontSize: 8))),
          ],
        ),
        ...meal.items.map((i) => pw.TableRow(
          children: [
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(i.foodItemName, style: pw.TextStyle(font: reg, fontSize: 8))),
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text("${i.quantity} ${i.unit}", style: pw.TextStyle(font: reg, fontSize: 8))),
          ],
        )),
      ],
    );
  }

  static pw.Widget _buildPdfSectionTitle(String title, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 15, bottom: 5),
      child: pw.Text(title, style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.indigo, letterSpacing: 1.2)),
    );
  }

  static pw.Widget _buildClinicalVitalsGrid(VitalsModel? vitals, pw.Font bold, pw.Font reg) {
    return pw.Wrap(
      spacing: 15,
      runSpacing: 10,
      children: [
        _vitalBox("Weight", "${vitals!.weightKg}kg", reg, bold),
        _vitalBox("Height", "${vitals.heightCm}cm", reg, bold),
        _vitalBox("BMI", "${vitals.bmi}", reg, bold),
        _vitalBox("BP", "${vitals.bloodPressureSystolic} / ${vitals.bloodPressureDiastolic}" ?? "N/A", reg, bold),
      ],
    );
  }

  static pw.Widget _vitalBox(String label, String val, pw.Font reg, pw.Font bold) {
    return pw.Container(
      width: 60,
      padding: const pw.EdgeInsets.all(4),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey200), borderRadius: pw.BorderRadius.circular(4)),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: pw.TextStyle(font: reg, fontSize: 6, color: PdfColors.grey600)),
          pw.Text(val, style: pw.TextStyle(font: bold, fontSize: 8)),
        ],
      ),
    );
  }
}