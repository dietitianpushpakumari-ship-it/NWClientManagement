// lib/services/diet_plan_pdf_generator.dart (COMPREHENSIVE CLINICAL REPORT STRUCTURE)

import 'dart:typed_data';
import 'dart:math';
import 'package:nutricare_client_management/admin/admin_profile_model.dart';
import 'package:nutricare_client_management/admin/admin_profile_service.dart';
import 'package:nutricare_client_management/modules/client/model/client_diet_plan_model.dart';
import 'package:nutricare_client_management/modules/client/model/client_model.dart';
import 'package:nutricare_client_management/modules/client/model/vitals_model.dart';
import 'package:nutricare_client_management/modules/client/screen/investigation_master_model.dart';
import 'package:nutricare_client_management/modules/client/screen/investigation_master_service.dart';
import 'package:nutricare_client_management/modules/client/services/vitals_service.dart';
import 'package:nutricare_client_management/modules/master/model/diagonosis_master.dart';
import 'package:nutricare_client_management/modules/master/model/diet_plan_item_model.dart';
import 'package:nutricare_client_management/modules/master/model/guidelines.dart';
import 'package:nutricare_client_management/modules/master/service/diagonosis_master_service.dart';
import 'package:nutricare_client_management/modules/master/service/guideline_service.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

// MOCK/STUB: Data Structures
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
    'pp_glucose': LabTest(displayName: 'Postprandial Glucose', unit: 'mg/dL', category: 'Blood Sugar', referenceRange: '< 140'),
    'hba1c': LabTest(displayName: 'HbA1c', unit: '%', category: 'Blood Sugar', referenceRange: '4.0 - 5.6'),
    'total_cholesterol': LabTest(displayName: 'Total Cholesterol', unit: 'mg/dL', category: 'Lipid Profile', referenceRange: '< 200'),
  };
}




class DietPlanPdfGenerator {
  static const String _declarationText =
      "**CLINICAL DIETITIAN DECLARATION:** I, the undersigned Registered Dietitian, affirm that this diet plan is meticulously prepared based on a thorough assessment of the client's current health status, comprehensive medical and dietary history, lab reports, and defined nutritional requirements. This document serves as a personalized clinical recommendation and must be used in conjunction with and should not replace advice from a primary healthcare provider or physician.";


