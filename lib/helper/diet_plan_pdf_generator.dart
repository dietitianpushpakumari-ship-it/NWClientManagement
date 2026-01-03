import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutricare_client_management/modules/client/model/client_diet_plan_model.dart';
import 'package:nutricare_client_management/modules/client/model/client_model.dart';
import 'package:nutricare_client_management/modules/client/model/vitals_model.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
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

    final regularFont = await PdfGoogleFonts.openSansRegular();
    final boldFont = await PdfGoogleFonts.openSansBold();

    // Styles
    final headerStyle = pw.TextStyle(font: boldFont, fontSize: 18, color: PdfColors.indigo900);
    final subHeaderStyle = pw.TextStyle(font: boldFont, fontSize: 10, color: PdfColors.indigo);
    final bodyStyle = pw.TextStyle(font: regularFont, fontSize: 9);
    final smallStyle = pw.TextStyle(font: regularFont, fontSize: 8, color: PdfColors.grey800);
    final altStyle = pw.TextStyle(font: regularFont, fontSize: 8, color: PdfColors.grey600); // Style for alternatives

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build: (context) {
          return [
            if (clientPlan.isProvisional)
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(vertical: 4),
                margin: const pw.EdgeInsets.only(bottom: 10),
                decoration: const pw.BoxDecoration(color: PdfColors.orange50),
                child: pw.Text(
                  "PROVISIONAL DIET PLAN (DRAFT) - NOT FINALIZED",
                  style: pw.TextStyle(font: boldFont, fontSize: 10, color: PdfColors.orange800),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            // --- 1. HEADER & PATIENT INFO ---
            _buildHeader(dietitianProfile, headerStyle, bodyStyle),
            pw.SizedBox(height: 15),
            _buildPatientBanner(client, boldFont, regularFont),
            pw.Divider(color: PdfColors.grey400, thickness: 0.5),
            pw.SizedBox(height: 10),

            // --- 2. CLINICAL & MEDICAL DASHBOARD ---
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Left Col: Clinical Profile
                pw.Expanded(
                  flex: 5,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle("CLINICAL PROFILE", subHeaderStyle),
                      _buildMedicalProfile(vitals, boldFont, regularFont),
                    ],
                  ),
                ),
                pw.SizedBox(width: 20),
                // Right Col: Intervention & Rx
                pw.Expanded(
                  flex: 4,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle("INTERVENTION & RX", subHeaderStyle),
                      _buildInterventionSection(vitals, clientPlan, boldFont, regularFont),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 15),

            // --- 3. DIET PLAN GRID ---
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 10),
              decoration: const pw.BoxDecoration(color: PdfColors.indigo900),
              child: pw.Text(
                "NUTRITION PLAN: ${clientPlan.name.toUpperCase()}",
                style: pw.TextStyle(font: boldFont, fontSize: 11, color: PdfColors.white),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.SizedBox(height: 10),

            ...clientPlan.days.map((day) {
              final activeMeals = day.meals.where((m) => m.items.isNotEmpty).toList();
              if (activeMeals.isEmpty) return pw.SizedBox();

              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(
                  children: [
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.all(6),
                      color: PdfColors.grey100,
                      child: pw.Text(day.dayName.toUpperCase(), style: pw.TextStyle(font: boldFont, fontSize: 9)),
                    ),
                    pw.Table(
                        border: const pw.TableBorder(verticalInside: pw.BorderSide(color: PdfColors.grey300)),
                        children: [
                          pw.TableRow(
                            children: activeMeals.map((meal) => pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(meal.mealName, style: pw.TextStyle(font: boldFont, fontSize: 9, color: PdfColors.indigo)),
                                  pw.SizedBox(height: 4),

                                  // 🎯 UPDATED ITEM RENDERING LOGIC
                                  ...meal.items.map((item) {
                                    return pw.Column(
                                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                                      children: [
                                        // 1. Main Item
                                        pw.Padding(
                                            padding: const pw.EdgeInsets.only(bottom: 2),
                                            child: pw.RichText(
                                                text: pw.TextSpan(
                                                    children: [
                                                      pw.TextSpan(text: "• ", style: bodyStyle.copyWith(color: PdfColors.indigo)),
                                                      pw.TextSpan(text: item.foodItemName, style: bodyStyle),
                                                      pw.TextSpan(text: " (${item.quantity}${item.unit})", style: smallStyle),
                                                    ]
                                                )
                                            )
                                        ),

                                        // 2. Alternatives (if any)
                                        if (item.alternatives.isNotEmpty)
                                          ...item.alternatives.map((alt) => pw.Padding(
                                            padding: const pw.EdgeInsets.only(left: 10, bottom: 2),
                                            child: pw.RichText(
                                                text: pw.TextSpan(
                                                    children: [
                                                      pw.TextSpan(text: "OR ", style: altStyle.copyWith(fontWeight: pw.FontWeight.bold, fontSize: 7)),
                                                      pw.TextSpan(text: alt.foodItemName, style: altStyle),
                                                      pw.TextSpan(text: " (${alt.quantity}${alt.unit})", style: altStyle.copyWith(fontSize: 7)),
                                                    ]
                                                )
                                            ),
                                          )),
                                      ],
                                    );
                                  })
                                ],
                              ),
                            )).toList(),
                          )
                        ]
                    )
                  ],
                ),
              );
            }).toList(),

            pw.SizedBox(height: 30),
            _buildFooter(dietitianProfile, boldFont, regularFont),
          ];
        },
      ),
    );

    return pdf.save();
  }

  // --- LOGIC: SMART FORMATTER ---
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

  // --- WIDGET BUILDERS ---

  static pw.Widget _buildMedicalProfile(VitalsModel? vitals, pw.Font bold, pw.Font reg) {
    if (vitals == null) return pw.Text("No clinical data available", style: pw.TextStyle(font: reg, fontSize: 9));

    final diagnosis = _smartFormat(vitals.nutritionDiagnoses);
    final complaints = _smartFormat(vitals.clinicalComplaints);
    final history = _smartFormat(vitals.medicalHistory);
    final investigations = (vitals.labTestOrders.isNotEmpty)
        ? vitals.labTestOrders.join(", ")
        : "-";

    return pw.Column(
      children: [
        _infoRow("Diagnosis", diagnosis, bold, reg),
        _infoRow("Complaints", complaints, bold, reg),
        _infoRow("History", history, bold, reg),
        _infoRow("Investigation", investigations, bold, reg),
        pw.SizedBox(height: 6),
        pw.Row(
          children: [
            _boxTag("BMI: ${vitals.bmi.toStringAsFixed(1)}", bold),
            pw.SizedBox(width: 8),
            _boxTag("Weight: ${vitals.weightKg}kg", bold),
            pw.SizedBox(width: 8),
            _boxTag("BP: ${vitals.bloodPressureSystolic ?? '-'}/${vitals.bloodPressureDiastolic ?? '-'}", bold),
          ],
        )
      ],
    );
  }

  static pw.Widget _buildInterventionSection(VitalsModel? vitals, ClientDietPlanModel plan, pw.Font bold, pw.Font reg) {
    final List<pw.Widget> items = [];

    // 1. Medications / Supplements
    if (vitals != null) {
      if (vitals.medications.isNotEmpty) {
        items.addAll(vitals.medications.map((m) {
          final List<String> parts = [];
          if (m.dosage.isNotEmpty) parts.add(m.dosage);
          if (m.frequency.isNotEmpty) parts.add(m.frequency);
          if (m.duration.isNotEmpty) parts.add(m.duration);
          if (m.instruction.isNotEmpty) parts.add(m.instruction);

          final details = parts.join(", ");
          return _bulletPoint("${m.name}: $details", bold, reg);
        }));
      } else if (vitals.prescribedMedications.isNotEmpty) {
        items.add(pw.Text(_smartFormat(vitals.prescribedMedications), style: pw.TextStyle(font: reg, fontSize: 9)));
      } else {
        items.add(pw.Text("No medication/supplements.", style: pw.TextStyle(font: reg, fontSize: 9, color: PdfColors.grey600)));
      }
    }

    // 2. Guidelines
    if (vitals?.clinicalGuidelines != null && vitals!.clinicalGuidelines!.isNotEmpty) {
      items.add(pw.SizedBox(height: 8));
      items.add(pw.Text("GUIDELINES:", style: pw.TextStyle(font: bold, fontSize: 9, color: PdfColors.indigo)));

      vitals.clinicalGuidelines!.entries.forEach((e) {
        String text;
        if (e.value == "Standard Protocol Advised" || e.value.isEmpty) {
          text = e.key;
        } else {
          text = "${e.key} - ${e.value}";
        }
        items.add(_bulletPoint(text, bold, reg));
      });
    }

    // 3. Follow Up
    // Corrected Null check safely
    if (vitals != null && vitals.clinicalNotes != null && vitals.clinicalNotes!['Next Review'] != null) {
      items.add(pw.SizedBox(height: 8));
      items.add(pw.Divider(borderStyle: pw.BorderStyle.dashed, color: PdfColors.grey400));
      items.add(pw.Padding(
        padding: const pw.EdgeInsets.only(top: 4),
        child: pw.Text(
          "FOLLOW UP: Review in ${vitals.clinicalNotes!['Next Review']} ",
          style: pw.TextStyle(font: bold, fontSize: 9, color: PdfColors.red900),
        ),
      ));
    }

    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: items);
  }

  // --- HELPERS ---

  static pw.Widget _bulletPoint(String text, pw.Font bold, pw.Font reg) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text("• ", style: pw.TextStyle(font: bold, fontSize: 10, color: PdfColors.indigo)),
          pw.Expanded(child: pw.Text(text, style: pw.TextStyle(font: reg, fontSize: 9))),
        ],
      ),
    );
  }

  static pw.Widget _infoRow(String label, String value, pw.Font bold, pw.Font reg) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(width: 60, child: pw.Text("$label:", style: pw.TextStyle(font: bold, fontSize: 8, color: PdfColors.grey800))),
          pw.Expanded(child: pw.Text(value, style: pw.TextStyle(font: reg, fontSize: 9), maxLines: 3)),
        ],
      ),
    );
  }

  static pw.Widget _boxTag(String text, pw.Font font) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400), borderRadius: pw.BorderRadius.circular(4)),
      child: pw.Text(text, style: pw.TextStyle(font: font, fontSize: 8)),
    );
  }

  static pw.Widget _buildHeader(AdminProfileModel admin, pw.TextStyle header, pw.TextStyle sub) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(admin.companyName?.toUpperCase() ?? "DIET PLAN", style: header),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(admin.fullName ?? "", style: sub.copyWith(fontSize: 10)),
            pw.Text(admin.designation ?? "", style: sub.copyWith(fontSize: 8, color: PdfColors.grey700)),
          ],
        )
      ],
    );
  }

  static pw.Widget _buildPatientBanner(ClientModel client, pw.Font bold, pw.Font reg) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: const pw.BoxDecoration(color: PdfColors.grey100),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text("PATIENT: ${client.name} (${client.age}y/${client.gender})", style: pw.TextStyle(font: bold, fontSize: 10)),
          pw.Text("DATE: ${DateFormat('dd MMM yyyy').format(DateTime.now())}", style: pw.TextStyle(font: bold, fontSize: 10)),
        ],
      ),
    );
  }

  static pw.Widget _buildSectionTitle(String title, pw.TextStyle style) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Text(title, style: style),
    );
  }

  static pw.Widget _buildFooter(AdminProfileModel admin, pw.Font bold, pw.Font reg) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text("Generated by NutriCare", style: pw.TextStyle(font: reg, fontSize: 7, color: PdfColors.grey500)),
        pw.Column(
          children: [
            pw.Container(width: 100, height: 0.5, color: PdfColors.black),
            pw.SizedBox(height: 2),
            pw.Text("Signature", style: pw.TextStyle(font: reg, fontSize: 8)),
          ],
        )
      ],
    );
  }
}