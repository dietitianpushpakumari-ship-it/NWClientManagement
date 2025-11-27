import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

// 🎯 Project Imports
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
import 'package:nutricare_client_management/screens/vitals_entry_form_screen.dart';

// --- Result Model ---
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

  // Controllers
  final _nameController = TextEditingController();
  final _generalPlanNotesController = TextEditingController();
  final _followUpDaysController = TextEditingController();
  final _clinicalNotesController = TextEditingController();
  final _complaintController = TextEditingController();

  // Data
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
      if (test(element)) return element;
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

  // --- DIALOG ACTIONS ---

  void _showSupplementationSelectionDialog() async {
    final List<String>? finalSelection = await showDialog<List<String>>(
      context: context,
      builder: (BuildContext context) => SupplementationMultiSelectDialog(
        initialSelectedIds: _selectedSupplementationIds,
      ),
    );

    if (finalSelection != null) {
      // Refresh master list in case new items added
      final newSupplementations = await SupplimentMasterService().fetchAllSupplimentMaster();
      setState(() {
        _selectedSupplementationIds = finalSelection;
        _allSupplementations = newSupplementations;
      });
    }
  }

  Future<void> _showDiagnosisSelectionDialog() async {
    final List<String>? finalSelection = await showDialog<List<String>>(
      context: context,
      builder: (BuildContext context) => DiagnosisMultiSelectDialog(
        allDiagnoses: _allDiagnoses,
        initialSelectedIds: _selectedDiagnosisIds,
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

  void _showGuidelineDialog() async {
    final selected = await showDialog<List<String>>(
      context: context,
      builder: (context) => GuidelineMultiSelect(initialSelectedIds: _selectedGuidelineIds),
    );
    if (selected != null) {
      setState(() => _selectedGuidelineIds = selected);
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

  void _saveAndReturn() {
    if (_formKey.currentState!.validate()) {
      if (_linkedVitalsId == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please link a Vitals record before saving.'), backgroundColor: Colors.orange));
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

  // --- UI BUILDERS ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: Stack(
        children: [
          // Ambient Background
          Positioned(
              top: -100, right: -100,
              child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.indigo.withOpacity(0.05), blurRadius: 80, spreadRadius: 20)]))),

          SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
              children: [
                // 1. Custom Header
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
                          child: const Icon(Icons.arrow_back, size: 20, color: Colors.black87),
                        ),
                      ),
                      const Text("Plan Settings", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
                      ElevatedButton.icon(
                        onPressed: _saveAndReturn,
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text("DONE"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                      )
                    ],
                  ),
                ),

                // 2. Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // --- CARD 1: IDENTITY ---
                          _buildPremiumCard(
                            title: "Plan Identity",
                            icon: Icons.badge,
                            color: Colors.indigo,
                            child: Column(
                              children: [
                                _buildTextField("Plan Name", _nameController, hint: "e.g. Weight Loss Week 1"),
                                const SizedBox(height: 16),
                                _buildTextField("Follow-up (Days)", _followUpDaysController, hint: "7", isNumber: true),
                              ],
                            ),
                          ),

                          // --- CARD 2: CLINICAL CONTEXT ---
                          _buildPremiumCard(
                            title: "Clinical Context",
                            icon: Icons.medical_services,
                            color: Colors.purple,
                            child: Column(
                              children: [
                                // Vitals Linker
                                _buildVitalsLinker(),
                                const SizedBox(height: 20),

                                // Diagnosis
                                _buildSectionHeader("Diagnosis", Icons.local_hospital, Colors.red, _showDiagnosisSelectionDialog),
                                _buildChipGroup(_selectedDiagnosisIds.map((id) => _safeFirstWhere(_allDiagnoses, (d) => d.id == id)?.enName ?? id).toList(), (id) => setState(() => _selectedDiagnosisIds.remove(id))),

                                const SizedBox(height: 20),
                                _buildTextField("Primary Complaints", _complaintController, maxLines: 2),
                                const SizedBox(height: 16),
                                _buildTextField("Clinical Notes", _clinicalNotesController, maxLines: 2),
                              ],
                            ),
                          ),

                          // --- CARD 3: PROTOCOLS ---
                          _buildPremiumCard(
                            title: "Protocols",
                            icon: Icons.rule,
                            color: Colors.teal,
                            child: Column(
                              children: [
                                // Guidelines
                                _buildSectionHeader("Guidelines", Icons.list_alt, Colors.blueGrey, _showGuidelineDialog),
                                if (_selectedGuidelineIds.isNotEmpty)
                                  FutureBuilder<List<Guideline>>(
                                    future: GuidelineService().fetchGuidelinesByIds(_selectedGuidelineIds),
                                    builder: (ctx, snap) => _buildChipGroup((snap.data ?? []).map((g) => g.enTitle).toList(), (val) {}), // Delete handled in dialog usually, but visual here
                                  )
                                else
                                  const Text("No guidelines added.", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),

                                const SizedBox(height: 20),

                                // Investigations
                                _buildSectionHeader("Investigations", Icons.science, Colors.blue, _showInvestigationSelectionDialog),
                                _buildChipGroup(_selectedInvestigationIds.map((id) => _safeFirstWhere(_allInvestigations, (i) => i.id == id)?.enName ?? id).toList(), (v) => setState(() => _selectedInvestigationIds.remove(v))),

                                const SizedBox(height: 20),

                                // Supplements
                                _buildSectionHeader("Supplementation", Icons.medication_liquid, Colors.green, _showSupplementationSelectionDialog),
                                _buildChipGroup(_selectedSupplementationIds.map((id) => _safeFirstWhere(_allSupplementations, (s) => s.id == id)?.enName ?? id).toList(), (v) => setState(() => _selectedSupplementationIds.remove(v))),
                              ],
                            ),
                          ),

                          // --- CARD 4: INSTRUCTIONS ---
                          _buildPremiumCard(
                            title: "Instructions to Client",
                            icon: Icons.description,
                            color: Colors.orange,
                            child: _buildTextField("General Instructions", _generalPlanNotesController, maxLines: 3, hint: "Specific notes for the client..."),
                          ),

                          // View History Link
                          Padding(
                            padding: const EdgeInsets.only(bottom: 40.0),
                            child: OutlinedButton.icon(
                              onPressed: () => setState(() {}), // Toggle History (impl inside widget if needed)
                              icon: const Icon(Icons.history),
                              label: const Text("View Vitals History"),
                            ),
                          ),
                          // To keep simple, we can just show the widget
                          if (_clientVitals.isNotEmpty)
                            ExpansionTile(title: const Text("Full Vitals History"), children: [LabVitalsHistoryWidget(clientVitals: _clientVitals)]),

                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET HELPERS ---

  Widget _buildPremiumCard({required String title, required IconData icon, required Color color, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 20)),
            const SizedBox(width: 12),
            Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          ]),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildVitalsLinker() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Linked Vitals Record", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _linkedVitalsId,
              hint: const Text("Select Record"),
              items: _clientVitals.map((v) => DropdownMenuItem(
                value: v.id,
                child: Text("${DateFormat('dd MMM').format(v.date)} - ${v.weightKg}kg", style: const TextStyle(fontWeight: FontWeight.w600)),
              )).toList(),
              onChanged: (v) => setState(() {
                _linkedVitalsId = v;
                _linkedVitalsRecord = _safeFirstWhere(_clientVitals, (r) => r.id == v);
              }),
            ),
          ),
          if (_linkedVitalsRecord != null) ...[
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("BMI: ${_linkedVitalsRecord!.bmi.toStringAsFixed(1)}", style: const TextStyle(fontSize: 12)),
                if (_linkedVitalsRecord!.bodyFatPercentage > 0) Text("Fat: ${_linkedVitalsRecord!.bodyFatPercentage}%", style: const TextStyle(fontSize: 12)),
                TextButton(onPressed: () => _editVitals(_linkedVitalsRecord), child: const Text("View Full", style: TextStyle(fontSize: 12)))
              ],
            )
          ]
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl, {int maxLines = 1, String? hint, bool isNumber = false}) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
      ),
      validator: (v) => v!.isEmpty && label.contains("Name") ? "Required" : null,
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color, VoidCallback onAdd) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [Icon(icon, size: 16, color: color), const SizedBox(width: 8), Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))]),
          InkWell(onTap: onAdd, child: Icon(Icons.add_circle, color: color, size: 20)),
        ],
      ),
    );
  }

  Widget _buildChipGroup(List<String> items, Function(String) onRemove) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((e) => Chip(
        label: Text(e, style: const TextStyle(fontSize: 11)),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade300)),
        deleteIcon: const Icon(Icons.close, size: 14, color: Colors.grey),
        onDeleted: () => onRemove(e), // This needs mapping logic for IDs if e is name
        visualDensity: VisualDensity.compact,
      )).toList(),
    );
  }
}