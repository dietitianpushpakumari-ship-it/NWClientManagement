import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutricare_client_management/admin/admin_profile_model.dart';
import 'package:nutricare_client_management/admin/admin_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

import 'package:nutricare_client_management/modules/client/model/client_model.dart';
import 'package:nutricare_client_management/modules/client/model/vitals_model.dart';

class ClinicalPrescriptionPrinter extends ConsumerWidget {
  final ClientModel client;
  final VitalsModel vitals;

  const ClinicalPrescriptionPrinter({
    super.key,
    required this.client,
    required this.vitals,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminAsync = ref.watch(currentAdminProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Prescription Preview"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.zoom_in),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Use Pinch or Double-Tap to Zoom"), duration: Duration(seconds: 1))
              );
            },
          )
        ],
      ),
      body: InteractiveViewer(
        panEnabled: true,
        boundaryMargin: const EdgeInsets.all(20),
        minScale: 0.5,
        maxScale: 4.0,
        child: adminAsync.when(
          data: (doctor) => PdfPreview(
            build: (format) => _generatePdf(format, doctor),
            initialPageFormat: PdfPageFormat.a4,
            canChangePageFormat: false,
            canChangeOrientation: false,
            maxPageWidth: 700,
            pdfFileName: "Rx_${client.name}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf",
            scrollViewDecoration: const BoxDecoration(color: Color(0xFFF4F7FF)),
            loadingWidget: const Center(child: CircularProgressIndicator()),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text("Error: $err")),
        ),
      ),
    );
  }

  Future<Uint8List> _generatePdf(PdfPageFormat format, AdminProfileModel? doctor) async {
    final pdf = pw.Document();
    final pageFormat = PdfPageFormat.a4;

    // --- STYLES ---
    final headerStyle = pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900);
    final subHeaderStyle = pw.TextStyle(fontSize: 10, color: PdfColors.grey700);
    final sectionTitleStyle = pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.white);
    final contentStyle = const pw.TextStyle(fontSize: 10);
    final boldContentStyle = pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold);

    // Doctor Details
    final drName = doctor != null ? "Dr. ${doctor.firstName} ${doctor.lastName}" : "Dr. Name";
    final drQual = doctor != null ? doctor.qualifications.join(', ') : "Qualification";
    final drReg = doctor != null ? "Reg No: ${doctor.regdNo}" : "";
    final drPhone = doctor != null ? "+91 ${doctor.mobile}" : "";

    // 1. EXTRACT FOLLOW UP (Before ignoring notes)
    // We access the map safely, check for the key, and store it.
    // We do NOT print the rest of the notes.
    String? followUpText;
    if (vitals.clinicalNotes != null && vitals.clinicalNotes!.containsKey('Next Review')) {
      followUpText = vitals.clinicalNotes!['Next Review'];
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.symmetric(horizontal: 30, vertical: 30),
        build: (pw.Context context) {
          return [
            // --- HEADER ---
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("NUTRICARE WELLNESS", style: headerStyle),
                    pw.Text("Clinical Nutrition & Dietetics", style: subHeaderStyle),
                    pw.SizedBox(height: 6),
                    pw.Text(drName, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    pw.Text(drQual, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey800)),
                    pw.Text("$drReg  |  $drPhone", style: subHeaderStyle),
                  ],
                ),
                pw.Container(height: 50, width: 50, decoration: const pw.BoxDecoration(color: PdfColors.indigo50))
              ],
            ),
            pw.Divider(color: PdfColors.indigo900, thickness: 1.5),
            pw.SizedBox(height: 10),

            // --- PATIENT INFO ---
            pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                        pw.Text("Patient: ${client.name}", style: boldContentStyle),
                        pw.Text("Age/Gender: ${client.age} / ${client.gender}", style: contentStyle),
                        pw.Text("ID: ${client.id.substring(0, 6).toUpperCase()}", style: contentStyle),
                      ]),
                      pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                        pw.Text("Date: ${DateFormat('dd MMM yyyy').format(vitals.date)}", style: boldContentStyle),
                        pw.Text("Weight: ${vitals.weightKg} kg  |  BMI: ${vitals.bmi.toStringAsFixed(1)}", style: contentStyle),
                        if(vitals.bloodPressureSystolic != null)
                          pw.Text("BP: ${vitals.bloodPressureSystolic}/${vitals.bloodPressureDiastolic} mmHg", style: contentStyle),
                      ]),
                    ]
                )
            ),
            pw.SizedBox(height: 20),

            // --- MEDICAL HISTORY ---
            if (vitals.medicalHistory?.isNotEmpty ?? false) ...[
              pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                        width: 80,
                        child: pw.Text("Medical History:", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900))
                    ),
                    pw.Expanded(
                        child: pw.Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: vitals.medicalHistory!.entries.map((e) {
                              String text = e.key;
                              // Check for "Not specified" case-insensitive
                              if (e.value.isNotEmpty && e.value.toLowerCase() != 'not specified') {
                                text += " (${e.value})";
                              }
                              return pw.Container(
                                  padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: pw.BoxDecoration(color: PdfColors.grey200, borderRadius: pw.BorderRadius.circular(4)),
                                  child: pw.Text(text, style: const pw.TextStyle(fontSize: 9))
                              );
                            }).toList()
                        )
                    )
                  ]
              ),
              pw.SizedBox(height: 10),
              pw.Divider(thickness: 0.5, color: PdfColors.grey300),
              pw.SizedBox(height: 10),
            ],

            // --- FINDINGS (Complaints & Diagnosis) ---
            if ((vitals.clinicalComplaints?.isNotEmpty ?? false) || (vitals.nutritionDiagnoses?.isNotEmpty ?? false)) ...[
              pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (vitals.clinicalComplaints?.isNotEmpty ?? false)
                      pw.Expanded(
                          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                            pw.Text("Complaints / Symptoms:", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                            // 🎯 FIX: Hiding value if 'Not Specified'
                            ...vitals.clinicalComplaints!.entries.map((e) {
                              String text = e.key;
                              if (e.value.isNotEmpty && e.value.toLowerCase() != 'not specified') {
                                text += " (${e.value})";
                              }
                              return _buildBulletPoint(text, isRich: false, normalStyle: contentStyle);
                            })
                          ])
                      ),
                    if (vitals.nutritionDiagnoses?.isNotEmpty ?? false)
                      pw.Expanded(
                          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                            pw.Text("Clinical Diagnosis:", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                            // 🎯 FIX: Hiding value if 'Not Specified'
                            ...vitals.nutritionDiagnoses!.entries.map((e) {
                              String text = e.key;
                              if (e.value.isNotEmpty && e.value.toLowerCase() != 'not specified') {
                                text += " (${e.value})";
                              }
                              return _buildBulletPoint(text, isRich: false, normalStyle: contentStyle);
                            })
                          ])
                      ),
                  ]
              ),
              pw.SizedBox(height: 20),
              pw.Divider(thickness: 0.5, color: PdfColors.grey400),
              pw.SizedBox(height: 10),
            ],

            // --- Rx PRESCRIPTIONS ---
            if (vitals.medications.isNotEmpty) ...[
              _buildSectionHeader("Rx (PRESCRIPTIONS)", sectionTitleStyle),
              pw.SizedBox(height: 10),
              pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                  children: [
                    pw.TableRow(
                        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                        children: [
                          _buildCell("Medicine Name", isHeader: true),
                          _buildCell("Dosage", isHeader: true),
                          _buildCell("Frequency", isHeader: true),
                          _buildCell("Duration", isHeader: true),
                          _buildCell("Instruction", isHeader: true),
                        ]
                    ),
                    ...vitals.medications.map((m) => pw.TableRow(
                        children: [
                          _buildCell(m.name, isBold: true),
                          _buildCell(m.dosage),
                          _buildCell(m.frequency),
                          _buildCell(m.duration),
                          _buildCell(m.instruction),
                        ]
                    )).toList()
                  ]
              ),
              pw.SizedBox(height: 20),
            ],

            // --- LAB INVESTIGATIONS ---
            if (vitals.labTestOrders.isNotEmpty) ...[
              _buildSectionHeader("LAB INVESTIGATIONS ADVISED", sectionTitleStyle),
              pw.SizedBox(height: 8),
              pw.Wrap(
                  spacing: 10,
                  runSpacing: 5,
                  children: vitals.labTestOrders.map((l) => pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey500), borderRadius: pw.BorderRadius.circular(4)),
                      child: pw.Text(l, style: const pw.TextStyle(fontSize: 9))
                  )).toList()
              ),
              pw.SizedBox(height: 20),
            ],

            // --- GUIDELINES ---
            if (vitals.clinicalGuidelines?.isNotEmpty ?? false) ...[
              _buildSectionHeader("CLINICAL PROTOCOLS & GUIDELINES", sectionTitleStyle),
              pw.SizedBox(height: 8),
              // 🎯 FIX: Only show Key if value is "Protocol Attached" or similar
              ...vitals.clinicalGuidelines!.entries.map((e) {

                String? contentToShow = e.value;
                if (contentToShow == "Standard Protocol Advised" ||
                    contentToShow == "Protocol Attached" ||
                    contentToShow == "Protocol attached") {
                  contentToShow = null; // Hide value completely
                }

                return _buildBulletPoint(
                    "", isRich: true, title: e.key,
                    content: contentToShow,
                    boldStyle: boldContentStyle, normalStyle: contentStyle
                );
              }),
              pw.SizedBox(height: 20),
            ],

            // --- ❌ NOTES SECTION REMOVED ---
            // We removed the "ADVICE & NOTES" block completely.

            // --- FOLLOW UP (Preserved) ---
            if (followUpText != null && followUpText.isNotEmpty && followUpText != 'Not specified') ...[
              pw.SizedBox(height: 20),
              pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.indigo900, width: 1),
                      borderRadius: pw.BorderRadius.circular(6),
                      color: PdfColors.indigo50
                  ),
                  child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        pw.Text("NEXT REVIEW / FOLLOW UP:  ", style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
                        pw.Text(followUpText, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold))
                      ]
                  )
              )
            ],

            // --- FOOTER ---
            pw.Spacer(),
            pw.Divider(color: PdfColors.indigo900),
            pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text("Generated on ${DateFormat('dd MMM yyyy HH:mm').format(DateTime.now())}", style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
                  pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.SizedBox(height: 30),
                        pw.Text(drName, style: boldContentStyle),
                        pw.Text("Authorized Signature", style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
                      ]
                  )
                ]
            )
          ];
        },
      ),
    );

    return pdf.save();
  }

  // --- HELPER FOR CLEAN BULLETS ---
  pw.Widget _buildBulletPoint(String plainText, {bool isRich = false, String? title, String? content, pw.TextStyle? boldStyle, pw.TextStyle? normalStyle}) {
    // 🎯 Logic: If content is null or matches filter words, don't show it.
    bool hasContent = content != null &&
        content.trim().isNotEmpty &&
        content.toLowerCase() != 'not specified';

    return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(width: 3, height: 3, margin: const pw.EdgeInsets.only(top: 4, right: 6), decoration: const pw.BoxDecoration(color: PdfColors.black, shape: pw.BoxShape.circle)),
              pw.Expanded(
                  child: isRich
                      ? pw.RichText(text: pw.TextSpan(children: [
                    pw.TextSpan(text: title, style: boldStyle),
                    if (hasContent) ...[
                      pw.TextSpan(text: ": ", style: boldStyle),
                      pw.TextSpan(text: content, style: normalStyle)
                    ]
                  ]))
                      : pw.Text(plainText, style: normalStyle)
              )
            ]
        )
    );
  }

  pw.Widget _buildSectionHeader(String title, pw.TextStyle style) {
    return pw.Container(width: double.infinity, padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8), color: PdfColors.indigo900, child: pw.Text(title, style: style));
  }

  pw.Widget _buildCell(String text, {bool isHeader = false, bool isBold = false}) {
    return pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(text, style: pw.TextStyle(fontSize: 9, fontWeight: (isHeader || isBold) ? pw.FontWeight.bold : pw.FontWeight.normal)));
  }
}