import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// 🎯 IMPORTS
import 'package:nutricare_client_management/admin/client_consultation_summary_page.dart';
import 'package:nutricare_client_management/admin/clinical_prescription_printer.dart';
import 'package:nutricare_client_management/admin/database_provider.dart';
import 'package:nutricare_client_management/admin/generic_service.dart';
import 'package:nutricare_client_management/master/model/master_constants.dart';
import 'package:nutricare_client_management/master_diet_planner/complex_input_widgets.dart';
import 'package:nutricare_client_management/master_diet_planner/generic_multi_select_dialogg.dart';
import 'package:nutricare_client_management/modules/client/model/client_model.dart';
import 'package:nutricare_client_management/modules/client/model/vitals_model.dart';
import 'package:nutricare_client_management/admin/labvital/global_service_provider.dart';
import 'package:nutricare_client_management/modules/medical/models/prescription_model.dart';

// ==============================================================================
// 1. PROVIDERS
// ==============================================================================

final clinicalComplaintDataProvider = FutureProvider.autoDispose<Map<String, String>>((ref) async {
  final service = ref.watch(masterDataServiceProvider);
  return await service.fetchMasterList(MasterCollectionMapper.getPath(MasterEntity.entity_Complaint));
});

final nutritionDiagnosisDataProvider = FutureProvider.autoDispose<Map<String, String>>((ref) async {
  final service = ref.watch(masterDataServiceProvider);
  return await service.fetchMasterList(MasterCollectionMapper.getPath(MasterEntity.entity_Diagnosis));
});

final clinicalNoteCategoryDataProvider = FutureProvider.autoDispose<Map<String, String>>((ref) async {
  final service = ref.watch(masterDataServiceProvider);
  return await service.fetchMasterList(MasterCollectionMapper.getPath(MasterEntity.entity_Clinicalnotes));
});

// 🎯 GUIDELINES PROVIDER
final clinicalGuidelineDataProvider = FutureProvider.autoDispose<Map<String, String>>((ref) async {
  final service = ref.watch(masterDataServiceProvider);
  // Using entity_Guidelines if available, else falling back to Notes or generic master
  return await service.fetchMasterList(MasterCollectionMapper.getPath(MasterEntity.entity_Guidelines));
});

final investigationDataProvider = FutureProvider.autoDispose<Map<String, String>>((ref) async {
  final service = ref.watch(investigationMasterServiceProvider);
  final list = await service.fetchActiveItems();
  return {for (var e in list) e.name: e.id};
});

final supplementDataProvider = FutureProvider.autoDispose<Map<String, String>>((ref) async {
  final service = ref.watch(supplimentMasterServiceProvider);
  final list = await service.fetchActiveItems();
  return {for (var e in list) e.name: e.id};
});

// ==============================================================================
// 2. SCREEN
// ==============================================================================

class ClientClinicalAssessmentSheet extends ConsumerStatefulWidget {
  final VitalsModel? latestVitals;
  final Function(Map<String, dynamic> assessmentData) onSaveAssessment;
  final String? sessionId;
  final bool isReadOnly;
  final ClientModel client;

  const ClientClinicalAssessmentSheet({
    super.key,
    this.latestVitals,
    required this.onSaveAssessment,
    this.sessionId,
    required this.client,
    this.isReadOnly = false,
  });

  @override
  ConsumerState<ClientClinicalAssessmentSheet> createState() => _ClientClinicalAssessmentSheetState();
}

