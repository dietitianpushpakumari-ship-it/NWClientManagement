// lib/master_diet_planner/client_clinical_assessment_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutricare_client_management/modules/client/model/vitals_model.dart';
import 'package:nutricare_client_management/master/model/master_constants.dart';
import 'package:nutricare_client_management/master_diet_planner/history_sections.dart';
import 'package:nutricare_client_management/master_diet_planner/complex_input_widgets.dart';
import 'package:nutricare_client_management/master_diet_planner/generic_multi_select_dialogg.dart';
import 'package:nutricare_client_management/admin/generic_clinical_master_entry_screen.dart';
import 'package:nutricare_client_management/admin/labvital/global_service_provider.dart';


final masterServiceProvider = masterDataServiceProvider;
final mapper = MasterCollectionMapper.getPath;

// Clinical Assessment Providers
final clinicalComplaintMasterProvider = FutureProvider.autoDispose<Map<String, String>>((ref) async {
  return ref.watch(masterServiceProvider).fetchMasterList(mapper(MasterEntity.entity_Complaint));
});

final nutritionDiagnosisMasterProvider = FutureProvider.autoDispose<Map<String, String>>((ref) async {
  return ref.watch(masterServiceProvider).fetchMasterList(mapper(MasterEntity.entity_Diagnosis));
});

final noteCategoryMasterProvider = FutureProvider.autoDispose<Map<String, String>>((ref) async {
  return ref.watch(masterServiceProvider).fetchMasterList(mapper(MasterEntity.entity_Clinicalnotes));
});
// 🎯 REMOVED: lifeStyleHabitMasterProvider is moved to MasterPlanAssignmentPage
// --------------------------------------------------------------------


class ClientClinicalAssessmentSheet extends ConsumerStatefulWidget {
  final VitalsModel? latestVitals;
  final Function(Map<String, dynamic> assessmentData) onSaveAssessment;

  const ClientClinicalAssessmentSheet({
    super.key,
    this.latestVitals,
    required this.onSaveAssessment,
  });

  @override
  ConsumerState<ClientClinicalAssessmentSheet> createState() => _ClientClinicalAssessmentSheetState();
}

class _ClientClinicalAssessmentSheetState extends ConsumerState<ClientClinicalAssessmentSheet> {
  final _formKey = GlobalKey<FormState>();

  // State for Clinical Assessment Section
  List<String> _clinicalComplaintKeys = [];
  Map<String, String> _finalComplaints = {}; // Complaint: Severity/Detail

  List<String> _diagnosisKeys = [];
  Map<String, String> _finalDiagnoses = {}; // Diagnosis: Related Factor/Etiology

  // Structured Notes (SOAP/ADIME)
  List<String> _noteCategoryKeys = [];
  Map<String, TextEditingController> _noteControllers = {}; // Category: Text Content
  Map<String, String> _finalNotes = {};

  // 🎯 REMOVED: _lifestyleGoalKeys state

  bool _isLoading = false;

  // --- Helper Methods ---

  Map<String, String> _safeToMapOfStrings(dynamic data) {
    if (data == null) return {};
    if (data is Map) return Map<String, String>.from(data.cast<String, String>());
    return {};
  }

  List<String> _safeToListOfStrings(dynamic data) {
    if (data == null) return [];
    if (data is Iterable) return List<String>.from(data.cast<String>());
    if (data is String && data.isNotEmpty) return [data];
    return [];
  }


  void _updateNoteContent(String key, String content) {
    _noteControllers[key]!.text = content;
    _finalNotes[key] = content.isEmpty ? 'Not specified' : content;
  }

  void _updateAssessmentMap(String keyType, Map<String, String> data) {
    setState(() {
      if (keyType == 'complaint') {
        _finalComplaints = Map.from(_finalComplaints);
        _finalComplaints.addAll(data);
      }
      else if (keyType == 'diagnosis') {
        _finalDiagnoses = Map.from(_finalDiagnoses);
        _finalDiagnoses.addAll(data);
      }
    });
  }

  // --- Initialization ---

