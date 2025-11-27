import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nutricare_client_management/admin/custom_gradient_app_bar.dart'; // Or generic header if unavailable
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

  // --- STATE: Clinical Profile ---
  List<String> _selectedDiagnosisIds = []; // Storing IDs (or Names if simple strings)
  Map<String, String> _medicalHistory = {}; // Key: Disease Name, Value: Duration
  List<String> _selectedComplaints = [];
  List<String> _selectedAllergies = [];
  List<PrescribedMedication> _prescribedMedications = [];
  final _medicationController = TextEditingController(); // For legacy/unstructured notes

  // --- STATE: Body & Lifestyle ---
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _waistController = TextEditingController();
  final _hipController = TextEditingController();
  final _fatController = TextEditingController();

  final _bpSysController = TextEditingController();
  final _bpDiaController = TextEditingController();
  final _hrController = TextEditingController();
  final _spo2Controller = TextEditingController();

  // Labs (Dynamic based on LabVitalsData keys)
  final Map<String, TextEditingController> _labControllers = {};

  // Lifestyle
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

    // Initialize controllers for ALL lab tests defined in configuration
    for(var key in LabVitalsData.allLabTests.keys) {
      _labControllers[key] = TextEditingController();
    }

    if (widget.vitalsToEdit != null) {
      _populateData(widget.vitalsToEdit!);
    }
  }

  void _populateData(VitalsModel data) {
    _selectedDate = data.date;

    // --- Populate Clinical Data ---
    _selectedDiagnosisIds = List.from(data.diagnosis);

    // History Logic: Parse "Diabetes: 5yrs, HTN: 2yrs" format if duration map missing
    if (data.medicalHistoryDurations != null && data.medicalHistoryDurations!.isNotEmpty) {
      final entries = data.medicalHistoryDurations!.split(', ');
      for(var e in entries) {
        final parts = e.split(':');
        if(parts.length > 1) {
          _medicalHistory[parts[0].trim()] = parts[1].trim();
        } else {
          _medicalHistory[e.trim()] = "";
        }
      }
    } else {
      // Fallback for older data format
      for(var h in data.medicalHistory) {
        _medicalHistory[h] = "";
      }
    }

    // Parse Comma Separated Lists or use direct lists if model updated
    _selectedComplaints = (data.complaints?.split(',') ?? [])
        .where((s) => s.trim().isNotEmpty)
        .map((e) => e.trim())
        .toList();

    _selectedAllergies = (data.foodAllergies?.split(',') ?? [])
        .where((s) => s.trim().isNotEmpty)
        .map((e) => e.trim())
        .toList();

    // Medications (New List Structure)
    _prescribedMedications = List.from(data.prescribedMedications);

    // Fallback for legacy medication string if list is empty
    if (_prescribedMedications.isEmpty && data.existingMedication != null && data.existingMedication!.isNotEmpty) {
      // Optional: logic to parse string "Dolo (1-0-1)" into objects,
      // for now we just put it in the legacy text field
      _medicationController.text = data.existingMedication!;
    }

    // --- Populate Body Data ---
    if(data.weightKg > 0) _weightController.text = data.weightKg.toString();
    if(data.heightCm > 0) _heightController.text = data.heightCm.toString();
    if(data.waistCm != null) _waistController.text = data.waistCm.toString();
    if(data.hipCm != null) _hipController.text = data.hipCm.toString();
    if(data.bodyFatPercentage > 0) _fatController.text = data.bodyFatPercentage.toString();

    if(data.bloodPressureSystolic != null) _bpSysController.text = data.bloodPressureSystolic.toString();
    if(data.bloodPressureDiastolic != null) _bpDiaController.text = data.bloodPressureDiastolic.toString();
    if(data.heartRate != null) _hrController.text = data.heartRate.toString();
    if(data.spO2Percentage != null) _spo2Controller.text = data.spO2Percentage.toString();

    // Populate Labs
    data.labResults.forEach((k, v) {
      if(_labControllers.containsKey(k)) {
        _labControllers[k]!.text = v;
      }
    });

    // --- Populate Lifestyle ---
    _foodHabit = data.foodHabit;
    _activityLevel = data.activityType;
    if(data.otherLifestyleHabits?.containsKey('Smoking') ?? false) {
      _smoking = true;
      _smokingCtrl.text = data.otherLifestyleHabits!['Smoking']!;
    }
    if(data.otherLifestyleHabits?.containsKey('Alcohol') ?? false) {
      _alcohol = true;
      _alcoholCtrl.text = data.otherLifestyleHabits!['Alcohol']!;
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
    for(var c in _labControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please correct invalid fields before saving."))
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // 1. Calculations & Conversions
      double h = double.tryParse(_heightController.text) ?? 0;
      double w = double.tryParse(_weightController.text) ?? 0;
      double bmi = (h > 0 && w > 0) ? w / ((h/100)*(h/100)) : 0;
      double ibw = (h > 0) ? 22 * ((h/100)*(h/100)) : 0; // Simple IBW logic

      // 2. Format Data for Storage
      // Convert Map back to string for legacy support or display purposes
      String historyStr = _medicalHistory.entries.map((e) => "${e.key}:${e.value}").join(", ");

      // Lab Results Map
      Map<String, String> labs = {};
      _labControllers.forEach((k, v) {
        if(v.text.trim().isNotEmpty) labs[k] = v.text.trim();
      });

      // Lifestyle Map
      Map<String, String> habits = {};
      if(_smoking) habits['Smoking'] = _smokingCtrl.text;
      if(_alcohol) habits['Alcohol'] = _alcoholCtrl.text;

      // 3. Create Model
      final model = VitalsModel(
        id: widget.vitalsToEdit?.id ?? '',
        clientId: widget.clientId,
        date: _selectedDate,
        isFirstConsultation: widget.isFirstConsultation,

        // Anthro
        heightCm: h,
        weightKg: w,
        bmi: bmi,
        idealBodyWeightKg: ibw,
        bodyFatPercentage: double.tryParse(_fatController.text) ?? 0,
        waistCm: double.tryParse(_waistController.text),
        hipCm: double.tryParse(_hipController.text),
        measurements: {}, // Deprecated or extra measurements

        // Vitals
        bloodPressureSystolic: int.tryParse(_bpSysController.text),
        bloodPressureDiastolic: int.tryParse(_bpDiaController.text),
        heartRate: int.tryParse(_hrController.text),
        spO2Percentage: double.tryParse(_spo2Controller.text),

        // Clinical Profile
        diagnosis: _selectedDiagnosisIds,
        medicalHistory: _medicalHistory.keys.toList(),
        medicalHistoryDurations: historyStr,
        complaints: _selectedComplaints.join(", "),
        foodAllergies: _selectedAllergies.join(", "),

        prescribedMedications: _prescribedMedications, // 🎯 NEW LIST
        existingMedication: _medicationController.text, // Legacy notes

        // Lab & Lifestyle
        labResults: labs,
        foodHabit: _foodHabit,
        activityType: _activityLevel,
        otherLifestyleHabits: habits,
      );

      // 4. Save to Service
      await VitalsService().saveVitals(model);

      // 5. Notify & Return
      widget.onVitalsSaved();
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vitals saved successfully!"), backgroundColor: Colors.green));
        Navigator.pop(context);
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error saving vitals: $e"), backgroundColor: Colors.red));
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
          // Ambient Background Glow
          Positioned(
            top: -100,
            right: -80,
            child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.indigo.withOpacity(0.1), blurRadius: 80, spreadRadius: 30)
                    ]
                )
            ),
          ),

          SafeArea(
            child: Form(
              key: _formKey,
              child: Column(
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
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]
                            ),
                            child: const Icon(Icons.arrow_back, size: 20, color: Colors.black87),
                          ),
                        ),
                        const Text(
                            "Client Intake Form",
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))
                        ),
                        // Save Button
                        ElevatedButton.icon(
                          onPressed: _isSaving ? null : _save,
                          icon: _isSaving
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.check, size: 18),
                          label: const Text("SAVE"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 2. Date Picker
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200)
                    ),
                    child: ListTile(
                      dense: true,
                      title: Text(
                          "Consultation Date: ${DateFormat('dd MMM yyyy').format(_selectedDate)}",
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)
                      ),
                      trailing: const Icon(Icons.calendar_today, color: Colors.indigo, size: 20),
                      onTap: () async {
                        final d = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now()
                        );
                        if(d != null) setState(() => _selectedDate = d);
                      },
                    ),
                  ),

                  // 3. Tabs
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5)],
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                          color: Colors.indigo.shade50,
                          borderRadius: BorderRadius.circular(12)
                      ),
                      labelColor: Colors.indigo,
                      unselectedLabelColor: Colors.grey,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      tabs: const [
                        Tab(text: "Body & Labs", icon: Icon(Icons.science_outlined)),
                        Tab(text: "Clinical Profile", icon: Icon(Icons.medical_services_outlined)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // 4. Content Views
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // TAB 1: Body Vitals
                        BodyVitalsSection(
                          weightController: _weightController,
                          heightController: _heightController,
                          waistController: _waistController,
                          hipController: _hipController,
                          fatController: _fatController,
                          bpSysController: _bpSysController,
                          bpDiaController: _bpDiaController,
                          hrController: _hrController,
                          spo2Controller: _spo2Controller,
                          labControllers: _labControllers,

                          foodHabit: _foodHabit,
                          onFoodHabitChanged: (v) => setState(() => _foodHabit = v),
                          activityLevel: _activityLevel,
                          onActivityLevelChanged: (v) => setState(() => _activityLevel = v),
                          smoking: _smoking,
                          onSmokingChanged: (v) => setState(() => _smoking = v),
                          smokingFreqController: _smokingCtrl,
                          alcohol: _alcohol,
                          onAlcoholChanged: (v) => setState(() => _alcohol = v),
                          alcoholFreqController: _alcoholCtrl,
                        ),

                        // TAB 2: Clinical Profile
                        ClinicalProfileSection(
                          selectedDiagnosisIds: _selectedDiagnosisIds,
                          medicalHistoryWithDuration: _medicalHistory,
                          selectedComplaints: _selectedComplaints,
                          selectedAllergies: _selectedAllergies,

                          // Medication
                          prescribedMedications: _prescribedMedications,
                          medicationController: _medicationController,
                          onMedicationsChanged: (list) => setState(() => _prescribedMedications = list),

                          // Callbacks
                          onDiagnosesChanged: (list) => setState(() => _selectedDiagnosisIds = list),
                          onHistoryChanged: (map) => setState(() => _medicalHistory = map),

                          // Individual Add/Remove (if using chips directly)
                          onAddComplaint: (v) => setState(() => _selectedComplaints.add(v)),
                          onRemoveComplaint: (v) => setState(() => _selectedComplaints.remove(v)),
                          onAddAllergy: (v) => setState(() => _selectedAllergies.add(v)),
                          onRemoveAllergy: (v) => setState(() => _selectedAllergies.remove(v)),

                          // 🎯 BULK UPDATES from Multi-Select Dialog
                          onComplaintsListChanged: (list) => setState(() => _selectedComplaints = list),
                          onAllergiesListChanged: (list) => setState(() => _selectedAllergies = list),
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
}