  static Future<Uint8List> generatePlanPdf({
    required ClientDietPlanModel clientPlan,
    required ClientModel client,
    // ------------------------------------------------------------------------
  }) async {
    final pdf = pw.Document(title: clientPlan.name);

    final regularFont = await PdfGoogleFonts.openSansRegular();
    final boldFont = await PdfGoogleFonts.openSansBold();

    VitalsService vitalsService = VitalsService();

    final vitalsList = await vitalsService.getClientVitals(client.id);
    final VitalsModel? vitals = vitalsList.isNotEmpty ? vitalsList.first : null;

    final guidelineList = await GuidelineService().fetchGuidelinesByIds(clientPlan.guidelineIds);
    final diagnosisList = await DiagnosisMasterService().fetchAllDiagnosisMasterByIds(clientPlan.diagnosisIds);
    final investigationList =  await InvestigationMasterService().fetchAllInvestigationMasterByIds(clientPlan.investigationIds);

    final  dietitianInfo = await AdminProfileService().fetchAdminProfile();

    String reportType = clientPlan.isProvisional ?  'Provisional' : '';
        int? followUpDays = clientPlan.followUpDays;
    List<String> medicalHistory = [] ;//vitals!.medicalHistoryDurations!.split(',').toList();
    List<String> existingMedications = vitals!.existingMedication!.split(',').toList();
    List<String> allergiesRestrictions = vitals!.foodAllergies!.split(',').toList();
    List<InvestigationMasterModel> investigationRequired = investigationList;
    List<String> clientComplaints = clientPlan.complaints.split(',').toList();


    // --------------------------------------------------------
    // --- 1. FIRST PAGE: CLINICAL REPORT SUMMARY (pw.Page) ---
    // --------------------------------------------------------
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
                  dietitianInfo!.companyName,
                  style: pw.TextStyle(
                    fontSize: 80,
                    color: PdfColors.grey200,
                    font: boldFont,
                  ),
                ),
              ),
            );
          },
        ),
        build: (context) => _buildFirstPageContent(
          client: client,
          info: dietitianInfo,
          vitals: vitals,
          diagnosisList: diagnosisList,
          boldFont: boldFont,
          regularFont: regularFont,
          reportType: reportType,
          followUpDays: followUpDays!,
          clientComplaints: clientComplaints,
          medicalHistory: medicalHistory,
          existingMedications: existingMedications,
          allergiesRestrictions: allergiesRestrictions,
          investigationRequired: investigationRequired,
        ),
      ),
    );


    // --------------------------------------------------------
    // --- 2. SECOND PAGE ONWARDS: MEAL PLAN (pw.MultiPage) ---
    // --------------------------------------------------------
    pdf.addPage(
      pw.MultiPage(
        footer: (context) {
          return _buildFooterSection(
              dietitianInfo!,
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
                  dietitianInfo!.companyName,
                  style: pw.TextStyle(
                    fontSize: 80,
                    color: PdfColors.grey200,
                    font: boldFont,
                  ),
                ),
              ),
            );
          },
        ),
        build: (context) => [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // --- DIET PLAN TITLE ---
              pw.Center(
                child: pw.Text(
                  '${clientPlan.name} (for ${clientPlan.days.length} Day Cycle) - Meal Plan',
                  style: pw.TextStyle(
                    fontSize: 18,
                    font: boldFont,
                    color: PdfColors.deepOrange,
                  ),
                ),
              ),
              pw.SizedBox(height: 15),

              // --- DIET PLAN CONTENT ---
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

  // ----------------------------------------------------------------------
  // --- NEW WIDGET FOR FIRST PAGE CONTENT ---
  // ----------------------------------------------------------------------

  static pw.Widget _buildFirstPageContent({
    required ClientModel client,
    required AdminProfileModel? info,
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
        // 1. HEADER (Logo and Company Contact Info)
        _buildHeader(client, info!, boldFont, regularFont),
        pw.SizedBox(height: 20),

        // 2. REPORT METADATA
        _buildReportMetadata(reportType, followUpDays, boldFont, regularFont),
        pw.SizedBox(height: 20),

        // 3. CLIENT INFO BLOCK (Name, Age, Gender - Separated)
        _buildClientInfoBlock(client, boldFont, regularFont),
        pw.SizedBox(height: 30),

        // 4. COMPLAINTS & DIAGNOSIS
        pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
             // pw.Expanded(child: _buildComplaintsSection(clientComplaints, boldFont, regularFont)),
              pw.SizedBox(width: 20),
           //   pw.Expanded(child: _buildDiagnosisSection(diagnosisList, boldFont, regularFont)),
            ]
        ),
        pw.SizedBox(height: 30),

        // 5. CLINICAL HISTORY (Medication, History, Allergies)
     /*   pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(child: _buildMedicalHistorySection(medicalHistory, boldFont, regularFont)),
            pw.SizedBox(width: 15),
            pw.Expanded(child: _buildMedicationSection(existingMedications, boldFont, regularFont)),
            pw.SizedBox(width: 15),
            pw.Expanded(child: _buildAllergiesSection(allergiesRestrictions, boldFont, regularFont)),
          ],
        ),*/
        pw.SizedBox(height: 30),

        // 6. VITALS (Body Metrics, IBW, Lab Vitals)
        if (vitals != null) ...[
          _buildVitalsSection(vitals, boldFont, regularFont),
          pw.SizedBox(height: 30),
        ] else
          pw.Text('No recent vitals record found for this client.',
              style: pw.TextStyle(font: regularFont, color: PdfColors.grey)),

        // 7. INVESTIGATION REQUIRED
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

  // ----------------------------------------------------------------------
  // --- NEW WIDGETS FOR REQUESTED SECTIONS ---
  // ----------------------------------------------------------------------

  static pw.Widget _buildReportMetadata(
      String reportType,
      int followUpDays,
      pw.Font boldFont,
      pw.Font font
      ) {
    return pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey100,
          borderRadius: pw.BorderRadius.circular(5),
        ),
        child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.RichText(
                  text: pw.TextSpan(
                      children: [
                        pw.TextSpan(text: 'Report Type: ', style: pw.TextStyle(font: boldFont, fontSize: 10, color: PdfColors.grey700)),
                        pw.TextSpan(text: reportType.toUpperCase(), style: pw.TextStyle(font: boldFont, fontSize: 11, color: reportType.toUpperCase() == 'FINAL' ? PdfColors.green700 : PdfColors.orange700)),
                      ]
                  )
              ),
              pw.RichText(
                  text: pw.TextSpan(
                      children: [
                        pw.TextSpan(text: 'Follow Up Scheduled In: ', style: pw.TextStyle(font: boldFont, fontSize: 10, color: PdfColors.grey700)),
                        pw.TextSpan(text: '$followUpDays Days', style: pw.TextStyle(font: boldFont, fontSize: 11, color: PdfColors.blue700)),
                      ]
                  )
              ),
            ]
        )
    );
  }

  static pw.Widget _buildComplaintsSection(List<String> complaints, pw.Font boldFont, pw.Font font) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Primary Complaints', boldFont, color: PdfColors.red700, size: 12),
        ...complaints.map((complaint) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 4),
          child: _buildListItem(complaint, font, color: PdfColors.red800),
        )).toList(),
      ],
    );
  }

  static pw.Widget _buildMedicalHistorySection(List<String> history, pw.Font boldFont, pw.Font font) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Medical History', boldFont, color: PdfColors.brown700, size: 12),
        ...history.map((item) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 4),
          child: _buildListItem(item, font, color: PdfColors.brown800),
        )).toList(),
      ],
    );
  }

  static pw.Widget _buildMedicationSection(List<String> medications, pw.Font boldFont, pw.Font font) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Existing Medication', boldFont, color: PdfColors.purple700, size: 12),
        ...medications.map((item) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 4),
          child: _buildListItem(item, font, color: PdfColors.purple800),
        )).toList(),
      ],
    );
  }

  static pw.Widget _buildAllergiesSection(List<String> allergies, pw.Font boldFont, pw.Font font) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Allergies/Restrictions', boldFont, color: PdfColors.orange700, size: 12),
        ...allergies.map((item) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 4),
          child: _buildListItem(item, font, color: PdfColors.orange800),
        )).toList(),
      ],
    );
  }

  static pw.Widget _buildInvestigationsSection(List<InvestigationMasterModel> investigations, pw.Font boldFont, pw.Font font) {
    return pw.Container(
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.blueGrey300, width: 0.5),
          borderRadius: pw.BorderRadius.circular(5),
        ),
        padding: const pw.EdgeInsets.all(10),
        child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Investigations Required', boldFont, color: PdfColors.indigo700, size: 13),
              ...investigations.map((item) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: _buildListItem(item.enName, font, color: PdfColors.black),
              )).toList(),
            ]
        )
    );
  }

  static pw.Widget _buildListItem(String text, pw.Font font, {PdfColor color = PdfColors.black}) {
    return pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
              width: 3,
              height: 3,
              margin: const pw.EdgeInsets.only(right: 5, top: 4),
              decoration: pw.BoxDecoration(
                  color: color,
                  shape: pw.BoxShape.circle
              )
          ),
          pw.Expanded(
            child: pw.Text(
              text,
              style: pw.TextStyle(fontSize: 10, font: font, color: color),
            ),
          ),
        ]
    );
  }

  // ----------------------------------------------------------------------
  // --- UTILITY WIDGETS (Slightly modified to include IBW) ---
  // ----------------------------------------------------------------------

  static pw.Widget _buildSectionTitle(String title, pw.Font boldFont, {PdfColor color = PdfColors.indigo, double size = 14}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 10, bottom: 5),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: size,
          font: boldFont,
          color: color,
        ),
      ),
    );
  }

  static pw.Widget _buildHeader(
      ClientModel client, AdminProfileModel info, pw.Font boldFont, pw.Font font) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // LEFT: LOGO
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
           // info.logoBytes != null
             //   ? //pw.Image(pw.MemoryImage(info.logoBytes!), width: 100)
          //      :
          pw.SizedBox(
              width: 100,
              height: 30,
              child: pw.Center(
                child: pw.Text(
                    info.companyName,
                    style: pw.TextStyle(fontSize: 14, font: boldFont, color: PdfColors.indigo)
                ),
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Text(
                'Certified Dietitian: ${info.firstName } ${info.lastName } ',
                style: pw.TextStyle(fontSize: 10, font: font, color: PdfColors.grey700)
            ),
          ],
        ),

        // RIGHT: CONTACT INFORMATION
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

  static pw.Widget _buildClientInfoBlock(
      ClientModel client, pw.Font boldFont, pw.Font font) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.indigo50,
        borderRadius: pw.BorderRadius.circular(5),
        border: pw.Border.all(color: PdfColors.indigo200, width: 0.5),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          pw.Row(children: [
            pw.Text('Patient name: ', style: pw.TextStyle(fontSize: 12, font: font, color: PdfColors.indigo700)),
            pw.Text(client.name, style: pw.TextStyle(fontSize: 16, font: boldFont, color: PdfColors.indigo800)),
          ]),
          pw.Row(children: [
            pw.Text('Age: ', style: pw.TextStyle(fontSize: 12, font: font, color: PdfColors.grey700)),
            pw.Text('${client.age}', style: pw.TextStyle(fontSize: 12, font: boldFont, color: PdfColors.black)),
          ]),
          pw.Row(children: [
            pw.Text('Gender: ', style: pw.TextStyle(fontSize: 12, font: font, color: PdfColors.grey700)),
            pw.Text(client.gender, style: pw.TextStyle(fontSize: 12, font: boldFont, color: PdfColors.black)),
          ]),
        ],
      ),
    );
  }

  static pw.Widget _buildDiagnosisSection(List<DiagnosisMasterModel> diagnosisNames, pw.Font boldFont, pw.Font font) {
    if (diagnosisNames.isEmpty) {
      return pw.SizedBox.shrink();
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Primary Diagnosis', boldFont, color: PdfColors.red700, size: 12),
        pw.Wrap(
          spacing: 8,
          runSpacing: 5,
          children: diagnosisNames.map((name) => pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: pw.BoxDecoration(
              color: PdfColors.red50,
              borderRadius: pw.BorderRadius.circular(4),
              border: pw.Border.all(color: PdfColors.red200, width: 0.5),
            ),
            child: pw.Text(
              name.enName,
              style: pw.TextStyle(fontSize: 10, font: boldFont, color: PdfColors.red800),
            ),
          )).toList(),
        ),
      ],
    );
  }

  static pw.Widget _buildVitalsSection(VitalsModel vitals, pw.Font boldFont, pw.Font font) {
    String formatVitalsValue(double value, {String unit = ''}) {
      if (value == 0.0 || value.isNaN) return 'N/A';
      return '${value.toStringAsFixed(1)}$unit';
    }

    pw.Widget buildVitalsCell(String label, String value) {
      return pw.Expanded(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(value, style: pw.TextStyle(fontSize: 11, font: boldFont, color: PdfColors.blueGrey900)),
            pw.Text(label, style: pw.TextStyle(fontSize: 8, font: font, color: PdfColors.grey600)),
          ],
        ),
      );
    }

    List<pw.Widget> vitalsContent = [];

    // --- BODY VITALS / KEY METRICS (Height, Weight, BMI, IBW) ---
    vitalsContent.add(pw.Text('Key Body Metrics:', style: pw.TextStyle(fontSize: 9, font: boldFont, color: PdfColors.grey700)));
    vitalsContent.add(pw.SizedBox(height: 5));
    vitalsContent.add(pw.Row(
      children: [
        buildVitalsCell('Height', formatVitalsValue(vitals.heightCm, unit: ' cm')),
        buildVitalsCell('Weight', formatVitalsValue(vitals.weightKg, unit: ' kg')),
        buildVitalsCell('BMI', formatVitalsValue(vitals.bmi)),
        buildVitalsCell('IBW', formatVitalsValue(vitals.idealBodyWeightKg, unit: ' kg')), // Include IBW
      ],
    ));

    // --- Suggested Addition: Target Goals ---
    vitalsContent.add(pw.SizedBox(height: 10));

    // --- LAB VITALS SECTION (Grouped Table) ---
    final filteredLabResults = vitals.labResults.entries.where((e) => LabVitalsData.allLabTests.containsKey(e.key)).toList();

    if (filteredLabResults.isNotEmpty) {
      vitalsContent.add(pw.SizedBox(height: 15));

      // Grouping by category
      final Map<String, List<MapEntry<String, String>>> groupedLabs = {};
      for (var entry in filteredLabResults) {
        final category = LabVitalsData.allLabTests[entry.key]?.category ?? 'Other';
        groupedLabs.putIfAbsent(category, () => []).add(entry);
      }

      vitalsContent.add(_buildSectionTitle('Lab Vitals (Grouped)', boldFont, color: PdfColors.teal700));

      for (var category in groupedLabs.keys) {
        vitalsContent.add(pw.SizedBox(height: 10));
        vitalsContent.add(pw.Text(category, style: pw.TextStyle(fontSize: 11, font: boldFont, color: PdfColors.teal800)));
        vitalsContent.add(pw.SizedBox(height: 5));

        final List<List<pw.Widget>> labTableData = [
          [
            pw.Text('Test Name', style: pw.TextStyle(font: boldFont, fontSize: 9, color: PdfColors.white)),
            pw.Text('Result', style: pw.TextStyle(font: boldFont, fontSize: 9, color: PdfColors.white)),
            pw.Text('Reference Range', style: pw.TextStyle(font: boldFont, fontSize: 9, color: PdfColors.white)),
          ],
          ...groupedLabs[category]!.map((entry) {
            final testKey = entry.key;
            final testValue = entry.value;
            final LabTest? testInfo = LabVitalsData.allLabTests[testKey];

            return [
              pw.Text(testInfo?.displayName ?? testKey, style: pw.TextStyle(fontSize: 9, font: font)),
              pw.Text('$testValue ${testInfo?.unit ?? ''}', style: pw.TextStyle(fontSize: 9, font: boldFont)),
              pw.Text(testInfo?.referenceRange ?? 'N/A', style: const pw.TextStyle(fontSize: 9)),
            ];
          }).toList(),
        ];

        vitalsContent.add(
          pw.Table.fromTextArray(
            headers: labTableData.first.map((w) => (w as pw.Text).text).toList(),
            data: labTableData.sublist(1).map((row) => row.map((w) => (w as pw.Text).text).toList()).toList(),
            headerStyle: pw.TextStyle(font: boldFont, fontSize: 9, color: PdfColors.white),
            cellStyle: pw.TextStyle(font: font, fontSize: 9),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.teal600),
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(2.5),
              1: const pw.FlexColumnWidth(1.5),
              2: const pw.FlexColumnWidth(2),
            },
          ),
        );
      }
    }


    // --- LIFESTYLE HABITS ---
    if (vitals.foodHabit != null || vitals.activityType != null || vitals.otherLifestyleHabits?.isNotEmpty == true) {
      vitalsContent.add(pw.SizedBox(height: 15));
      vitalsContent.add(pw.Text('Lifestyle Habits:', style: pw.TextStyle(fontSize: 9, font: boldFont, color: PdfColors.grey700)));
      vitalsContent.add(pw.SizedBox(height: 5));
      if (vitals.foodHabit != null)
        vitalsContent.add(pw.Text('• Food: ${vitals.foodHabit}', style: pw.TextStyle(fontSize: 9, font: font)));
      if (vitals.activityType != null)
        vitalsContent.add(pw.Text('• Activity: ${vitals.activityType}', style: pw.TextStyle(fontSize: 9, font: font)));

      final otherHabitEntries = vitals.otherLifestyleHabits?.entries.where((e) => e.value.isNotEmpty).toList();
      if (otherHabitEntries?.isNotEmpty == true) {
        vitalsContent.add(pw.Text('• Others: ${otherHabitEntries!.map((e) => '${e.key.replaceAll('Status', '')}: ${e.value}').join(', ')}', style: pw.TextStyle(fontSize: 9, font: font)));
      }
    }


    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Vitals Captured (${DateFormat('MMM dd, yyyy').format(vitals.date)})', boldFont),
        ...vitalsContent,
      ],
    );
  }

  static pw.Widget _buildDayPlanTable(MasterDayPlanModel day, pw.Font boldFont, pw.Font font) {
    // ... (rest of _buildDayPlanTable remains the same)
    List<pw.TableRow> tableRows = [];

    // Header Row
    tableRows.add(
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.indigo600),
          children: [
            pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8), child: pw.Text('Food Item / Choice', style: pw.TextStyle(font: boldFont, fontSize: 10, color: PdfColors.white))),
            pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8), child: pw.Text('Qty/Unit', style: pw.TextStyle(font: boldFont, fontSize: 10, color: PdfColors.white))),
          ],
        )
    );

    // Data Rows
    for (var meal in day.meals) {
      // Meal header row for visual grouping
      if (meal.items.isNotEmpty) {
        tableRows.add(
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.blueGrey100),
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Text(meal.mealName, style: pw.TextStyle(font: boldFont, fontSize: 10, color: PdfColors.blueGrey800)),
                ),
                pw.Container(),
              ],
            )
        );
      }

      // Meal items rows
      for (var item in meal.items) {
        final List<String> alternativesList = item.alternatives
            .map((e) => e.foodItemName.trim() + ' ('+(e.quantity.toStringAsFixed(2) +' '+e.unit)+')')
            .where((e) => e.isNotEmpty)
            .toList();

        final List<pw.InlineSpan> foodCellChildren = [];

        // 1. Primary Food Item
        foodCellChildren.add(pw.TextSpan(
          text: item.foodItemName,
          style: pw.TextStyle(font: boldFont, fontSize: 10, color: PdfColors.black),
        ));

        // 2. Alternatives
        if (alternativesList.isNotEmpty) {
          foodCellChildren.add(pw.TextSpan(
            text: '\n(OR Choose from: ',
            style: pw.TextStyle(fontSize: 8, font: font, color: PdfColors.grey600),
          ));
          foodCellChildren.add(pw.TextSpan(
            text: alternativesList.join(' / '),
            style: pw.TextStyle(fontSize: 9, font: font, color: PdfColors.green700),
          ));
          foodCellChildren.add(pw.TextSpan(
            text: ')',
            style: pw.TextStyle(fontSize: 8, font: font, color: PdfColors.grey600),
          ));
        }

        tableRows.add(
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.white),
              children: [
                // Food Item / Alternative Cell
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  alignment: pw.Alignment.centerLeft,
                  child: pw.RichText(text: pw.TextSpan(children: foodCellChildren)),
                ),

                // Quantity/Unit Cell
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Text('${item.quantity} ${item.unit}', style: const pw.TextStyle(fontSize: 10)),
                ),
              ],
            )
        );
      }
    }

    // Render the Table
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(4), // Food Item / Choice
        1: const pw.FlexColumnWidth(1), // Qty/Unit
      },
      children: tableRows,
    );
  }

  static pw.Widget _buildFooterSection(
      AdminProfileModel info,
      List<Guideline> guidelines,
      pw.Font boldFont,
      pw.Font font,
      bool isLastPage
      ) {
    // Correct widget usage for page numbers
    pw.Widget pageNumberWidget = pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text('Page ', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),

        //  pw.PageNumber(), // Widget
          pw.Text(' of ', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
          //pw.PagesCount(), // Widget
        ],
      ),
    );

    if (isLastPage) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // 1. Guidelines Section
          _buildGuidelinesSection(guidelines, boldFont, font),
          pw.SizedBox(height: 15),

          // 2. Declaration/Disclaimer
          pw.Divider(color: PdfColors.grey400),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              borderRadius: pw.BorderRadius.circular(6),
              color: PdfColor.fromHex('FFF5F5'),
            ),
            child: pw.RichText(
              text: pw.TextSpan(
                style: pw.TextStyle(
                  fontSize: 10,
                  font: font,
                  color: PdfColors.grey800,
                  lineSpacing: 1.5,
                ),
                children: [
                  pw.TextSpan(
                    text: _declarationText.replaceAll('[CompanyName]', info.companyName),
                  ),
                ],
              ),
            ),
          ),
          pw.SizedBox(height: 20),

          // 3. Signature area
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pageNumberWidget,
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Container(
                    width: 150,
                    height: 1,
                    color: PdfColors.black,
                    margin: const pw.EdgeInsets.only(bottom: 5),
                  ),
                  pw.Text(
                    'Signature of ${info.firstName} ${info.lastName}',
                    style: pw.TextStyle(fontSize: 10, font: boldFont),
                  ),
                  pw.Text(
                    info.mobile,
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
                  ),
                ],
              ),
            ],
          ),
        ],
      );
    }

    // For all other pages, just show the page number widget
    return pw.Container(
      alignment: pw.Alignment.topRight,
      child: pageNumberWidget,
    );
  }

  static pw.Widget _buildGuidelinesSection(List<Guideline> guidelines, pw.Font boldFont, pw.Font font) {
    if (guidelines.isEmpty) {
      return pw.SizedBox.shrink();
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('General Guidelines', boldFont),
        ...guidelines.map((guideline) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 8),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(children: [
                pw.Container(width: 4, height: 4, margin: const pw.EdgeInsets.only(right: 5), decoration: pw.BoxDecoration(color: PdfColors.indigo, shape: pw.BoxShape.circle)),
                pw.Text(
                  guideline.enTitle,
                  style: pw.TextStyle(fontSize: 10, font: boldFont, color: PdfColors.grey800),
                ),
              ]),
             // pw.Padding(
               // padding: const pw.EdgeInsets.only(left: 10, top: 2),
               // child: pw.Text(
                //  guideline.content,
                //  style: pw.TextStyle(fontSize: 9, font: font, color: PdfColors.grey700, lineSpacing: 1.2),
               // ),
             // ),
            ],
          ),
        )).toList(),
      ],
    );
  }
}