  @override
  void initState() {
    super.initState();

    final initialComplaintMap = _safeToMapOfStrings(widget.latestVitals?.clinicalComplaints);
    _clinicalComplaintKeys = initialComplaintMap.keys.toList();
    _finalComplaints = initialComplaintMap;

    final initialDiagnosisMap = _safeToMapOfStrings(widget.latestVitals?.nutritionDiagnoses);
    _diagnosisKeys = initialDiagnosisMap.keys.toList();
    _finalDiagnoses = initialDiagnosisMap;

    final initialNotesMap = _safeToMapOfStrings(widget.latestVitals?.clinicalNotes);
    _noteCategoryKeys = initialNotesMap.keys.toList();
    _finalNotes = initialNotesMap;
    initialNotesMap.forEach((key, value) {
      _noteControllers[key] = TextEditingController(text: value);
    });

    // 🎯 REMOVED: _lifestyleGoalKeys initialization
  }

  @override
  void dispose() {
    _noteControllers.values.forEach((c) => c.dispose());
    super.dispose();
  }

  // --- Master Navigation/Dialog Handlers ---

  void _addMasterComplaint() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => GenericClinicalMasterEntryScreen(
      entityName: MasterEntity.entity_Complaint,
    ))).then((_) => ref.invalidate(clinicalComplaintMasterProvider));
  }
  void _addMasterDiagnosis() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => GenericClinicalMasterEntryScreen(
      entityName: MasterEntity.entity_Diagnosis,
    ))).then((_) => ref.invalidate(nutritionDiagnosisMasterProvider));
  }
  void _addMasterNoteCategory() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => GenericClinicalMasterEntryScreen(
      entityName: MasterEntity.entity_Clinicalnotes,
    ))).then((_) => ref.invalidate(noteCategoryMasterProvider));
  }

  // 🎯 REMOVED: _addMasterLifestyleGoal handler


  // Dialog Handler - Remains the same
  void _openDialog(Map<String, String> masterDataMap, List<String> currentKeys, String title, Function(List<String>) onResult, VoidCallback onAddMaster, {bool singleSelect = false}) async {
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => GenericMultiSelectDialog(
        title: title,
        items: masterDataMap.keys.toList(),
        itemNameIdMap: masterDataMap,
        initialSelectedItems: currentKeys,
        onAddMaster: onAddMaster,
        singleSelect: singleSelect,
      ),
    );
    if (result != null) onResult(result);
  }

  void _openComplaintDialog(Map<String, String> allComplaints) {
    _openDialog(allComplaints, _clinicalComplaintKeys, "Select ${MasterEntity.entity_Complaint}s", (r) => setState(() => _clinicalComplaintKeys = r), _addMasterComplaint);
  }
  void _openDiagnosisDialog(Map<String, String> allDiagnoses) {
    _openDialog(allDiagnoses, _diagnosisKeys, "Select ${MasterEntity.entity_Diagnosis}", (r) => setState(() => _diagnosisKeys = r), _addMasterDiagnosis);
  }
  void _openNoteCategoryDialog(Map<String, String> allNotes) {
    _openDialog(allNotes, _noteCategoryKeys, "Manage Note Categories", (r) {
      setState(() {
        _noteCategoryKeys = r;
        // Clean up/initialize controllers after selection
        _noteControllers.keys.toList().forEach((key) {
          if (!r.contains(key)) _noteControllers.remove(key)?.dispose();
        });
        r.forEach((key) {
          if (!_noteControllers.containsKey(key)) {
            _noteControllers[key] = TextEditingController(text: _finalNotes[key] ?? '');
          }
        });
      });
    }, _addMasterNoteCategory);
  }

  // 🎯 REMOVED: _openLifestyleGoalDialog handler


  Future<void> _saveAssessment() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      // Final aggregation of all new clinical fields
      final Map<String, String> finalNotes = _noteCategoryKeys.asMap().map((_, key) => MapEntry(key, _noteControllers[key]?.text.trim() ?? 'Not specified'));

      final Map<String, dynamic> assessmentData = {
        'clinicalComplaints': _finalComplaints,
        'nutritionDiagnoses': _finalDiagnoses,
        'clinicalNotes': finalNotes,
        // 🎯 REMOVED: 'lifestyleGoals' from assessmentData
      };

      // Report final data back to the parent widget
      widget.onSaveAssessment(assessmentData);

    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Assessment Save failed: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Local helper to build the assessment-specific header with the back button (Premium Layout)
  Widget _buildAssessmentHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 10),
          const Text(
            'Clinical Assessment & Diagnosis', // Specific Title
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    // Watch providers
    final complaintsAsync = ref.watch(clinicalComplaintMasterProvider);
    final diagnosisAsync = ref.watch(nutritionDiagnosisMasterProvider);
    final notesAsync = ref.watch(noteCategoryMasterProvider);
    // 🎯 REMOVED: habitsAsync watch


    // Error and Loading checks
    if (complaintsAsync.isLoading || diagnosisAsync.isLoading || notesAsync.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (complaintsAsync.hasError || diagnosisAsync.hasError || notesAsync.hasError) {
      return Scaffold(body: Center(child: Text('Error loading clinical masters: ${complaintsAsync.error ?? diagnosisAsync.error ?? notesAsync.error}')));
    }

    final allComplaints = complaintsAsync.value!;
    final allDiagnoses = diagnosisAsync.value!;
    final allNotes = notesAsync.value!;
    // 🎯 REMOVED: allHabits extraction

    // Full-screen Scaffold Structure (No AppBar)
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: Column(
        children: [
          _buildAssessmentHeader(context),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // --- Card Wrapper for Assessment ---
                  buildCard(
                    title: "Clinical Assessment Details",
                    icon: Icons.assignment_turned_in,
                    color: Colors.purple,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- MODULE 1: Clinical Complaint ---
                        const Text("Primary Complaints:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A1A1A))),
                        ..._clinicalComplaintKeys.map((key) => ComplaintDetailInput(
                          key: ValueKey(key), complaint: key, initialDetail: _finalComplaints[key] ?? '',
                          onChanged: (map) => _updateAssessmentMap('complaint', map),
                          onDelete: () => setState(() { _clinicalComplaintKeys.remove(key); _finalComplaints.remove(key); }),
                        )).toList(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton.icon(onPressed: () => _openComplaintDialog(allComplaints), icon: const Icon(Icons.psychology), label: const Text("Select Complaints")),
                            IconButton(onPressed: _addMasterComplaint, icon: const Icon(Icons.add_circle, color: Colors.green), tooltip: "Add Complaint Master"),
                          ],
                        ),
                        const Divider(height: 25),

                        // --- MODULE 2: Diagnosis Selection ---
                        const Text("Formal Nutrition Diagnoses:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A1A1A))),
                        ..._diagnosisKeys.map((key) => DiagnosisDetailInput(
                          key: ValueKey(key), diagnosis: key, initialDetail: _finalDiagnoses[key] ?? '',
                          onChanged: (map) => _updateAssessmentMap('diagnosis', map),
                          onDelete: () => setState(() { _diagnosisKeys.remove(key); _finalDiagnoses.remove(key); }),
                        )).toList(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton.icon(onPressed: () => _openDiagnosisDialog(allDiagnoses), icon: const Icon(Icons.local_hospital), label: const Text("Select Diagnoses")),
                            IconButton(onPressed: _addMasterDiagnosis, icon: const Icon(Icons.add_circle, color: Colors.green), tooltip: "Add Diagnosis Master"),
                          ],
                        ),
                        const Divider(height: 25),

                        // 🎯 REMOVED: Lifestyle Goals Module
                        // const Divider(height: 25),

                        // --- MODULE 3: Structured Clinical Notes ---
                        const Text("Structured Clinical Notes:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A1A1A))),
                        ..._noteCategoryKeys.map((key) => NoteCategoryInput(
                          key: ValueKey(key),
                          category: key,
                          controller: _noteControllers[key]!,
                          onChanged: _updateNoteContent,
                          onDelete: () => setState(() {
                            _noteCategoryKeys.remove(key);
                            _noteControllers.remove(key)?.dispose();
                            _finalNotes.remove(key);
                          }),
                        )).toList(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton.icon(onPressed: () => _openNoteCategoryDialog(allNotes), icon: const Icon(Icons.notes), label: const Text("Manage Note Structure")),
                            IconButton(onPressed: _addMasterNoteCategory, icon: const Icon(Icons.add_circle, color: Colors.green), tooltip: "Add Note Category Master"),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Save button
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveAssessment,
                    style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(40)),
                    child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("SAVE CLINICAL ASSESSMENT"),
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}