class _ClientClinicalAssessmentSheetState extends ConsumerState<ClientClinicalAssessmentSheet> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // --- STATE VARIABLES ---
  late Map<String, String> _clinicalComplaints;
  late Map<String, String> _nutritionDiagnoses;
  late Map<String, String> _clinicalNotes;

  // 🎯 NEW: GUIDELINES STATE
  late Map<String, String> _clinicalGuidelines;

  List<String> _noteCategoryKeys = [];
  final Map<String, TextEditingController> _noteControllers = {};

  List<PrescribedMedicine> _medications = [];
  List<String> _labTests = [];

  String _followUpText = "Not specified";
  DateTime? _selectedFollowUpDate;

  @override
  void initState() {
    super.initState();
    _initializeRestoration();
  }

  void _initializeRestoration() {
    final v = widget.latestVitals;

    // 1. Complaints
    if (v?.clinicalComplaints != null) {
      _clinicalComplaints = Map<String, String>.from(v!.clinicalComplaints!);
    } else {
      _clinicalComplaints = {};
    }

    // 2. Diagnosis
    if (v?.nutritionDiagnoses != null) {
      _nutritionDiagnoses = Map<String, String>.from(v!.nutritionDiagnoses!);
    } else {
      _nutritionDiagnoses = {};
    }

    // 3. Notes
    _clinicalNotes = Map<String, String>.from(v?.clinicalNotes ?? {});
    _noteCategoryKeys = _clinicalNotes.keys.toList();
    _clinicalNotes.forEach((key, value) {
      _noteControllers[key] = TextEditingController(text: value == 'Not specified' ? '' : value);
    });

    // 🎯 4. Restore Guidelines
    _clinicalGuidelines = Map<String, String>.from(v?.clinicalGuidelines ?? {});

    // 5. Follow-up Logic (Check Notes for Legacy or Guidelines)
    if (_clinicalNotes.containsKey('Next Review')) {
      _followUpText = _clinicalNotes['Next Review']!;
      _noteControllers.remove('Next Review');
      _noteCategoryKeys.remove('Next Review');
      _clinicalNotes.remove('Next Review');
    }

    // 6. Lists
    if (v != null) {
      _medications = List.from(v.medications);
      _labTests = List.from(v.labTestOrders);
    }
  }

  @override
  Widget build(BuildContext context) {
    final complaintsAsync = ref.watch(clinicalComplaintDataProvider);
    final diagnosisAsync = ref.watch(nutritionDiagnosisDataProvider);
    final notesAsync = ref.watch(clinicalNoteCategoryDataProvider);
    final investigationsAsync = ref.watch(investigationDataProvider);
    final supplementsAsync = ref.watch(supplementDataProvider);
    final guidelinesAsync = ref.watch(clinicalGuidelineDataProvider); // 🎯 Watch Guidelines

    if (complaintsAsync.isLoading || diagnosisAsync.isLoading || notesAsync.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      body: CustomScrollView(
        slivers: [
          _buildPremiumHeader(guidelinesAsync.value ?? {}),
          SliverToBoxAdapter(
            child: Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // --- 1. COMPLAINTS ---
                    _buildPremiumCard("Primary Complaints", Icons.personal_injury, Colors.deepOrange, [
                      _buildAddAction("Select Complaints", () => _openSelection(title: "Complaints", masterData: complaintsAsync.value!, currentMap: _clinicalComplaints, section: 'complaint', defaultValue: "Not specified", provider: clinicalComplaintDataProvider, collectionPath: MasterCollectionMapper.getPath(MasterEntity.entity_Complaint))),
                      if (_clinicalComplaints.isEmpty) _buildEmptyText("No complaints recorded."),
                      ..._clinicalComplaints.entries.map((e) => _buildDetailCard(
                        title: e.key,
                        detail: e.value,
                        placeholder: "Tap to add details",
                        color: Colors.deepOrange,
                        icon: Icons.sick,
                        onTap: () => _openTextSheet(title: "Details", key: e.key, currentVal: e.value, section: 'complaint'),
                        onDelete: () => setState(() => _clinicalComplaints.remove(e.key)),
                      )),
                    ]),
                    // --- 2. DIAGNOSIS ---
                    _buildPremiumCard("Diagnosis", Icons.assignment_late, Colors.indigo, [
                      _buildAddAction("Identify Diagnoses", () => _openSelection(title: "Diagnoses", masterData: diagnosisAsync.value!, currentMap: _nutritionDiagnoses, section: 'diagnosis', defaultValue: "Not specified", provider: nutritionDiagnosisDataProvider, collectionPath: MasterCollectionMapper.getPath(MasterEntity.entity_Diagnosis))),
                      if (_nutritionDiagnoses.isEmpty) _buildEmptyText("No diagnosis recorded."),
                      ..._nutritionDiagnoses.entries.map((e) => _buildDetailCard(
                        title: e.key,
                        detail: e.value,
                        placeholder: "Tap to add details",
                        color: Colors.indigo,
                        icon: Icons.assignment_ind,
                        onTap: () => _openTextSheet(title: "Details", key: e.key, currentVal: e.value, section: 'diagnosis'),
                        onDelete: () => setState(() => _nutritionDiagnoses.remove(e.key)),
                      )),
                    ]),

                    // --- 3. MEDICATIONS ---
                    _buildPremiumCard("Rx Medications", Icons.medication, Colors.blue, [
                      if (!widget.isReadOnly) Row(children: [Expanded(child: ElevatedButton.icon(onPressed: () => _openBatchSupplementSelector(supplementsAsync.value ?? {}), icon: const Icon(Icons.playlist_add_check, size: 20), label: const Text("Select from Master"), style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade50, foregroundColor: Colors.blue, elevation: 0))), const SizedBox(width: 8), Expanded(child: OutlinedButton.icon(onPressed: () => _openMedicineConfigSheet(index: null), icon: const Icon(Icons.add, size: 18), label: const Text("Manual Add"), style: OutlinedButton.styleFrom(foregroundColor: Colors.blue)))]),
                      if (_medications.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(16), child: Text("No medications added.", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)))),
                      ..._medications.asMap().entries.map((e) => _buildSwipeableMedication(e.key, e.value)),
                    ]),

                    // --- 4. INVESTIGATIONS ---
                    _buildPremiumCard("Investigations", Icons.science, Colors.teal, [
                      if (!widget.isReadOnly) ElevatedButton.icon(onPressed: () => _openLabSelector(investigationsAsync.value ?? {}), icon: const Icon(Icons.search, size: 18), label: const Text("Select Investigations"), style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade50, foregroundColor: Colors.teal, elevation: 0)),
                      const SizedBox(height: 12),
                      Wrap(spacing: 8, children: _labTests.map((l) => Chip(label: Text(l), backgroundColor: Colors.teal.shade50, labelStyle: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold), onDeleted: widget.isReadOnly ? null : () => setState(() => _labTests.remove(l)), deleteIconColor: Colors.teal)).toList())
                    ]),

                    // 🎯 5. CLINICAL GUIDELINES (NEW CARD) ---
                    _buildPremiumCard("Clinical Guidelines", Icons.menu_book, Colors.teal.shade800, [
                      if(!widget.isReadOnly) _buildAddAction("Select Guidelines", () => _openGuidelinesDialog(guidelinesAsync.value ?? {})),
                      if (_clinicalGuidelines.isEmpty) _buildEmptyText("No standard guidelines selected."),
                      ..._clinicalGuidelines.entries.map((e) => _buildSwipeableGuideline(e.key, e.value)),
                    ]),

                    // --- 6. NOTES ---
                    _buildPremiumCard("Clinical Notes", Icons.description, Colors.blueGrey, [
                      _buildAddAction("Manage Categories", () => _openSelection(title: "Notes", masterData: notesAsync.value!, currentMap: _clinicalNotes, section: 'notes', defaultValue: "", provider: clinicalNoteCategoryDataProvider, collectionPath: MasterCollectionMapper.getPath(MasterEntity.entity_Clinicalnotes))),
                      if (_clinicalNotes.isEmpty) _buildEmptyText("No notes added."),
                      ..._clinicalNotes.entries.map((e) => _buildDetailCard(
                        title: e.key,
                        detail: e.value,
                        placeholder: "Tap to write note...",
                        color: Colors.blueGrey,
                        icon: Icons.note_alt,
                        onTap: () => _openTextSheet(title: "Note: ${e.key}", key: e.key, currentVal: e.value, section: 'notes', isLongText: true),
                        onDelete: () => setState(() { _clinicalNotes.remove(e.key); _noteCategoryKeys.remove(e.key); }),
                      )),
                    ]),

                    // --- 7. FOLLOW UP ---
                    _buildPremiumCard("Follow-up Plan", Icons.event_repeat, Colors.purple, [
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        _buildFollowUpChip("7 Days", 7), _buildFollowUpChip("15 Days", 15), _buildFollowUpChip("1 Month", 30), _buildFollowUpChip("SOS", null),
                        ActionChip(avatar: const Icon(Icons.calendar_month, size: 16, color: Colors.purple), label: const Text("Pick Date"), backgroundColor: Colors.purple.shade50, side: BorderSide.none, onPressed: widget.isReadOnly ? null : _pickFollowUpDate)
                      ]),
                      const SizedBox(height: 16),
                      Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.purple.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.purple.shade100)), child: Row(children: [const Icon(Icons.notifications_active_outlined, color: Colors.purple), const SizedBox(width: 12), Expanded(child: Text(_followUpText, style: TextStyle(color: Colors.purple.shade900, fontWeight: FontWeight.bold))), if(_followUpText != "Not specified" && !widget.isReadOnly) IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () => setState(() => _followUpText = "Not specified"))]))
                    ]),

                    const SizedBox(height: 30),
                    if (!widget.isReadOnly) _buildSaveButton(),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 💾 SAVE LOGIC
  // ===========================================================================
  Future<void> _save({required bool isPrintMode}) async {
    if (widget.isReadOnly || !_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      // 1. Sync Text Controllers to Map
      _noteControllers.forEach((key, controller) => _clinicalNotes[key] = controller.text.trim().isEmpty ? 'Not specified' : controller.text.trim());

      // 2. Add Follow-up to Notes (Invisible to user in UI lists, visible in map)
      if (_followUpText != "Not specified" && _followUpText.isNotEmpty) {
        _clinicalNotes['Next Review'] = _followUpText;
      }

      // 3. Prepare Data Packet
      final Map<String, dynamic> updateData = {
        'clinicalComplaints': _clinicalComplaints,
        'nutritionDiagnoses': _nutritionDiagnoses,
        'clinicalNotes': _clinicalNotes,
        'clinicalGuidelines': _clinicalGuidelines, // 🎯 SAVE GUIDELINES SEPARATELY
        'medications': _medications.map((m) => m.toMap()).toList(),
        'labTests': _labTests,
        'sessionId': widget.sessionId,
      };

      // 4. Update Backend
      if (widget.client.id.isNotEmpty) {
        await ref.read(vitalsServiceProvider).updateHistoryData(
            clientId: widget.client.id,
            updateData: updateData,
            existingVitals: widget.latestVitals
        );
      }

      if (widget.sessionId != null) {
        final batch = ref.read(firestoreProvider).batch();
        final sessionRef = ref.read(firestoreProvider).collection('consultation_sessions').doc(widget.sessionId);
        batch.update(sessionRef, {'steps.clinical': true, 'steps.prescription': true, 'updatedAt': FieldValue.serverTimestamp()});
        await batch.commit();
      }

      widget.onSaveAssessment(updateData);

      // 5. Handle Print or Close
      if (isPrintMode) {
        if (mounted) {
          final printVitals = widget.latestVitals?.copyWith(
            medications: _medications,
            labTestOrders: _labTests,
            clinicalNotes: _clinicalNotes,
            clinicalComplaints: _clinicalComplaints,
            nutritionDiagnoses: _nutritionDiagnoses,
            clinicalGuidelines: _clinicalGuidelines, // 🎯 PASS TO PRINTER
          ) ?? VitalsModel(
              id: '', clientId: widget.client.id, date: DateTime.now(),
              medications: _medications, labTestOrders: _labTests,
              clinicalNotes: _clinicalNotes, clinicalComplaints: _clinicalComplaints,
              nutritionDiagnoses: _nutritionDiagnoses, clinicalGuidelines: _clinicalGuidelines, // 🎯
              weightKg: 0, heightCm: 0, bmi: 0, idealBodyWeightKg: 0, bodyFatPercentage: 0,
              isFirstConsultation: true
          );

          Navigator.push(context, MaterialPageRoute(
              builder: (_) => ClinicalPrescriptionPrinter(client: widget.client, vitals: printVitals)
          ));
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Saved & Generated Prescription"), backgroundColor: Colors.green));
        }
      } else {
        if (mounted) Navigator.pop(context);
      }

    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ===========================================================================
  // 🧩 WIDGET HELPERS
  // ===========================================================================

  Widget _buildPremiumHeader(Map<String, String> guidelinesMaster) {
    return SliverAppBar(
        expandedHeight: 80, pinned: true, backgroundColor: Colors.white,
        flexibleSpace: FlexibleSpaceBar(titlePadding: const EdgeInsets.only(left: 20, bottom: 16), title: const Text("Clinical Assessment", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16))),
        actions: [
          IconButton(icon: const Icon(Icons.print, color: Colors.indigo), onPressed: _isLoading ? null : () => _save(isPrintMode: true)),
          IconButton(icon: const Icon(Icons.history, color: Colors.indigo), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ClinicalConsultationSummaryPage(client: widget.client))))
        ]
    );
  }

  // 🎯 GUIDELINE SELECTOR
  void _openGuidelinesDialog(Map<String, String> masterData) async {
    final result = await showModalBottomSheet<List<String>>(
        context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
        builder: (ctx) => GenericMultiSelectDialog(
            title: "Select Guidelines",
            items: masterData.keys.toList(),
            itemNameIdMap: masterData,
            initialSelectedItems: _clinicalGuidelines.keys.toList(),
            providerToRefresh: clinicalGuidelineDataProvider,
            collectionPath: MasterCollectionMapper.getPath(MasterEntity.entity_Guidelines)
        )
    );
    if (result != null) {
      setState(() {
        for (var k in result) {
          if (!_clinicalGuidelines.containsKey(k)) _clinicalGuidelines[k] = "Standard Protocol Advised";
        }
        _clinicalGuidelines.removeWhere((k, v) => !result.contains(k));
      });
    }
  }

  // ... [Other Helpers like _buildPremiumCard, _buildDetailCard, _openTextSheet, etc. remain same as previous] ...

  // (Minimal placeholders for copy-paste safety if previous context lost)
  Widget _buildEmptyText(String t) => Padding(padding: const EdgeInsets.only(top: 8), child: Text(t, style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)));
  Widget _buildPremiumCard(String t, IconData i, Color c, List<Widget> ch) => Container(margin: const EdgeInsets.only(bottom: 24), padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: c.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 8))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(i, color: c, size: 22), const SizedBox(width: 12), Expanded(child: Text(t, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))]), const Divider(height: 32), ...ch]));
  Widget _buildAddAction(String l, VoidCallback t) => widget.isReadOnly ? const SizedBox.shrink() : TextButton.icon(onPressed: t, icon: const Icon(Icons.add_circle_outline, size: 18), label: Text(l));

  // Note: Ensure all helper methods from the previous comprehensive response (Selection, Meds, TextSheet) are included in the final file.
  // ... [Include logic for _openSelection, _openTextSheet, _openMedicineConfigSheet, _openLabSelector, etc.] ...

  // [Code for helpers omitted for brevity but should be identical to the previous full version]
 /* Widget _buildDetailCard({required String title, required String detail, required String placeholder, required Color color, required IconData icon, required VoidCallback onTap, required VoidCallback onDelete}) {
    // Implementation same as previous steps
    return GestureDetector(onTap: widget.isReadOnly ? null : onTap, child: Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.3))), child: Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 20)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), Text(detail.isNotEmpty && detail != 'Not specified' ? detail : placeholder, style: TextStyle(fontSize: 12, color: Colors.grey))])), if (!widget.isReadOnly) IconButton(icon: const Icon(Icons.close, color: Colors.grey, size: 18), onPressed: onDelete)])));
  }*/

  void _openSelection({required String title, required Map<String, String> masterData, required Map<String, String> currentMap, required String section, required String defaultValue, required AutoDisposeFutureProvider<Map<String, String>> provider, required String collectionPath}) async {
    final result = await showModalBottomSheet<List<String>>(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (ctx) => GenericMultiSelectDialog(title: title, items: masterData.keys.toList(), itemNameIdMap: masterData, initialSelectedItems: section == 'notes' ? _noteCategoryKeys : currentMap.keys.toList(), providerToRefresh: provider, collectionPath: collectionPath));
    if (result != null) { setState(() { if (section == 'notes') { _noteCategoryKeys = result; for (var k in result) { if (!_clinicalNotes.containsKey(k)) _clinicalNotes[k] = defaultValue; } _clinicalNotes.removeWhere((k, v) => !result.contains(k)); } else { for (var k in result) { if (!currentMap.containsKey(k)) currentMap[k] = defaultValue; } currentMap.removeWhere((k, v) => !result.contains(k)); } }); }
  }

  void _openTextSheet({required String title, required String key, required String currentVal, required String section, bool isLongText = false}) {
    final controller = TextEditingController(text: currentVal == 'Not specified' ? '' : currentVal);
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (ctx) => Container(padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24), decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))), child: Column(mainAxisSize: MainAxisSize.min, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), TextField(controller: controller, maxLines: isLongText ? 6 : 3, decoration: const InputDecoration(border: OutlineInputBorder())), const SizedBox(height: 16), ElevatedButton(onPressed: () { final val = controller.text.trim(); if(widget.isReadOnly) return; setState(() { if(section == 'complaint') _clinicalComplaints[key] = val; else if(section == 'diagnosis') _nutritionDiagnoses[key] = val; else if(section == 'notes') _clinicalNotes[key] = val; }); Navigator.pop(ctx); }, child: const Text("SAVE"))])));
  }

  Widget _buildMedicationCard(PrescribedMedicine med, int index) => Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue.shade100)), child: Row(children: [const Icon(Icons.edit, color: Colors.blue, size: 16), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(med.name, style: const TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text("${med.dosage} | ${med.frequency} | ${med.duration}", style: const TextStyle(fontSize: 11))])), if (!widget.isReadOnly) IconButton(icon: const Icon(Icons.close, color: Colors.red, size: 18), onPressed: () => setState(() => _medications.removeAt(index)))]));

  Widget _buildFollowUpChip(String label, int? days) {
    bool isSelected = (days == null) ? _followUpText == label : _followUpText.startsWith(label);
    return FilterChip(label: Text(label), selected: isSelected, selectedColor: Colors.purple.shade100, onSelected: widget.isReadOnly ? null : (_) => _setFollowUp(label, days: days));
  }

  void _setFollowUp(String label, {int? days}) {
    setState(() { if (days != null) { final date = DateTime.now().add(Duration(days: days)); _selectedFollowUpDate = date; _followUpText = "$label (${DateFormat('dd MMM').format(date)})"; } else { _selectedFollowUpDate = null; _followUpText = label; } });
  }

  Future<void> _pickFollowUpDate() async {
    final picked = await showDatePicker(context: context, initialDate: DateTime.now().add(const Duration(days: 14)), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
    if(picked != null) { final days = picked.difference(DateTime.now()).inDays + 1; setState(() { _selectedFollowUpDate = picked; _followUpText = "On ${DateFormat('dd MMM yyyy').format(picked)} (in $days days)"; }); }
  }

  void _openBatchSupplementSelector(Map<String, String> m) async { final res = await showModalBottomSheet<List<String>>(context: context, builder: (c) => GenericMultiSelectDialog(title: "Supplements", items: m.keys.toList(), itemNameIdMap: m, initialSelectedItems: [], providerToRefresh: supplementDataProvider, collectionPath: MasterCollectionMapper.getPath(MasterEntity.entity_supplement))); if(res!=null) setState(() { for(var n in res) if(!_medications.any((x)=>x.name==n)) _medications.add(PrescribedMedicine(name: n, dosage: "1 Tab", frequency: "1-0-0", duration: "30 Days", instruction: "After Food")); }); }
  void _openLabSelector(Map<String, String> m) async { final res = await showModalBottomSheet<List<String>>(context: context, builder: (c) => GenericMultiSelectDialog(title: "Labs", items: m.keys.toList(), itemNameIdMap: m, initialSelectedItems: _labTests, providerToRefresh: investigationDataProvider, collectionPath: MasterCollectionMapper.getPath(MasterEntity.entity_Investigation))); if(res!=null) setState(()=>_labTests=res); }

  Widget _buildSaveButton() => ElevatedButton(onPressed: _isLoading ? null : () => _save(isPrintMode: false), child: const Text("SAVE"));
// ===========================================================================
  // 💊 MEDICINE CONFIGURATION SHEET (Restored)
  // ===========================================================================
  void _openMedicineConfigSheet({required int? index}) {
    final bool isEditing = index != null;
    final PrescribedMedicine? existing = isEditing ? _medications[index] : null;

    final nameCtrl = TextEditingController(text: existing?.name ?? '');

    String dosageQty = '';
    String dosageUnit = 'Tablet';
    if (existing != null && existing.dosage.isNotEmpty) {
      final parts = existing.dosage.trim().split(' ');
      if (parts.isNotEmpty) {
        if (double.tryParse(parts[0]) != null) {
          dosageQty = parts[0];
          if (parts.length > 1) { dosageUnit = parts.sublist(1).join(' '); }
        } else {
          dosageQty = '';
        }
      }
    }
    final dosageQtyCtrl = TextEditingController(text: dosageQty);

    // 🎯 DURATION PARSING
    String durationQty = '30';
    String durationUnit = 'Days';
    if (existing != null && existing.duration.isNotEmpty) {
      final dParts = existing.duration.trim().split(' ');
      if (dParts.length >= 2) {
        durationQty = dParts[0];
        durationUnit = dParts.sublist(1).join(' ');
      }
    }
    final durationQtyCtrl = TextEditingController(text: durationQty);

    String freq = existing?.frequency ?? '1-0-1';
    String instr = existing?.instruction ?? 'After Food';

    final List<String> dosageUnits = ["Tablet", "Capsule", "mg", "ml", "Drops", "Sachet", "Puff", "Unit", "Teaspoon", "Tablespoon", "Patch", "Injection", "g", "mcg", "IU"];
    final List<String> durationUnits = ["Days", "Weeks", "Months", "Years"];

    String currentDosageUnit = dosageUnits.firstWhere((u) => u.toLowerCase() == dosageUnit.toLowerCase(), orElse: () => "Tablet");
    String currentDurationUnit = durationUnits.firstWhere((u) => u.toLowerCase() == durationUnit.toLowerCase(), orElse: () => "Days");

    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (ctx) => StatefulBuilder(builder: (c, st) => Container(padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24), decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(isEditing ? "Edit: ${existing!.name}" : "Add Medicine", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)), const SizedBox(height: 16),
      if (!isEditing) TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Medicine Name", border: OutlineInputBorder())), const SizedBox(height: 16),
      SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: ["1-0-1", "1-0-0", "0-0-1", "1-1-1", "SOS", "0-1-0", "1-1-0"].map((f) => Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(f), selected: freq == f, onSelected: (v) => st(() => freq = f), selectedColor: Colors.blue.shade100))).toList())), const SizedBox(height: 16),

      // Dosage Row
      Row(children: [
        Expanded(flex: 1, child: TextField(controller: dosageQtyCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Qty", border: OutlineInputBorder()))),
        const SizedBox(width: 8),
        Expanded(flex: 2, child: DropdownButtonFormField<String>(value: currentDosageUnit, decoration: const InputDecoration(labelText: "Unit", border: OutlineInputBorder()), items: dosageUnits.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(), onChanged: (v) => st(() => currentDosageUnit = v!), isExpanded: true))
      ]),
      const SizedBox(height: 16),

      // 🎯 DURATION ROW (SPLIT)
      Row(children: [
        Expanded(flex: 1, child: TextField(controller: durationQtyCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Dur.", border: OutlineInputBorder()))),
        const SizedBox(width: 8),
        Expanded(flex: 2, child: DropdownButtonFormField<String>(value: currentDurationUnit, decoration: const InputDecoration(labelText: "Period", border: OutlineInputBorder()), items: durationUnits.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(), onChanged: (v) => st(() => currentDurationUnit = v!), isExpanded: true))
      ]),
      const SizedBox(height: 16),

      DropdownButtonFormField<String>(value: ["After Food", "Before Food", "Empty Stomach", "With Water", "Before Sleep"].contains(instr) ? instr : "After Food", decoration: const InputDecoration(labelText: "Instruction", border: OutlineInputBorder()), items: ["After Food", "Before Food", "Empty Stomach", "With Water", "Before Sleep"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => instr = v!),
      const SizedBox(height: 24),

      SizedBox(width: double.infinity, child: ElevatedButton(onPressed: (){
        if (nameCtrl.text.isEmpty) return;
        setState(() {
          final combinedDosage = "${dosageQtyCtrl.text.trim()} $currentDosageUnit";
          final combinedDuration = "${durationQtyCtrl.text.trim()} $currentDurationUnit"; // 🎯 Combine Duration
          final newItem = PrescribedMedicine(name: nameCtrl.text, dosage: combinedDosage, frequency: freq, duration: combinedDuration, instruction: instr);
          if (isEditing) { _medications[index] = newItem; } else { _medications.add(newItem); }
        });
        Navigator.pop(context);
      }, style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50)), child: Text(isEditing ? "UPDATE DETAILS" : "ADD MEDICINE")))
    ]))));
  }


  Widget _buildSwipeableMedication(int index, PrescribedMedicine med) {
    if (widget.isReadOnly) return _buildMedicationCard(med, index);

    return Dismissible(
      key: ValueKey("med_${med.name}_$index"),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.delete, color: Colors.red),
      ),
      onDismissed: (direction) {
        setState(() => _medications.removeAt(index));
      },
      child: GestureDetector(
        onTap: () => widget.isReadOnly ? null : _openMedicineConfigSheet(index: index),
        child: _buildMedicationCard(med, index),
      ),
    );
  }



  Widget _buildSwipeableGuideline(String key, String value) {
    if (widget.isReadOnly) return _buildGuidelineCard(key, value);

    return Dismissible(
      key: Key("guideline_$key"),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(8)),
        child: const Icon(Icons.delete, color: Colors.red),
      ),
      onDismissed: (direction) {
        setState(() => _clinicalGuidelines.remove(key));
      },
      child: _buildGuidelineCard(key, value),
    );
  }

  Widget _buildGuidelineCard(String key, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.teal.shade100)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, size: 18, color: Colors.teal),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            if(value.isNotEmpty && value != 'Standard Protocol Advised')
              Text(value, style: TextStyle(fontSize: 12, color: Colors.grey.shade700))
          ])),
          if(!widget.isReadOnly)
            IconButton(icon: const Icon(Icons.close, size: 16, color: Colors.grey), onPressed: () => setState(() => _clinicalGuidelines.remove(key)))
        ],
      ),
    );
  }

  Widget _buildDetailCard({
    required String title,
    required String detail,
    required String placeholder,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
    required VoidCallback onDelete
  }) {
    if (widget.isReadOnly) return _buildDetailCardContent(title, detail, placeholder, color, icon, null, null);

    return Dismissible(
      key: Key("detail_$title"),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.delete, color: Colors.red),
      ),
      onDismissed: (direction) => onDelete(),
      child: GestureDetector(
        onTap: onTap,
        child: _buildDetailCardContent(title, detail, placeholder, color, icon, onTap, onDelete),
      ),
    );
  }

  Widget _buildDetailCardContent(String title, String detail, String placeholder, Color color, IconData icon, VoidCallback? onTap, VoidCallback? onDelete) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.3))),
      child: Row(
          children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 20)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), Text(detail.isNotEmpty && detail != 'Not specified' ? detail : placeholder, style: TextStyle(fontSize: 12, color: Colors.grey))])),
            if (!widget.isReadOnly && onDelete != null) IconButton(icon: const Icon(Icons.close, color: Colors.grey, size: 18), onPressed: onDelete)
          ]
      ),
    );
  }
}