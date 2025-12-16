// lib/services/diet_plan_pdf_generator.dart

import 'dart:typed_data';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutricare_client_management/admin/admin_profile_model.dart';
import 'package:nutricare_client_management/admin/labvital/global_service_provider.dart';
import 'package:nutricare_client_management/master/model/diet_plan_item_model.dart';
import 'package:nutricare_client_management/master/model/guidelines.dart';
// REMOVED: import 'package:nutricare_client_management/admin/admin_profile_service.dart';
import 'package:nutricare_client_management/modules/client/model/client_diet_plan_model.dart';
import 'package:nutricare_client_management/modules/client/model/client_model.dart';
import 'package:nutricare_client_management/modules/client/model/vitals_model.dart';
import 'package:nutricare_client_management/modules/client/screen/investigation_master_model.dart';
import 'package:nutricare_client_management/modules/client/screen/investigation_master_service.dart';
import 'package:nutricare_client_management/modules/client/services/vitals_service.dart';
import 'package:nutricare_client_management/master/model/diagonosis_master.dart';
import 'package:nutricare_client_management/modules/master/service/diagonosis_master_service.dart';
import 'package:nutricare_client_management/modules/master/service/guideline_service.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

// ... (Keep LabTest classes as they were) ...
class LabTest {
  final String displayName;
  final String unit;
  final String category;
  final String referenceRange;
  const LabTest({required this.displayName, required this.unit, required this.category, required this.referenceRange});
}
class LabVitalsData {
  static const Map<String, LabTest> allLabTests = {
    'fasting_glucose': LabTest(displayName: 'Fasting Glucose', unit: 'mg/dL', category: 'Blood Sugar', referenceRange: '< 100'),
    // ... (keep rest of map)
  };
}

class DietPlanPdfGenerator  {




  static const String _declarationText =
      "**CLINICAL DIETITIAN DECLARATION:** I, the undersigned Registered Dietitian, affirm that this diet plan is meticulously prepared based on a thorough assessment of the client's current health status, comprehensive medical and dietary history, lab reports, and defined nutritional requirements. This document serves as a personalized clinical recommendation and must be used in conjunction with and should not replace advice from a primary healthcare provider or physician.";

  static Future<Uint8List> generatePlanPdf({
    required ClientDietPlanModel clientPlan,
    required ClientModel client,
    required AdminProfileModel dietitianProfile,required WidgetRef ref// 🎯 FIX: Pass profile here
  }) async {
    final pdf = pw.Document(title: clientPlan.name);

    final regularFont = await PdfGoogleFonts.openSansRegular();
    final boldFont = await PdfGoogleFonts.openSansBold();



    final vitalsList = await ref.read(vitalsServiceProvider).getClientVitals(client.id);
    final VitalsModel? vitals = vitalsList.isNotEmpty ? vitalsList.first : null;

    final guidelineList = await ref.read(guidelineServiceProvider).fetchGuidelinesByIds(clientPlan.guidelineIds);
    final diagnosisList = await ref.read(diagnosisMasterServiceProvider).fetchAllDiagnosisMasterByIds(clientPlan.diagnosisIds);
    final investigationList =  await ref.read(investigationMasterServiceProvider).fetchAllInvestigationMasterByIds(clientPlan.investigationIds);

    // 🎯 REMOVED: final dietitianInfo = await AdminProfileService().fetchAdminProfile();
    // Use the passed argument instead:
    final dietitianInfo = dietitianProfile;

    String reportType = clientPlan.isProvisional ?  'Provisional' : '';
    int? followUpDays = clientPlan.followUpDays;
    List<String> medicalHistory = [];
    List<String> existingMedications = vitals != null ? (vitals.existingMedication?.split(',').toList() ?? []) : [];
    List<String> allergiesRestrictions = [];
    //List<String> allergiesRestrictions = vitals != null ? (vitals.foodAllergies?.split(',').toList() ?? []) : [];
    List<InvestigationMasterModel> investigationRequired = investigationList;
    List<String> clientComplaints = clientPlan.complaints.split(',').toList();

    // --- 1. FIRST PAGE ---
    pdf.addPage(
      pw.Page(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(35),
          buildBackground: (context) {
            return pw.Center(
              child: pw.Transform.rotate(
                angle: -pi / 4,
                child: pw.Text(
                  dietitianInfo.companyName, // 🎯 Use local var
                  style: pw.TextStyle(fontSize: 80, color: PdfColors.grey200, font: boldFont),
                ),
              ),
            );
          },
        ),
        build: (context) => _buildFirstPageContent(
          client: client,
          info: dietitianInfo, // 🎯 Pass it down
          vitals: vitals,
          diagnosisList: diagnosisList,
          boldFont: boldFont,
          regularFont: regularFont,
          reportType: reportType,
          followUpDays: followUpDays ?? 0,
          clientComplaints: clientComplaints,
          medicalHistory: medicalHistory,
          existingMedications: existingMedications,
          allergiesRestrictions: allergiesRestrictions,
          investigationRequired: investigationRequired,
        ),
      ),
    );

