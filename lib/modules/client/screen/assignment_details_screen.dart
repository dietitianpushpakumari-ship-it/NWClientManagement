import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
// 🎯 ADJUST THESE IMPORTS TO YOUR PROJECT STRUCTURE
import 'package:nutricare_client_management/modules/client/model/client_diet_plan_model.dart';
import 'package:nutricare_client_management/modules/client/model/vitals_model.dart';
import 'package:nutricare_client_management/modules/client/screen/Suppliment_master_service.dart';
import 'package:nutricare_client_management/modules/client/screen/investigation_master_model.dart';
import 'package:nutricare_client_management/modules/client/screen/investigation_master_service.dart';
import 'package:nutricare_client_management/modules/client/screen/investigation_multi_select_dialog.dart';

import 'package:nutricare_client_management/modules/client/screen/lab_vitals_history_widget.dart';
import 'package:nutricare_client_management/modules/client/screen/suppliment_master_model.dart';
import 'package:nutricare_client_management/modules/client/screen/supplimentation_multi_select_dialog.dart';
import 'package:nutricare_client_management/modules/master/model/diagonosis_master.dart';
import 'package:nutricare_client_management/modules/master/model/guidelines.dart';
import 'package:nutricare_client_management/modules/client/services/vitals_service.dart';
import 'package:nutricare_client_management/modules/master/service/diagonosis_master_service.dart';
import 'package:nutricare_client_management/modules/master/service/guideline_service.dart';
import 'package:nutricare_client_management/widgets/diagonosis_multi_select_dialog.dart';
import 'package:nutricare_client_management/widgets/GuidelineWidget.dart';
import 'package:nutricare_client_management/admin/custom_gradient_app_bar.dart';

import '../../../screens/vitals_entry_form_screen.dart';

// --- Data Model for Result ---
class AssignmentDetailsResult {
  final String planName;
  final String? linkedVitalsId;
  final List<String> selectedDiagnosisIds;
  final List<String> selectedGuidelineIds;
  final String generalPlanNotes;
  final int followUpDays;
  final String clinicalNotes;
  final String primaryComplaints;
  final List<String> selectedInvestigationIds;
  final List<String> selectedSupplementationIds;

  AssignmentDetailsResult({
    required this.planName,
    this.linkedVitalsId,
    this.selectedDiagnosisIds = const [],
    this.selectedGuidelineIds = const [],
    required this.generalPlanNotes,
    this.followUpDays = 0,
    required this.clinicalNotes,
    required this.primaryComplaints,
    this.selectedInvestigationIds = const [],
    this.selectedSupplementationIds = const [],
  });
}

class AssignmentDetailsScreen extends StatefulWidget {
  final String clientId;
  final String initialPlanName;
  final String? initialLinkedVitalsId;
  final List<String> initialSelectedDiagnosisIds;
  final List<String> initialSelectedGuidelineIds;
  final String initialGeneralPlanNotes;
  final int? initialFollowUpDays;
  final String initialClinicalNotes;
  final String initialPrimaryComplaints;
  final List<String> initialSelectedInvestigationIds;
  final List<String> initialSelectedSupplementationIds;

  const AssignmentDetailsScreen({
    super.key,
    required this.clientId,
    required this.initialPlanName,
    this.initialLinkedVitalsId,
    required this.initialSelectedDiagnosisIds,
    required this.initialSelectedGuidelineIds,
    this.initialGeneralPlanNotes = '',
    this.initialFollowUpDays = 0,
    this.initialClinicalNotes = '',
    this.initialPrimaryComplaints = '',
    this.initialSelectedInvestigationIds = const [],
    this.initialSelectedSupplementationIds = const [],
  });

  @override
  State<AssignmentDetailsScreen> createState() => _AssignmentDetailsScreenState();
}

