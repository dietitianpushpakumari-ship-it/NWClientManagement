import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutricare_client_management/master/model/master_constants.dart';
import 'package:nutricare_client_management/master_diet_planner/complex_input_widgets.dart';
import 'package:nutricare_client_management/master_diet_planner/generic_multi_select_dialogg.dart';
import 'package:nutricare_client_management/modules/client/model/vitals_model.dart';
import 'package:nutricare_client_management/admin/generic_clinical_master_entry_screen.dart';
import 'package:nutricare_client_management/admin/labvital/global_service_provider.dart';

// --- Data Providers for Assessment ---
final clinicalComplaintDataProvider = FutureProvider.autoDispose<Map<String, String>>((ref) async {
  final service = ref.watch(masterDataServiceProvider);
  final mapper = MasterCollectionMapper.getPath;
  return await service.fetchMasterList(mapper(MasterEntity.entity_Complaint));
});

final nutritionDiagnosisDataProvider = FutureProvider.autoDispose<Map<String, String>>((ref) async {
  final service = ref.watch(masterDataServiceProvider);
  final mapper = MasterCollectionMapper.getPath;
  return await service.fetchMasterList(mapper(MasterEntity.entity_Diagnosis));
});

final clinicalNoteCategoryDataProvider = FutureProvider.autoDispose<Map<String, String>>((ref) async {
  final service = ref.watch(masterDataServiceProvider);
  final mapper = MasterCollectionMapper.getPath;
  return await service.fetchMasterList(mapper(MasterEntity.entity_Clinicalnotes));
});

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
  bool _isLoading = false;

  // --- SOURCE OF TRUTH ---
  late Map<String, String> _clinicalComplaints;
  late Map<String, String> _nutritionDiagnoses;
  late Map<String, String> _clinicalNotes;

  // 🎯 FIX: Explicitly declare the missing keys list
  List<String> _noteCategoryKeys = [];

  // --- PERSISTENT CONTROLLERS (Fixes Cursor Focus Loss) ---
  final Map<String, TextEditingController> _noteControllers = {};

  @override
  void initState() {
    super.initState();
    _initializeRestoration();
  }

  void _initializeRestoration() {
    final v = widget.latestVitals;

    _clinicalComplaints = Map<String, String>.from(v?.clinicalComplaints ?? {});
    _nutritionDiagnoses = Map<String, String>.from(v?.nutritionDiagnoses ?? {});
    _clinicalNotes = Map<String, String>.from(v?.clinicalNotes ?? {});

    // Initialize Keys
    _noteCategoryKeys = _clinicalNotes.keys.toList();

    // Restore controllers for saved notes to maintain focus
    _clinicalNotes.forEach((key, value) {
      _noteControllers[key] = TextEditingController(text: value == 'Not specified' ? '' : value);
    });
  }

  @override
  void dispose() {
    _noteControllers.values.forEach((c) => c.dispose());
    super.dispose();
  }

  void _updateEntry(String section, String key, String value) {
    if (SchedulerBinding.instance.schedulerPhase != SchedulerPhase.idle) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _updateEntry(section, key, value));
      return;
    }
    setState(() {
      if (section == 'complaint') _clinicalComplaints[key] = value;
      if (section == 'diagnosis') _nutritionDiagnoses[key] = value;
      if (section == 'notes') _clinicalNotes[key] = value;
    });
  }

  void _openSelection({
    required String title,
    required Map<String, String> masterData,
    required Map<String, String> currentMap,
    required String section,
    required String defaultValue,
  }) async {
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GenericMultiSelectDialog(
        title: title,
        items: masterData.keys.toList(),
        itemNameIdMap: masterData,
        initialSelectedItems: section == 'notes' ? _noteCategoryKeys : currentMap.keys.toList(),
        onAddMaster: () {},
      ),
    );

    if (result != null) {
      setState(() {
        if (section == 'notes') {
          _noteCategoryKeys = result;
          for (var key in result) {
            if (!_noteControllers.containsKey(key)) {
              _noteControllers[key] = TextEditingController(text: _clinicalNotes[key] ?? '');
              _clinicalNotes[key] = _clinicalNotes[key] ?? defaultValue;
            }
          }
          // Clean up removed controllers
          _noteControllers.removeWhere((k, v) {
            if (!result.contains(k)) {
              v.dispose();
              return true;
            }
            return false;
          });
          _clinicalNotes.removeWhere((k, v) => !result.contains(k));
        } else {
          for (var key in result) {
            if (!currentMap.containsKey(key)) currentMap[key] = defaultValue;
          }
          currentMap.removeWhere((k, v) => !result.contains(k));
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final complaintsAsync = ref.watch(clinicalComplaintDataProvider);
    final diagnosisAsync = ref.watch(nutritionDiagnosisDataProvider);
    final notesAsync = ref.watch(clinicalNoteCategoryDataProvider);

    if (complaintsAsync.isLoading || diagnosisAsync.isLoading || notesAsync.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      body: CustomScrollView(
        slivers: [
          _buildPremiumHeader(),
          SliverToBoxAdapter(
            child: Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildPremiumCard("Primary Complaints", Icons.personal_injury, Colors.deepOrange, [
                      _buildAddAction("Select Complaints", () => _openSelection(
                          title: "Complaints", masterData: complaintsAsync.value!,
                          currentMap: _clinicalComplaints, section: 'complaint', defaultValue: "Not specified"
                      )),
                      ..._clinicalComplaints.keys.map((k) => ComplaintDetailInput(
                        key: ValueKey('comp_$k'), complaint: k, initialDetail: _clinicalComplaints[k]!,
                        onChanged: (val) => _updateEntry('complaint', k, val[k]!),
                        onDelete: () => setState(() => _clinicalComplaints.remove(k)),
                      )),
                    ]),

                    _buildPremiumCard("Nutrition Diagnosis", Icons.assignment_late, Colors.indigo, [
                      _buildAddAction("Identify Diagnoses", () => _openSelection(
                          title: "Diagnoses", masterData: diagnosisAsync.value!,
                          currentMap: _nutritionDiagnoses, section: 'diagnosis', defaultValue: "Not specified"
                      )),
                      ..._nutritionDiagnoses.keys.map((k) => DiagnosisDetailInput(
                        key: ValueKey('diag_$k'), diagnosis: k, initialDetail: _nutritionDiagnoses[k]!,
                        onChanged: (val) => _updateEntry('diagnosis', k, val[k]!),
                        onDelete: () => setState(() => _nutritionDiagnoses.remove(k)),
                      )),
                    ]),

                    _buildPremiumCard("Clinical Notes (ADIME)", Icons.description, Colors.blueGrey, [
                      _buildAddAction("Manage Categories", () => _openSelection(
                          title: "Notes", masterData: notesAsync.value!,
                          currentMap: _clinicalNotes, section: 'notes', defaultValue: ""
                      )),
                      ..._noteCategoryKeys.map((k) => NoteCategoryInput(
                        key: ValueKey('note_$k'), category: k,
                        controller: _noteControllers[k]!,
                        onChanged: (cat, val) => _updateEntry('notes', cat, val),
                        onDelete: () => setState(() {
                          _noteCategoryKeys.remove(k);
                          _clinicalNotes.remove(k);
                          _noteControllers.remove(k)?.dispose();
                        }),
                      )),
                    ]),

                    const SizedBox(height: 30),
                    _buildSaveButton(),
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

  // --- UI COMPONENTS ---
  Widget _buildPremiumHeader() => SliverAppBar(expandedHeight: 100, pinned: true, automaticallyImplyLeading: false, backgroundColor: Colors.white, flexibleSpace: FlexibleSpaceBar(titlePadding: const EdgeInsets.only(left: 20, bottom: 16), title: Row(children: [GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.arrow_back_ios, size: 20, color: Colors.black)), const SizedBox(width: 12), const Text("Clinical Assessment", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18))])));
  Widget _buildPremiumCard(String t, IconData i, Color c, List<Widget> ch) => Container(margin: const EdgeInsets.only(bottom: 24), padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: c.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 8))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(i, color: c, size: 22), const SizedBox(width: 12), Text(t, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))]), const Divider(height: 32), ...ch]));
  Widget _buildAddAction(String l, VoidCallback t) => TextButton.icon(onPressed: t, icon: const Icon(Icons.add_circle_outline, size: 18), label: Text(l));

  Widget _buildSaveButton() => ElevatedButton(
    onPressed: _isLoading ? null : _save,
    style: ElevatedButton.styleFrom(backgroundColor: Colors.indigoAccent, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
    child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("CONFIRM ASSESSMENT", style: TextStyle(fontWeight: FontWeight.bold)),
  );

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      // 1. Sync note map from controllers to ensure current text is captured
      _noteControllers.forEach((key, controller) {
        _clinicalNotes[key] = controller.text.trim().isEmpty ? 'Not specified' : controller.text.trim();
      });

      // 2. Aggregate the clinical assessment data
      final Map<String, dynamic> updateData = {
        'clinicalComplaints': _clinicalComplaints,
        'nutritionDiagnoses': _nutritionDiagnoses,
        'clinicalNotes': _clinicalNotes,
      };

      // 3. 🎯 FIX: Explicitly call the service to update Firestore
      // Note: This requires widget.client.id or widget.latestVitals.clientId
      final clientId = widget.latestVitals?.clientId ?? "";

      if (clientId.isNotEmpty) {
        await ref.read(vitalsServiceProvider).updateHistoryData(
          clientId: clientId,
          updateData: updateData,
          existingVitals: widget.latestVitals,
        );
      }

      // 4. Notify parent and close the sheet
      widget.onSaveAssessment(updateData);
      if (mounted) Navigator.pop(context);

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Firestore Update Failed: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}