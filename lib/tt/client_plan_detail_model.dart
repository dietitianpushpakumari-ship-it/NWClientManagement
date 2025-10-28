// lib/screens/client_plan_details_modal.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nutricare_client_management/modules/client/model/client_diet_plan_model.dart';
import 'package:nutricare_client_management/modules/client/model/vitals_model.dart';
import 'package:nutricare_client_management/modules/client/services/vitals_service.dart';
import 'package:nutricare_client_management/modules/master/model/diagonosis_master.dart';
import 'package:nutricare_client_management/modules/master/model/guidelines.dart';
import 'package:nutricare_client_management/modules/master/service/diagonosis_master_service.dart';
import 'package:nutricare_client_management/widgets/GuidelineWidget.dart';
import 'package:nutricare_client_management/widgets/diagonosis_multi_select_dialog.dart';
import 'plan_details_result.dart';

// ---------------- MOCK DEPENDENCIES (Place real imports here) ----------------
/*class DiagnosisMasterModel { final String id; final String name; const DiagnosisMasterModel({required this.id, required this.name}); }
class VitalsModel { final String id; final DateTime date; final double weightKg; const VitalsModel({required this.id, required this.date, required this.weightKg}); }
class Guideline { final String id; final String name; const Guideline({required this.id, required this.name}); }
class MasterDietPlanModel { final String id; final String name; const MasterDietPlanModel({required this.id, required this.name}); }
class MockDiagnosisService { Future<List<DiagnosisMasterModel>> getMasterDiagnoses() async => [const DiagnosisMasterModel(id: 'D1', name: 'Obesity'), const DiagnosisMasterModel(id: 'D2', name: 'Diabetes')]; }
class MockVitalsService { Future<List<VitalsModel>> getClientVitals(String clientId) async => [const VitalsModel(id: 'V1', date: null, weightKg: 80.0), const VitalsModel(id: 'V2', date: null, weightKg: 81.0)]; }
// -----------------------------------------------------------------------------
*/
class ClientPlanDetailsModal extends StatefulWidget {
  final ClientDietPlanModel initialData;
  final String clientId;

  const ClientPlanDetailsModal({
    super.key,
    required this.initialData, // Now receives a plan (empty for ADD, populated for EDIT)
    required this.clientId,
  });

  @override
  State<ClientPlanDetailsModal> createState() => _ClientPlanDetailsModalState();
}

class _ClientPlanDetailsModalState extends State<ClientPlanDetailsModal> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // State variables for all metadata fields
  String? _masterPlanId;
  String? _selectedMasterPlanName;
  List<DiagnosisMasterModel> _allDiagnoses = [];
  List<VitalsModel> _clientVitals = [];
  List<String> _selectedDiagnosisIds = [];
  String? _linkedVitalsId;
  VitalsModel? _linkedVitalsRecord;
  List<Guideline> _selectedGuidelines = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // --- Initialize for Edit (or Add if cloned from master) ---
    _nameController.text = widget.initialData.name;
    _descriptionController.text = widget.initialData.description;
    _masterPlanId = widget.initialData.masterPlanId.isEmpty ? null : widget.initialData.masterPlanId;
    _selectedDiagnosisIds = List.from(widget.initialData.diagnosisIds);
    _linkedVitalsId = widget.initialData.linkedVitalsId;

    // NOTE: You need to load selectedGuidelines based on widget.initialData.guidelineIds

    _loadData();
  }

  void _loadData() async {
    // MOCK: Load necessary master data (Diagnoses and Vitals)
    try {
      final diagnoses = await DiagnosisMasterService().fetchAllDiagnosisMaster();
      final vitals = await VitalsService().getClientVitals(widget.clientId);
      vitals.sort((a, b) => (b.date ?? DateTime(2000)).compareTo(a.date ?? DateTime(2000)));

      if(mounted) {
        setState(() {
          _allDiagnoses = diagnoses;
          _clientVitals = vitals;
          if (_linkedVitalsId != null) {
            _linkedVitalsRecord = vitals.firstWhere((v) => v.id == _linkedVitalsId);
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      // Handle error loading data
      if(mounted) setState(() => _isLoading = false);
    }
  }

  void _saveDetails() {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    // 1. Package the result
    final result = PlanDetailsResult(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      masterPlanId: _masterPlanId,
      linkedVitalsId: _linkedVitalsId,
      diagnosisIds: _selectedDiagnosisIds,
      guidelineIds: widget.initialData.guidelineIds, // NOTE: Assuming GuidelineWidget updates state externally or we read from a local state
    );

    // 2. Return the result
    Navigator.of(context).pop(result);
  }

  // --- UI Builder Methods (Placeholders for your actual complex widgets) ---
  Widget _buildDetailsContent() {
    return Column(
      children: [
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'Plan Name*'),
          validator: (v) => v!.trim().isEmpty ? 'Name is required' : null,
        ),
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(labelText: 'Description (Optional)'),
          maxLines: 2,
        ),
        // ... (Master Plan Dropdown/Selector logic goes here) ...
      ],
    );
  }

  Widget _buildLinkageContent() {
    final linkedDate = _linkedVitalsRecord?.date != null ? DateFormat('d MMM yyyy').format(_linkedVitalsRecord!.date!) : 'N/A';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Linked Vitals Record', style: TextStyle(fontWeight: FontWeight.bold)),
        ListTile(
          title: Text(_linkedVitalsRecord == null
              ? 'No Vitals Linked'
              : 'Weight: ${_linkedVitalsRecord!.weightKg.toStringAsFixed(1)} kg ($linkedDate)'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () async {
            // MOCK: Open Vitals selection Dialog
            final selectedVitalsId = await showDialog<String>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Select Vitals Record'),
                content: SizedBox(
                  width: double.maxFinite,
                  child: ListView.builder(
                    itemCount: _clientVitals.length,
                    itemBuilder: (c, i) => ListTile(
                      title: Text('Record ${i + 1}'),
                      onTap: () => Navigator.of(c).pop(_clientVitals[i].id),
                    ),
                  ),
                ),
              ),
            );
            if (selectedVitalsId != null && mounted) {
              setState(() {
                _linkedVitalsId = selectedVitalsId;
                _linkedVitalsRecord = _clientVitals.firstWhere((v) => v.id == selectedVitalsId);
              });
            }
          },
        ),

        // Diagnosis Multi Select
        const Text('Diagnosis', style: TextStyle(fontWeight: FontWeight.bold)),
        ListTile(
          title: Text('${_selectedDiagnosisIds.length} Diagnoses Selected'),
          trailing: const Icon(Icons.edit, size: 16),
          onTap: () async {
            // MOCK: Open DiagonosisMultiSelectDialog
            final selectedIds = await showDialog<List<String>>(
              context: context,
              builder: (ctx) => const DiagnosisMultiSelectDialog(initialSelectedIds: [],  allDiagnoses: [],), // Use your actual widget
            );
            if (selectedIds != null && mounted) {
              setState(() => _selectedDiagnosisIds = selectedIds);
            }
          },
        ),
      ],
    );
  }

  Widget _buildGuidelinesContent() {
    return const GuidelineMultiSelect(initialSelectedIds: [],); // Use your actual GuidelineWidget
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return AlertDialog(
      title: const Text('Edit Plan Details & Linkage'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.7,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailsContent(),
                const Divider(height: 30),
                _buildLinkageContent(),
                const Divider(height: 30),
                _buildGuidelinesContent(),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('CANCEL'),
        ),
        ElevatedButton(
          onPressed: _saveDetails,
          child: const Text('CONFIRM DETAILS'),
        ),
      ],
    );
  }
}