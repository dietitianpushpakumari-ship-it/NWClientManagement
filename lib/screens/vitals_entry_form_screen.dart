import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nutricare_client_management/admin/labvital/body_vitals_section.dart';
import 'package:nutricare_client_management/admin/labvital/clinical_model.dart';
import 'package:nutricare_client_management/admin/labvital/clinical_profile_section.dart';
import 'package:nutricare_client_management/helper/lab_vitals_data.dart';
import 'package:nutricare_client_management/modules/client/model/vitals_model.dart';
import 'package:nutricare_client_management/modules/client/services/vitals_service.dart';

class VitalsEntryPage extends StatefulWidget {
  final String clientId;
  final String clientName;
  final VoidCallback onVitalsSaved;
  final bool isFirstConsultation;
  final VitalsModel? vitalsToEdit;

  const VitalsEntryPage({
    super.key,
    required this.clientId,
    required this.clientName,
    required this.onVitalsSaved,
    required this.isFirstConsultation,
    this.vitalsToEdit,
  });

  @override
  State<VitalsEntryPage> createState() => _VitalsEntryPageState();
}

class _VitalsEntryPageState extends State<VitalsEntryPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;
  bool _isSaving = false;
  DateTime _selectedDate = DateTime.now();

  // --- STATE ---
  List<String> _selectedDiagnosisIds = [];
  Map<String, String> _medicalHistory = {};
  List<String> _selectedComplaints = [];
  List<String> _selectedAllergies = [];
  List<PrescribedMedication> _prescribedMedications = [];
  final _medicationController = TextEditingController();

  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _waistController = TextEditingController();
  final _hipController = TextEditingController();
  final _fatController = TextEditingController();
  final _bpSysController = TextEditingController();
  final _bpDiaController = TextEditingController();
  final _hrController = TextEditingController();
  final _spo2Controller = TextEditingController();

  final Map<String, TextEditingController> _labControllers = {};

  String? _foodHabit;
  String? _activityLevel;
  bool _smoking = false;
  final _smokingCtrl = TextEditingController();
  bool _alcohol = false;
  final _alcoholCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    for(var key in LabVitalsData.allLabTests.keys) _labControllers[key] = TextEditingController();

    if (widget.vitalsToEdit != null) {
      _populateData(widget.vitalsToEdit!);
    }
  }

  void _populateData(VitalsModel data) {
    _selectedDate = data.date;
    _selectedDiagnosisIds = List.from(data.diagnosis);

    if (data.medicalHistoryDurations != null && data.medicalHistoryDurations!.isNotEmpty) {
      final entries = data.medicalHistoryDurations!.split(', ');
      for(var e in entries) {
        final parts = e.split(':');
        if(parts.length > 1) _medicalHistory[parts[0].trim()] = parts[1].trim();
        else _medicalHistory[e.trim()] = "";
      }
    } else {
      for(var h in data.medicalHistory) _medicalHistory[h] = "";
    }

    _selectedComplaints = (data.complaints?.split(',') ?? []).where((s) => s.isNotEmpty).map((e) => e.trim()).toList();
    _selectedAllergies = (data.foodAllergies?.split(',') ?? []).where((s) => s.isNotEmpty).map((e) => e.trim()).toList();
    _prescribedMedications = List.from(data.prescribedMedications);
    if (_prescribedMedications.isEmpty && data.existingMedication != null) _medicationController.text = data.existingMedication!;

    if(data.weightKg > 0) _weightController.text = data.weightKg.toString();
    if(data.heightCm > 0) _heightController.text = data.heightCm.toString();
    if(data.waistCm != null) _waistController.text = data.waistCm.toString();
    if(data.hipCm != null) _hipController.text = data.hipCm.toString();
    if(data.bodyFatPercentage > 0) _fatController.text = data.bodyFatPercentage.toString();

    if(data.bloodPressureSystolic != null) _bpSysController.text = data.bloodPressureSystolic.toString();
    if(data.bloodPressureDiastolic != null) _bpDiaController.text = data.bloodPressureDiastolic.toString();
    if(data.heartRate != null) _hrController.text = data.heartRate.toString();
    if(data.spO2Percentage != null) _spo2Controller.text = data.spO2Percentage.toString();

    data.labResults.forEach((k, v) { if(_labControllers.containsKey(k)) _labControllers[k]!.text = v; });

    _foodHabit = data.foodHabit;
    _activityLevel = data.activityType;
    if(data.otherLifestyleHabits?.containsKey('Smoking') ?? false) {
      _smoking = true; _smokingCtrl.text = data.otherLifestyleHabits!['Smoking']!;
    }
    if(data.otherLifestyleHabits?.containsKey('Alcohol') ?? false) {
      _alcohol = true; _alcoholCtrl.text = data.otherLifestyleHabits!['Alcohol']!;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _medicationController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _waistController.dispose();
    _hipController.dispose();
    _fatController.dispose();
    _bpSysController.dispose();
    _bpDiaController.dispose();
    _hrController.dispose();
    _spo2Controller.dispose();
    _smokingCtrl.dispose();
    _alcoholCtrl.dispose();
    for(var c in _labControllers.values) c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      double h = double.tryParse(_heightController.text) ?? 0;
      double w = double.tryParse(_weightController.text) ?? 0;
      double bmi = (h > 0 && w > 0) ? w / ((h/100)*(h/100)) : 0;
      double ibw = (h > 0) ? 22 * ((h/100)*(h/100)) : 0;

      String historyStr = _medicalHistory.entries.map((e) => "${e.key}:${e.value}").join(", ");
      Map<String, String> labs = {};
      _labControllers.forEach((k, v) { if(v.text.isNotEmpty) labs[k] = v.text; });

      Map<String, String> habits = {};
      if(_smoking) habits['Smoking'] = _smokingCtrl.text;
      if(_alcohol) habits['Alcohol'] = _alcoholCtrl.text;

      final model = VitalsModel(
        id: widget.vitalsToEdit?.id ?? '',
        clientId: widget.clientId,
        date: _selectedDate,
        isFirstConsultation: widget.isFirstConsultation,
        heightCm: h,
        weightKg: w,
        bmi: bmi,
        idealBodyWeightKg: ibw,
        bodyFatPercentage: double.tryParse(_fatController.text) ?? 0,
        waistCm: double.tryParse(_waistController.text),
        hipCm: double.tryParse(_hipController.text),
        measurements: {},
        bloodPressureSystolic: int.tryParse(_bpSysController.text),
        bloodPressureDiastolic: int.tryParse(_bpDiaController.text),
        heartRate: int.tryParse(_hrController.text),
        spO2Percentage: double.tryParse(_spo2Controller.text),
        diagnosis: _selectedDiagnosisIds,
        medicalHistory: _medicalHistory.keys.toList(),
        medicalHistoryDurations: historyStr,
        complaints: _selectedComplaints.join(", "),
        foodAllergies: _selectedAllergies.join(", "),
        prescribedMedications: _prescribedMedications,
        existingMedication: _medicationController.text,
        labResults: labs,
        foodHabit: _foodHabit,
        activityType: _activityLevel,
        otherLifestyleHabits: habits,
      );

      await VitalsService().saveVitals(model);
      widget.onVitalsSaved();
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vitals saved!")));
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if(mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: Stack(
        children: [
          Positioned(top: -100, right: -80, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.1), blurRadius: 80, spreadRadius: 30)]))),
          SafeArea(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // 1. Custom Header
                  _buildHeader(),

                  // 2. Tabs
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: TabBar(
                      controller: _tabController,
                      indicatorColor: Theme.of(context).colorScheme.primary,
                      labelColor: Theme.of(context).colorScheme.primary,
                      unselectedLabelColor: Colors.grey,
                      tabs: const [
                        Tab(text: "Body & Labs", icon: Icon(Icons.monitor_weight_outlined)),
                        Tab(text: "Clinical Profile", icon: Icon(Icons.medical_services_outlined)),
                      ],
                    ),
                  ),

                  // 3. Content
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        BodyVitalsSection(
                          weightController: _weightController, heightController: _heightController, waistController: _waistController, hipController: _hipController, fatController: _fatController, bpSysController: _bpSysController, bpDiaController: _bpDiaController, hrController: _hrController, spo2Controller: _spo2Controller, labControllers: _labControllers, foodHabit: _foodHabit, onFoodHabitChanged: (v) => setState(() => _foodHabit = v), activityLevel: _activityLevel, onActivityLevelChanged: (v) => setState(() => _activityLevel = v), smoking: _smoking, onSmokingChanged: (v) => setState(() => _smoking = v), smokingFreqController: _smokingCtrl, alcohol: _alcohol, onAlcoholChanged: (v) => setState(() => _alcohol = v), alcoholFreqController: _alcoholCtrl,
                        ),
                        ClinicalProfileSection(
                          selectedDiagnosisIds: _selectedDiagnosisIds,
                          medicalHistoryWithDuration: _medicalHistory,
                          selectedComplaints: _selectedComplaints,
                          selectedAllergies: _selectedAllergies,
                          prescribedMedications: _prescribedMedications,
                          medicationController: _medicationController,
                          onMedicationsChanged: (l) => setState(() => _prescribedMedications = l),
                          onDiagnosesChanged: (l) => setState(() => _selectedDiagnosisIds = l),
                          onHistoryChanged: (m) => setState(() => _medicalHistory = m),
                          onAddComplaint: (v) => setState(() => _selectedComplaints.add(v)),
                          onRemoveComplaint: (v) => setState(() => _selectedComplaints.remove(v)),
                          onAddAllergy: (v) => setState(() => _selectedAllergies.add(v)),
                          onRemoveAllergy: (v) => setState(() => _selectedAllergies.remove(v)),
                          onComplaintsListChanged: (l) => setState(() => _selectedComplaints = l),
                          onAllergiesListChanged: (l) => setState(() => _selectedAllergies = l),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1)))),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(onTap: () => Navigator.pop(context), child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]), child: const Icon(Icons.arrow_back, size: 20))),
                  const Text("Client Intake Form", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(onPressed: _isSaving ? null : _save, icon: _isSaving ? const CircularProgressIndicator() : Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary, size: 28))
                ],
              ),
              const SizedBox(height: 10),
              InkWell(
                onTap: () async {
                  final d = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2020), lastDate: DateTime.now());
                  if(d != null) setState(() => _selectedDate = d);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(.1), borderRadius: BorderRadius.circular(8)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.calendar_today, size: 16, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(DateFormat('dd MMM yyyy').format(_selectedDate), style:  TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary))
                  ]),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}