    // --- 2. SECOND PAGE ONWARDS ---
    pdf.addPage(
      pw.MultiPage(
        footer: (context) {
          return _buildFooterSection(
              dietitianInfo, // 🎯 Pass it down
              guidelineList,
              boldFont,
              regularFont,
              context.pageNumber == context.pagesCount
          );
        },
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.only(top: 35, bottom: 120, left: 35, right: 35),
          buildBackground: (context) {
            return pw.Center(
              child: pw.Transform.rotate(
                angle: -pi / 4,
                child: pw.Text(
                  dietitianInfo.companyName,
                  style: pw.TextStyle(fontSize: 80, color: PdfColors.grey200, font: boldFont),
                ),
              ),
            );
          },
        ),
        build: (context) => [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  '${clientPlan.name} (for ${clientPlan.days.length} Day Cycle) - Meal Plan',
                  style: pw.TextStyle(fontSize: 18, font: boldFont, color: PdfColors.deepOrange),
                ),
              ),
              pw.SizedBox(height: 15),
              ...clientPlan.days.map((day) {
                final index = clientPlan.days.indexOf(day);
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 8.0),
                      child: pw.Text(
                        'Day ${index + 1}: ${day.dayName}',
                        style: pw.TextStyle(font: boldFont, fontSize: 13, color: PdfColors.indigo700),
                      ),
                    ),
                    _buildDayPlanTable(day, boldFont, regularFont),
                    pw.SizedBox(height: 20),
                  ],
                );
              }).toList(),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }

  // ... (Keep ALL other static widget builder methods exactly as they were: _buildFirstPageContent, _buildHeader, etc.) ...
  // ... Ensure _buildFirstPageContent and _buildHeader accept 'AdminProfileModel info' which they already do. ...

  // COPY PASTE THE REST OF THE UTILITY METHODS FROM YOUR PREVIOUS FILE HERE
  // (omitted for brevity, they don't need changes)

  static pw.Widget _buildFirstPageContent({
    required ClientModel client,
    required AdminProfileModel info,
    VitalsModel? vitals,
    required List<DiagnosisMasterModel> diagnosisList,
    required pw.Font boldFont,
    required pw.Font regularFont,
    required String reportType,
    required int followUpDays,
    required List<String> clientComplaints,
    required List<String> medicalHistory,
    required List<String> existingMedications,
    required List<String> allergiesRestrictions,
    required List<InvestigationMasterModel> investigationRequired,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildHeader(client, info, boldFont, regularFont),
        pw.SizedBox(height: 20),
        _buildReportMetadata(reportType, followUpDays, boldFont, regularFont),
        pw.SizedBox(height: 20),
        _buildClientInfoBlock(client, boldFont, regularFont),
        pw.SizedBox(height: 30),
        pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(child: _buildComplaintsSection(clientComplaints, boldFont, regularFont)),
              pw.SizedBox(width: 20),
              pw.Expanded(child: _buildDiagnosisSection(diagnosisList, boldFont, regularFont)),
            ]
        ),
        pw.SizedBox(height: 30),
        if (vitals != null) ...[
          _buildVitalsSection(vitals, boldFont, regularFont),
          pw.SizedBox(height: 30),
        ] else
          pw.Text('No recent vitals record found.', style: pw.TextStyle(font: regularFont, color: PdfColors.grey)),
        _buildInvestigationsSection(investigationRequired, boldFont, regularFont),
        pw.Expanded(child: pw.SizedBox.shrink()),
        pw.Container(
            padding: const pw.EdgeInsets.only(top: 20),
            alignment: pw.Alignment.bottomLeft,
            child: pw.Text(
              '**Please turn over for the personalized meal plan.**',
              style: pw.TextStyle(font: boldFont, fontSize: 11),
            )),
      ],
    );
  }

  // ... Include all other helpers (_buildHeader, _buildFooterSection, _buildDayPlanTable, etc.) from previous file ...
  // Be sure _buildHeader uses 'info' correctly.

  static pw.Widget _buildHeader(ClientModel client, AdminProfileModel info, pw.Font boldFont, pw.Font font) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 100, height: 30,
              child: pw.Center(child: pw.Text(info.companyName, style: pw.TextStyle(fontSize: 14, font: boldFont, color: PdfColors.indigo))),
            ),
            pw.SizedBox(height: 5),
            pw.Text('Certified Dietitian: ${info.firstName} ${info.lastName}', style: pw.TextStyle(fontSize: 10, font: font, color: PdfColors.grey700)),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text('Contact:', style: pw.TextStyle(fontSize: 10, font: boldFont, color: PdfColors.grey700)),
            pw.Text('Email: ${info.email}', style: const pw.TextStyle(fontSize: 9)),
            pw.Text('Phone: ${info.mobile}', style: const pw.TextStyle(fontSize: 9)),
            pw.Text('Web: ${info.website}', style: const pw.TextStyle(fontSize: 9)),
            pw.SizedBox(height: 5),
            pw.Text('Date: ${DateFormat('MMM dd, yyyy').format(DateTime.now())}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey)),
          ],
        ),
      ],
    );
  }

  // (Paste remaining helpers here exactly as before)
  static pw.Widget _buildReportMetadata(String reportType, int followUpDays, pw.Font boldFont, pw.Font font) {
    return pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: pw.BorderRadius.circular(5)),
        child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.RichText(text: pw.TextSpan(children: [pw.TextSpan(text: 'Report Type: ', style: pw.TextStyle(font: boldFont, fontSize: 10, color: PdfColors.grey700)), pw.TextSpan(text: reportType.toUpperCase(), style: pw.TextStyle(font: boldFont, fontSize: 11, color: reportType.toUpperCase() == 'FINAL' ? PdfColors.green700 : PdfColors.orange700))])),
          pw.RichText(text: pw.TextSpan(children: [pw.TextSpan(text: 'Follow Up: ', style: pw.TextStyle(font: boldFont, fontSize: 10, color: PdfColors.grey700)), pw.TextSpan(text: '$followUpDays Days', style: pw.TextStyle(font: boldFont, fontSize: 11, color: PdfColors.blue700))])),
        ])
    );
  }

  static pw.Widget _buildClientInfoBlock(ClientModel client, pw.Font boldFont, pw.Font font) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(color: PdfColors.indigo50, borderRadius: pw.BorderRadius.circular(5), border: pw.Border.all(color: PdfColors.indigo200, width: 0.5)),
      child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceAround, children: [
        pw.Row(children: [pw.Text('Patient: ', style: pw.TextStyle(fontSize: 12, font: font, color: PdfColors.indigo700)), pw.Text(client.name, style: pw.TextStyle(fontSize: 16, font: boldFont, color: PdfColors.indigo800))]),
        pw.Row(children: [pw.Text('Age: ', style: pw.TextStyle(fontSize: 12, font: font, color: PdfColors.grey700)), pw.Text('${client.age}', style: pw.TextStyle(fontSize: 12, font: boldFont, color: PdfColors.black))]),
        pw.Row(children: [pw.Text('Gender: ', style: pw.TextStyle(fontSize: 12, font: font, color: PdfColors.grey700)), pw.Text(client.gender, style: pw.TextStyle(fontSize: 12, font: boldFont, color: PdfColors.black))]),
      ]),
    );
  }

  static pw.Widget _buildComplaintsSection(List<String> complaints, pw.Font boldFont, pw.Font font) {
    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [_buildSectionTitle('Primary Complaints', boldFont, color: PdfColors.red700, size: 12), ...complaints.map((c) => pw.Padding(padding: const pw.EdgeInsets.only(bottom: 4), child: _buildListItem(c, font, color: PdfColors.red800))).toList()]);
  }

  static pw.Widget _buildDiagnosisSection(List<DiagnosisMasterModel> diagnosisNames, pw.Font boldFont, pw.Font font) {
    if (diagnosisNames.isEmpty) return pw.SizedBox.shrink();
    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      _buildSectionTitle('Primary Diagnosis', boldFont, color: PdfColors.red700, size: 12),
      pw.Wrap(spacing: 8, runSpacing: 5, children: diagnosisNames.map((name) => pw.Container(padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: pw.BoxDecoration(color: PdfColors.red50, borderRadius: pw.BorderRadius.circular(4), border: pw.Border.all(color: PdfColors.red200, width: 0.5)), child: pw.Text(name.enName, style: pw.TextStyle(fontSize: 10, font: boldFont, color: PdfColors.red800)))).toList()),
    ]);
  }

  static pw.Widget _buildVitalsSection(VitalsModel vitals, pw.Font boldFont, pw.Font font) {
    // (Existing Vitals Logic)
    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [_buildSectionTitle('Vitals Captured', boldFont), pw.Text("Height: ${vitals.heightCm} cm | Weight: ${vitals.weightKg} kg | BMI: ${vitals.bmi.toStringAsFixed(1)}", style: pw.TextStyle(font: font, fontSize: 10))]);
  }

  static pw.Widget _buildInvestigationsSection(List<InvestigationMasterModel> items, pw.Font boldFont, pw.Font font) {
    return pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.blueGrey300, width: 0.5), borderRadius: pw.BorderRadius.circular(5)),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [_buildSectionTitle('Investigations Required', boldFont, color: PdfColors.indigo700, size: 13), ...items.map((i) => _buildListItem(i.enName, font)).toList()])
    );
  }

  static pw.Widget _buildSectionTitle(String title, pw.Font boldFont, {PdfColor color = PdfColors.indigo, double size = 14}) {
    return pw.Padding(padding: const pw.EdgeInsets.only(top: 10, bottom: 5), child: pw.Text(title, style: pw.TextStyle(fontSize: size, font: boldFont, color: color)));
  }

  static pw.Widget _buildListItem(String text, pw.Font font, {PdfColor color = PdfColors.black}) {
    return pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Container(width: 3, height: 3, margin: const pw.EdgeInsets.only(right: 5, top: 4), decoration: pw.BoxDecoration(color: color, shape: pw.BoxShape.circle)),
      pw.Expanded(child: pw.Text(text, style: pw.TextStyle(fontSize: 10, font: font, color: color)))
    ]);
  }

  static pw.Widget _buildFooterSection(AdminProfileModel info, List<Guideline> guidelines, pw.Font boldFont, pw.Font font, bool isLastPage) {
    // (Keep previous footer logic, ensuring 'info' is used)
    if (!isLastPage) return pw.Container(alignment: pw.Alignment.topRight, child: pw.Text('Page', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)));

    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      _buildSectionTitle('General Guidelines', boldFont),
      ...guidelines.map((g) => _buildListItem(g.enTitle, font)).toList(),
      pw.SizedBox(height: 15),
      pw.Divider(color: PdfColors.grey400),
      pw.Container(padding: const pw.EdgeInsets.all(10), decoration: pw.BoxDecoration(borderRadius: pw.BorderRadius.circular(6), color: PdfColor.fromHex('FFF5F5')), child: pw.Text(_declarationText.replaceAll('[CompanyName]', info.companyName), style: pw.TextStyle(fontSize: 10, font: font, color: PdfColors.grey800))),
      pw.SizedBox(height: 20),
      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
        pw.Text('Page', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
          pw.Container(width: 150, height: 1, color: PdfColors.black, margin: const pw.EdgeInsets.only(bottom: 5)),
          pw.Text('Signature of ${info.firstName} ${info.lastName}', style: pw.TextStyle(fontSize: 10, font: boldFont)),
        ])
      ])
    ]);
  }

  static pw.Widget _buildDayPlanTable(MasterDayPlanModel day, pw.Font boldFont, pw.Font font) {
    // (Keep existing table logic)
    return pw.Table(border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5), children: [
      pw.TableRow(decoration: const pw.BoxDecoration(color: PdfColors.indigo600), children: [
        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Item', style: pw.TextStyle(font: boldFont, color: PdfColors.white, fontSize: 10))),
        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Qty', style: pw.TextStyle(font: boldFont, color: PdfColors.white, fontSize: 10))),
      ]),
      ...day.meals.expand((m) => m.items.map((i) => pw.TableRow(children: [
        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("${m.mealName}: ${i.foodItemName}", style: pw.TextStyle(font: font, fontSize: 10))),
        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("${i.quantity} ${i.unit}", style: pw.TextStyle(font: font, fontSize: 10))),
      ])))
    ]);
  }
}