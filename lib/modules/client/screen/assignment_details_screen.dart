// lib/screens/assignment_details_screen.dart (FINAL FIX)

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
    this.selectedSupplementationIds = const[]
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
    this.initialSelectedSupplementationIds = const[],
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
  List<VitalsModel> _clientVitals = []; // Stores all vitals history
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
    _selectedInvestigationIds = List.from(widget.initialSelectedInvestigationIds); // 🎯 INIT NEW STATE
    _selectedSupplementationIds = List.from(widget.initialSelectedSupplementationIds); // 🎯 INIT NEW STATE
    _loadLinkageData(widget.clientId);
  }

  // Helper function to safely find an element or return null
  T? _safeFirstWhere<T>(Iterable<T> list, bool Function(T) test) {
    for (var element in list) {
      if (test(element)) {
        return element;
      }
    }
    return null;
  }

  void _loadLinkageData(String clientId) async {
    // 1. Load Diagnoses Master List
    final diagnoses = await DiagnosisMasterService().fetchAllDiagnosisMaster();
final investigation  = await InvestigationMasterService().fetchAllInvestigationMaster();
    // 2. Load Client Vitals History
    final vitals = await VitalsService().getClientVitals(clientId);
    final supplementations = await SupplimentMasterService().fetchAllSupplimentMaster(); // 🎯 NEW FUTURE
    vitals.sort((a, b) => b.date.compareTo(a.date));
    _isLoading = false;
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
        _allSupplementations = newSupplementations; // Refresh the master list
      });
    }
  }

  // 🎯 NEW UI: Supplementation Chip Display Section
  Widget _buildSupplementationChipDisplay() {
    final selectedSupplementations = _selectedSupplementationIds
        .map((id) {
      return _safeFirstWhere(_allSupplementations, (i) => i.id == id);
    })
        .whereType<SupplimentMasterModel>()
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recommended Supplementation',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              icon: const Icon(Icons.medication, size: 18, color: Colors.green),
              label: Text(
                 'Select (${_selectedSupplementationIds.length})',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onPressed: _showSupplementationSelectionDialog,
            ),
          ],
        ),
        const Divider(),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: [
            if (selectedSupplementations.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text('No supplements selected.', style: TextStyle(fontStyle: FontStyle.italic)),
              ),
            ...selectedSupplementations.map((supplementation) {
              return Chip(
                label: Text(supplementation.enName),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () {
                  setState(() {
                    _selectedSupplementationIds.remove(supplementation.id);
                  });
                },
                backgroundColor: Colors.green.shade100,
                labelStyle: TextStyle(color: Colors.green.shade800),
              );
            }).toList(),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // 🎯 NEW METHOD: Navigate to Vitals Entry Screen for editing
  void _editVitals(VitalsModel? vitals) async {
    if (vitals == null) return;

    // Navigate to the edit screen, passing the VitalsModel
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => VitalsEntryPage(clientId: widget.clientId, clientName: '',
          vitalsToEdit: vitals, onVitalsSaved: () {  }, isFirstConsultation: false,
        ),
      ),
    );

    // After returning from the edit screen, reload data to update the dropdown/history
    _loadLinkageData(widget.clientId);
  }

  Future<void> _showDiagnosisSelectionDialog() async {
    final List<String> initialSelection = List.from(_selectedDiagnosisIds);

    final List<String>? finalSelection = await showDialog<List<String>>(
      context: context,
      builder: (BuildContext context) {
        return DiagnosisMultiSelectDialog(
          allDiagnoses: _allDiagnoses,
          initialSelectedIds: initialSelection,
        );
      },
    );

    if (finalSelection != null) {
      setState(() {
        _selectedDiagnosisIds = finalSelection;
      });
    }
  }

  // UI: Diagnosis Chip Display (Omitted for brevity, remains unchanged)
  Widget _buildDiagnosisChipDisplay() {
    final selectedDiagnoses = _selectedDiagnosisIds
        .map((id) {
      return _safeFirstWhere(_allDiagnoses, (d) => d.id == id);
    })
        .whereType<DiagnosisMasterModel>()
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: [
            ...selectedDiagnoses.map((diagnosis) {
              return Chip(
                label: Text(diagnosis.enName),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () {
                  setState(() {
                    _selectedDiagnosisIds.remove(diagnosis.id);
                  });
                },
                backgroundColor: Colors.red.shade100,
                labelStyle: TextStyle(color: Colors.red.shade800),
              );
            }).toList(),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // UI: Guideline Selection and Display Section (Omitted for brevity, remains unchanged)
  Widget _buildGuidelineSelectionSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Assigned Guidelines',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Edit Guidelines'),
                onPressed: () async {
                  final selected = await showDialog<List<String>>(
                    context: context,
                    builder: (context) => GuidelineMultiSelect(
                      initialSelectedIds: _selectedGuidelineIds,
                    ),
                  );

                  if (selected != null) {
                    setState(() {
                      _selectedGuidelineIds = selected;
                    });
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 8),

          _selectedGuidelineIds.isEmpty
              ? const Text(
            'No guidelines tagged.',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: Colors.grey,
            ),
          )
              : FutureBuilder<List<Guideline>>(
            future: GuidelineService().fetchGuidelinesByIds(
              _selectedGuidelineIds,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LinearProgressIndicator();
              }
              final guidelines = snapshot.data ?? [];

              return Wrap(
                spacing: 6.0,
                runSpacing: 6.0,
                children: guidelines
                    .map(
                      (g) => Chip(
                    label: Text(
                      g.enTitle,
                      style: const TextStyle(fontSize: 13),
                    ),
                    backgroundColor: Colors.blue.shade50,
                    deleteIcon: const Icon(Icons.cancel, size: 18),
                    onDeleted: () {
                      setState(() {
                        _selectedGuidelineIds.remove(g.id);
                      });
                    },
                  ),
                )
                    .toList(),
              );
            },
          ),
          const Divider(),
        ],
      ),
    );
  }

  // UI: Vitals Linker (UPDATED with Edit button)
  Widget _buildVitalsLinker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Clinical Vitals Record Date',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  value: _linkedVitalsId,
                  hint: const Text('Select Vitals entry to link report to'),
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('--- Clear Link ---'),
                    ),
                    ..._clientVitals.map((vitals) {
                      return DropdownMenuItem<String>(
                        value: vitals.id,
                        child: Text(
                          '${DateFormat.yMMMd().format(vitals.date)} - ${vitals.weightKg.toStringAsFixed(1)} kg',
                          style: TextStyle(
                            fontWeight: _linkedVitalsId == vitals.id
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
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
            ),
            // 🎯 NEW: Edit Button
            Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: IconButton(
                icon: const Icon(Icons.edit, color: Colors.indigo),
                tooltip: 'Edit Linked Vitals',
                onPressed: _linkedVitalsRecord != null
                    ? () => _editVitals(_linkedVitalsRecord)
                    : null,
              ),
            ),
          ],
        ),
        if (_linkedVitalsRecord != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 8),
            child: Text(
              'Linked Vitals: Weight ${_linkedVitalsRecord!.weightKg} kg, BFP ${_linkedVitalsRecord!.bodyFatPercentage}%',
              style: TextStyle(color: Colors.green.shade700, fontSize: 12),
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  void _showInvestigationSelectionDialog() async {
    // Pass the current list of selected IDs
    final List<String>? finalSelection = await showDialog<List<String>>(
      context: context,
      builder: (BuildContext context) {
        return InvestigationMultiSelectDialog(
          initialSelectedIds: _selectedInvestigationIds,
        );
      },
    );

    if (finalSelection != null) {
      // FIX: Reload the master list after the dialog closes.
      // This is crucial because a new investigation might have been created inside the dialog.
      final newInvestigations = await InvestigationMasterService().fetchAllInvestigationMaster();

      setState(() {
        _selectedInvestigationIds = finalSelection;
        _allInvestigations = newInvestigations; // Refresh the master list
      });
    }
  }

  // 🎯 NEW UI: Investigation Chip Display Section
  Widget _buildInvestigationChipDisplay() {
    final selectedInvestigations = _selectedInvestigationIds
        .map((id) {
      return _safeFirstWhere(_allInvestigations, (i) => i.id == id);
    })
        .whereType<InvestigationMasterModel>()
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recommended Investigations',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              icon: const Icon(Icons.list, size: 18, color: Colors.indigo),
              label: Text('Select (${_selectedInvestigationIds.length})',
                style: const TextStyle(
                  color: Colors.indigo,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onPressed: _showInvestigationSelectionDialog,
            ),
          ],
        ),
        const Divider(),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: [
            if (selectedInvestigations.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text('No investigations selected.', style: TextStyle(fontStyle: FontStyle.italic)),
              ),
            ...selectedInvestigations.map((investigation) {
              return Chip(
                label: Text(investigation.enName),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () {
                  setState(() {
                    _selectedInvestigationIds.remove(investigation.id);
                  });
                },
                backgroundColor: Colors.blue.shade100,
                labelStyle: TextStyle(color: Colors.blue.shade800),
              );
            }).toList(),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  void _saveAndReturn() {
    if (_formKey.currentState!.validate()) {
      // ... (Validation and save logic remains unchanged)
      if (_linkedVitalsId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please link a Vitals record before saving.'),
          ),
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
          selectedInvestigationIds: _selectedInvestigationIds
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Assignment Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assignment Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveAndReturn,
            tooltip: 'Save Details',
          ),
        ],
      ),
      body: SafeArea(child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Plan Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Plan Name / Title (e.g., Keto 1500 KCal)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 20),

              // 2. Follow-up Days
              const Text(
                'Follow-up Days (Optional)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _followUpDaysController,
                decoration: const InputDecoration(
                  labelText: 'Enter number of days until next follow-up',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 20),

              // 3. Complaint Section
              const Text(
                'Primary Complaints (e.g., Joint Pain, Constipation)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _complaintController,
                decoration: const InputDecoration(
                  labelText: 'Client\'s main health complaints',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 20),

              // 4. Clinical Notes
              const Text(
                'Clinical Notes / Context',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _clinicalNotesController,
                decoration: const InputDecoration(
                  labelText: 'Enter summary of physical exam, lab results context, etc.',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 20),

              // 5. Vitals Linker (Now includes Edit button)
              const Text(
                'Clinical Vitals Linker',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              _buildVitalsLinker(),

              // 6. Lab Vitals History (NEW ExpansionTile)
              const SizedBox(height: 10),
              ExpansionTile(
                title: const Text(
                  'Lab Vitals History (For Viewing)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                leading: const Icon(Icons.history),
                initiallyExpanded: false,
                children: [
                  LabVitalsHistoryWidget(clientVitals: _clientVitals),
                ],
              ),
              const SizedBox(height: 20),

              // 7. Diagnosis (Unchanged)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Diagnosis',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.search, size: 18, color: Colors.indigo),
                    label: Text(
                      _selectedDiagnosisIds.isEmpty
                          ? 'Select Diagnosis'
                          : 'Edit Diagnoses (${_selectedDiagnosisIds.length})',
                      style: const TextStyle(
                        color: Colors.indigo,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onPressed: _showDiagnosisSelectionDialog,
                  ),
                ],
              ),
              const Divider(),
              _buildDiagnosisChipDisplay(),

              _buildInvestigationChipDisplay(),

              // 8. Guidelines (Unchanged)
              _buildGuidelineSelectionSection(context),
              _buildSupplementationChipDisplay(),

              // 9. General Plan Notes (Unchanged)
              const Text(
                'General Plan Instructions',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _generalPlanNotesController,
                decoration: const InputDecoration(
                  labelText: 'Enter specific usage instructions or general notes for the client',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),),
    );
  }
}