class _AssignmentDetailsScreenState extends State<AssignmentDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _generalPlanNotesController = TextEditingController();
  final _followUpDaysController = TextEditingController();
  final _clinicalNotesController = TextEditingController();
  final _complaintController = TextEditingController();

  List<DiagnosisMasterModel> _allDiagnoses = [];
  List<VitalsModel> _clientVitals = [];
  List<String> _selectedDiagnosisIds = [];
  String? _linkedVitalsId;
  VitalsModel? _linkedVitalsRecord;
  List<String> _selectedGuidelineIds = [];
  bool _isLoading = true;
  List<InvestigationMasterModel> _allInvestigations = [];
  List<String> _selectedInvestigationIds = [];
  List<SupplimentMasterModel> _allSupplementations = [];
  List<String> _selectedSupplementationIds = [];

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.initialPlanName;
    _generalPlanNotesController.text = widget.initialGeneralPlanNotes;
    _followUpDaysController.text = widget.initialFollowUpDays.toString();
    _clinicalNotesController.text = widget.initialClinicalNotes;
    _complaintController.text = widget.initialPrimaryComplaints;

    _selectedDiagnosisIds = List.from(widget.initialSelectedDiagnosisIds);
    _linkedVitalsId = widget.initialLinkedVitalsId;
    _selectedGuidelineIds = List.from(widget.initialSelectedGuidelineIds);
    _selectedInvestigationIds = List.from(widget.initialSelectedInvestigationIds);
    _selectedSupplementationIds = List.from(widget.initialSelectedSupplementationIds);
    _loadLinkageData(widget.clientId);
  }

  T? _safeFirstWhere<T>(Iterable<T> list, bool Function(T) test) {
    for (var element in list) {
      if (test(element)) {
        return element;
      }
    }
    return null;
  }

  void _loadLinkageData(String clientId) async {
    final diagnoses = await DiagnosisMasterService().fetchAllDiagnosisMaster();
    final investigation = await InvestigationMasterService().fetchAllInvestigationMaster();
    final vitals = await VitalsService().getClientVitals(clientId);
    final supplementations = await SupplimentMasterService().fetchAllSupplimentMaster();

    vitals.sort((a, b) => b.date.compareTo(a.date));

    if (mounted) {
      setState(() {
        _allDiagnoses = diagnoses;
        _clientVitals = vitals;
        _allSupplementations = supplementations;
        _allInvestigations = investigation;

        if (_linkedVitalsId != null) {
          _linkedVitalsRecord = _safeFirstWhere(_clientVitals, (v) => v.id == _linkedVitalsId);
        }
        _isLoading = false;
      });
    }
  }

  // --- DIALOGS ---

  void _showSupplementationSelectionDialog() async {
    final List<String>? finalSelection = await showDialog<List<String>>(
      context: context,
      builder: (BuildContext context) {
        return SupplementationMultiSelectDialog(
          initialSelectedIds: _selectedSupplementationIds,
        );
      },
    );

    if (finalSelection != null) {
      final newSupplementations = await SupplimentMasterService().fetchAllSupplimentMaster();
      setState(() {
        _selectedSupplementationIds = finalSelection;
        _allSupplementations = newSupplementations;
      });
    }
  }

  Future<void> _showDiagnosisSelectionDialog() async {
    final List<String> initialSelection = List.from(_selectedDiagnosisIds);
    final List<String>? finalSelection = await showDialog<List<String>>(
      context: context,
      builder: (BuildContext context) => DiagnosisMultiSelectDialog(
        allDiagnoses: _allDiagnoses,
        initialSelectedIds: initialSelection,
      ),
    );

    if (finalSelection != null) {
      setState(() => _selectedDiagnosisIds = finalSelection);
    }
  }

  void _showInvestigationSelectionDialog() async {
    final List<String>? finalSelection = await showDialog<List<String>>(
      context: context,
      builder: (BuildContext context) => InvestigationMultiSelectDialog(
        initialSelectedIds: _selectedInvestigationIds,
      ),
    );

    if (finalSelection != null) {
      final newInvestigations = await InvestigationMasterService().fetchAllInvestigationMaster();
      setState(() {
        _selectedInvestigationIds = finalSelection;
        _allInvestigations = newInvestigations;
      });
    }
  }

  void _editVitals(VitalsModel? vitals) async {
    if (vitals == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => VitalsEntryPage(
          clientId: widget.clientId,
          clientName: '',
          vitalsToEdit: vitals,
          onVitalsSaved: () {},
          isFirstConsultation: false,
        ),
      ),
    );
    _loadLinkageData(widget.clientId);
  }

  // --- UI HELPERS ---

  // 🎯 HELPER: Standardized Section Header with Overflow protection
  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    VoidCallback? onAction,
    String? actionLabel,
    Color color = Colors.indigo,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 🎯 FIX: Expanded prevents overflow for long titles
        Expanded(
          child: Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        if (onAction != null && actionLabel != null)
          TextButton.icon(
            icon: Icon(Icons.add_circle_outline, size: 18, color: color),
            label: Text(
              actionLabel,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: onAction,
          ),
      ],
    );
  }

  // 🎯 HELPER: Standard Input Field Decoration
  InputDecoration _inputDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      filled: true,
      fillColor: Colors.grey.shade50,
      isDense: true,
      contentPadding: const EdgeInsets.all(14),
    );
  }

  // --- BUILDERS ---

  Widget _buildSupplementationSection() {
    final selectedSupplementations = _selectedSupplementationIds
        .map((id) => _safeFirstWhere(_allSupplementations, (i) => i.id == id))
        .whereType<SupplimentMasterModel>()
        .toList();

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              title: 'Supplementation',
              icon: Icons.medication_liquid,
              onAction: _showSupplementationSelectionDialog,
              actionLabel: 'Edit (${_selectedSupplementationIds.length})',
              color: Colors.green.shade700,
            ),
            const Divider(height: 12),
            if (selectedSupplementations.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text('No supplements selected.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
              )
            else
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: selectedSupplementations.map((s) {
                  return Chip(
                    label: Text(s.enName),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => setState(() => _selectedSupplementationIds.remove(s.id)),
                    backgroundColor: Colors.green.shade50,
                    labelStyle: TextStyle(color: Colors.green.shade900),
                    side: BorderSide.none,
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosisSection() {
    final selectedDiagnoses = _selectedDiagnosisIds
        .map((id) => _safeFirstWhere(_allDiagnoses, (d) => d.id == id))
        .whereType<DiagnosisMasterModel>()
        .toList();

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              title: 'Diagnosis',
              icon: Icons.local_hospital,
              onAction: _showDiagnosisSelectionDialog,
              actionLabel: 'Edit (${_selectedDiagnosisIds.length})',
              color: Colors.red.shade700,
            ),
            const Divider(height: 12),
            if (selectedDiagnoses.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text('No diagnoses selected.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
              )
            else
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: selectedDiagnoses.map((d) {
                  return Chip(
                    label: Text(d.enName),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => setState(() => _selectedDiagnosisIds.remove(d.id)),
                    backgroundColor: Colors.red.shade50,
                    labelStyle: TextStyle(color: Colors.red.shade900),
                    side: BorderSide.none,
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvestigationSection() {
    final selectedInvestigations = _selectedInvestigationIds
        .map((id) => _safeFirstWhere(_allInvestigations, (i) => i.id == id))
        .whereType<InvestigationMasterModel>()
        .toList();

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              title: 'Recommended Investigations',
              icon: Icons.science,
              onAction: _showInvestigationSelectionDialog,
              actionLabel: 'Edit (${_selectedInvestigationIds.length})',
              color: Colors.blue.shade700,
            ),
            const Divider(height: 12),
            if (selectedInvestigations.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text('No investigations selected.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
              )
            else
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: selectedInvestigations.map((i) {
                  return Chip(
                    label: Text(i.enName),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => setState(() => _selectedInvestigationIds.remove(i.id)),
                    backgroundColor: Colors.blue.shade50,
                    labelStyle: TextStyle(color: Colors.blue.shade900),
                    side: BorderSide.none,
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuidelineSection() {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              title: 'Assigned Guidelines',
              icon: Icons.rule,
              onAction: () async {
                final selected = await showDialog<List<String>>(
                  context: context,
                  builder: (context) => GuidelineMultiSelect(
                    initialSelectedIds: _selectedGuidelineIds,
                  ),
                );
                if (selected != null) {
                  setState(() => _selectedGuidelineIds = selected);
                }
              },
              actionLabel: 'Edit (${_selectedGuidelineIds.length})',
              color: Colors.orange.shade800,
            ),
            const Divider(height: 12),
            _selectedGuidelineIds.isEmpty
                ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text('No guidelines tagged.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
            )
                : FutureBuilder<List<Guideline>>(
              future: GuidelineService().fetchGuidelinesByIds(_selectedGuidelineIds),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const LinearProgressIndicator();
                final guidelines = snapshot.data ?? [];
                return Wrap(
                  spacing: 6.0,
                  runSpacing: 6.0,
                  children: guidelines.map((g) => Chip(
                    label: Text(g.enTitle, style: const TextStyle(fontSize: 13)),
                    backgroundColor: Colors.orange.shade50,
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => setState(() => _selectedGuidelineIds.remove(g.id)),
                    side: BorderSide.none,
                    labelStyle: TextStyle(color: Colors.orange.shade900),
                  )).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalsLinker() {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              title: 'Vitals Linker',
              icon: Icons.link,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: _inputDecoration('Select Vitals Record'),
                    value: _linkedVitalsId,
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem<String>(value: null, child: Text('--- Clear Link ---')),
                      ..._clientVitals.map((vitals) {
                        return DropdownMenuItem<String>(
                          value: vitals.id,
                          child: Text(
                            '${DateFormat.yMMMd().format(vitals.date)} - ${vitals.weightKg.toStringAsFixed(1)} kg',
                            style: TextStyle(fontWeight: _linkedVitalsId == vitals.id ? FontWeight.bold : FontWeight.normal),
                          ),
                        );
                      }).toList(),
                    ],
                    onChanged: (String? newValue) {
                      setState(() {
                        _linkedVitalsId = newValue;
                        _linkedVitalsRecord = _safeFirstWhere(_clientVitals, (v) => v.id == newValue);
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.indigo),
                  tooltip: 'Edit Linked Vitals',
                  onPressed: _linkedVitalsRecord != null ? () => _editVitals(_linkedVitalsRecord) : null,
                  style: IconButton.styleFrom(backgroundColor: Colors.grey.shade100),
                ),
              ],
            ),
            if (_linkedVitalsRecord != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 4),
                child: Text(
                  'Linked: Weight ${_linkedVitalsRecord!.weightKg} kg, BFP ${_linkedVitalsRecord!.bodyFatPercentage}%',
                  style: TextStyle(color: Colors.green.shade700, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _saveAndReturn() {
    if (_formKey.currentState!.validate()) {
      if (_linkedVitalsId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please link a Vitals record before saving.')),
        );
        return;
      }

      final days = int.tryParse(_followUpDaysController.text.trim()) ?? 0;

      Navigator.of(context).pop(
        AssignmentDetailsResult(
          planName: _nameController.text.trim(),
          linkedVitalsId: _linkedVitalsId,
          selectedDiagnosisIds: _selectedDiagnosisIds,
          selectedGuidelineIds: _selectedGuidelineIds,
          generalPlanNotes: _generalPlanNotesController.text.trim(),
          followUpDays: days,
          clinicalNotes: _clinicalNotesController.text.trim(),
          primaryComplaints: _complaintController.text.trim(),
          selectedSupplementationIds: _selectedSupplementationIds,
          selectedInvestigationIds: _selectedInvestigationIds,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomGradientAppBar(
        title: const Text('Assignment Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveAndReturn,
            tooltip: 'Save Details',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- HEADER CARD (Plan Name) ---
                Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  color: Colors.indigo.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextFormField(
                      controller: _nameController,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
                      decoration: const InputDecoration(
                        labelText: 'Plan Name',
                        hintText: 'e.g., Keto 1500 KCal',
                        border: InputBorder.none,
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                      ),
                      validator: (value) => value!.isEmpty ? 'Name is required' : null,
                    ),
                  ),
                ),

                // --- CLINICAL CONTEXT CARD ---
                Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(title: 'Clinical Context', icon: Icons.assignment),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _complaintController,
                          decoration: _inputDecoration('Primary Complaints', hint: 'e.g., Joint Pain'),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _clinicalNotesController,
                          decoration: _inputDecoration('Clinical Notes', hint: 'Summary of assessment'),
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ),

                // --- VITALS & DIAGNOSIS ---
                _buildVitalsLinker(),
                _buildDiagnosisSection(),

                // --- INVESTIGATIONS & SUPPLEMENTS ---
                _buildInvestigationSection(),
                _buildSupplementationSection(),

                // --- GUIDELINES ---
                _buildGuidelineSection(),

                // --- PLAN INSTRUCTIONS ---
                Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(title: 'Plan Instructions', icon: Icons.description),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _generalPlanNotesController,
                          decoration: _inputDecoration('General Instructions', hint: 'Specific usage notes for client'),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _followUpDaysController,
                          decoration: _inputDecoration('Follow-up in (Days)', hint: '7'),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        ),
                      ],
                    ),
                  ),
                ),

                // --- HISTORY (Collapsible) ---
                ExpansionTile(
                  title: const Text('View Lab Vitals History', style: TextStyle(fontWeight: FontWeight.bold)),
                  leading: const Icon(Icons.history, color: Colors.grey),
                  children: [LabVitalsHistoryWidget(clientVitals: _clientVitals)],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}