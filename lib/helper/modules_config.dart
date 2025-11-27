import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:nutricare_client_management/meal_planner/screen/disease_history_entry.dart';
import 'package:nutricare_client_management/meal_planner/screen/disease_master_model.dart';
import 'package:nutricare_client_management/meal_planner/screen/disease_master_service.dart';

// 🎯 ENSURE THESE IMPORTS ARE CORRECT FOR YOUR PROJECT
import 'package:nutricare_client_management/modules/client/model/vitals_model.dart';
import 'package:nutricare_client_management/modules/client/services/vitals_service.dart';
import 'package:nutricare_client_management/admin/custom_gradient_app_bar.dart';


// --- STUB: Lab Vitals Data (If you don't have the core file) ---
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
    'hdl_cholesterol': LabTest(displayName: 'HDL Cholesterol', unit: 'mg/dL', category: 'Lipid Profile', referenceRange: '> 40'),
    'ldl_cholesterol': LabTest(displayName: 'LDL Cholesterol', unit: 'mg/dL', category: 'Lipid Profile', referenceRange: '< 100'),
    'triglycerides': LabTest(displayName: 'Triglycerides', unit: 'mg/dL', category: 'Lipid Profile', referenceRange: '< 150'),
    'tsh': LabTest(displayName: 'TSH', unit: 'mIU/L', category: 'Thyroid', referenceRange: '0.4 - 4.0'),
  };
}

// --- MAIN SCREEN ---
class VitalsEntryPage extends StatefulWidget {
  final String clientId;
  final String clientName;
  final VitalsModel? vitalsToEdit;

  // 🎯 REQUIRED PARAMETER: This is what was missing/causing the error
  final VoidCallback onVitalsSaved;

  // 🎯 REQUIRED PARAMETER: For baseline/progress distinction
  final bool isFirstConsultation;

  const VitalsEntryPage({
    super.key,
    required this.clientId,
    required this.clientName,
    this.vitalsToEdit,
    required this.onVitalsSaved, // Ensure this is required
    required this.isFirstConsultation,
  });

  @override
  State<VitalsEntryPage> createState() => _VitalsEntryPageState();
}

class _VitalsEntryPageState extends State<VitalsEntryPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;

  final DiseaseMasterService _diseaseService = DiseaseMasterService();
  late Future<List<DiseaseMasterModel>> _diseaseMasterFuture;

  // Controllers
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _notesController = TextEditingController();
  final _waistController = TextEditingController();
  final _hipController = TextEditingController();
  final _chestController = TextEditingController();

  // Clinical Controllers
  final TextEditingController _complaintsController = TextEditingController();
  final TextEditingController _medicationController = TextEditingController();
  final TextEditingController _allergiesController = TextEditingController();
  final TextEditingController _restrictedDietController = TextEditingController();

  final Map<String, TextEditingController> _labControllers = {};

  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  double _bmi = 0.0;
  double _idealBodyWeightKg = 0.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _diseaseMasterFuture = _diseaseService.getActiveDiseasesList();

    // Init Lab Controllers
    for (var key in LabVitalsData.allLabTests.keys) {
      _labControllers[key] = TextEditingController();
    }

    _heightController.addListener(_calculateVitals);
    _weightController.addListener(_calculateVitals);

    if (widget.vitalsToEdit != null) {
      _initializeForEdit(widget.vitalsToEdit!);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _notesController.dispose();
    _waistController.dispose();
    _hipController.dispose();
    _chestController.dispose();
    _complaintsController.dispose();
    _medicationController.dispose();
    _allergiesController.dispose();
    _restrictedDietController.dispose();
    for (var c in _labControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _initializeForEdit(VitalsModel vitals) {
    _selectedDate = vitals.date;
    _heightController.text = vitals.heightCm.toStringAsFixed(1);
    _weightController.text = vitals.weightKg.toStringAsFixed(1);
    _notesController.text = vitals.notes ?? '';

    if(vitals.measurements.containsKey('waist')) _waistController.text = vitals.measurements['waist'].toString();
    if(vitals.measurements.containsKey('hip')) _hipController.text = vitals.measurements['hip'].toString();

    vitals.labResults.forEach((key, value) {
      if(_labControllers.containsKey(key)) _labControllers[key]!.text = value;
    });

    _complaintsController.text = vitals.complaints ?? '';
    _medicationController.text = vitals.existingMedication ?? '';
    _allergiesController.text = vitals.foodAllergies ?? '';
    _restrictedDietController.text = vitals.restrictedDiet ?? '';

    _calculateVitals();
  }

  void _calculateVitals() {
    final h = double.tryParse(_heightController.text) ?? 0;
    final w = double.tryParse(_weightController.text) ?? 0;
    if (h > 0 && w > 0) {
      setState(() {
        _bmi = w / ((h / 100) * (h / 100));
        // Simple IBW logic
        _idealBodyWeightKg = 22 * ((h / 100) * (h / 100));
      });
    }
  }

  void _saveForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final Map<String, double> measurements = {};
    if(_waistController.text.isNotEmpty) measurements['waist'] = double.parse(_waistController.text);
    if(_hipController.text.isNotEmpty) measurements['hip'] = double.parse(_hipController.text);
    if(_chestController.text.isNotEmpty) measurements['chest'] = double.parse(_chestController.text);

    final Map<String, String> labs = {};
    _labControllers.forEach((key, ctrl) {
      if(ctrl.text.isNotEmpty) labs[key] = ctrl.text;
    });

    final VitalsModel newVitals = VitalsModel(
      id: widget.vitalsToEdit?.id ?? '',
      clientId: widget.clientId,
      date: _selectedDate,
      heightCm: double.tryParse(_heightController.text) ?? 0,
      weightKg: double.tryParse(_weightController.text) ?? 0,
      bmi: _bmi,
      idealBodyWeightKg: _idealBodyWeightKg,
      bodyFatPercentage: 0, // Can add controller if needed
      measurements: measurements,
      labResults: labs,
      notes: _notesController.text,
      complaints: _complaintsController.text,
      existingMedication: _medicationController.text,
      foodAllergies: _allergiesController.text,
      restrictedDiet: _restrictedDietController.text,
      isFirstConsultation: widget.isFirstConsultation,
    );

    try {
      if (widget.vitalsToEdit?.id != null) {
        await VitalsService().saveVitals(newVitals);
      }

      // 🎯 CRITICAL: Call the callback so the previous screen knows to refresh
      widget.onVitalsSaved();

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomGradientAppBar(
        title: const Text("Vitals Entry"),
        actions: [
          IconButton(
            icon: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveForm,
          )
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.monitor_weight), text: 'Metrics'),
            Tab(icon: Icon(Icons.medical_services), text: 'Clinical'),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildMetricsTab(),
            _buildClinicalTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextFormField(
            controller: _heightController,
            decoration: const InputDecoration(labelText: "Height (cm)", border: OutlineInputBorder()),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _weightController,
            decoration: const InputDecoration(labelText: "Weight (kg)", border: OutlineInputBorder()),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text("BMI: ${_bmi.toStringAsFixed(1)}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text("IBW: ${_idealBodyWeightKg.toStringAsFixed(1)} kg", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(height: 30),
          const Text("Lab Results", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ..._labControllers.keys.map((key) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TextFormField(
              controller: _labControllers[key],
              decoration: InputDecoration(labelText: LabVitalsData.allLabTests[key]?.displayName ?? key, border: const OutlineInputBorder()),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildClinicalTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextFormField(controller: _complaintsController, decoration: const InputDecoration(labelText: "Complaints", border: OutlineInputBorder()), maxLines: 2),
          const SizedBox(height: 16),
          TextFormField(controller: _medicationController, decoration: const InputDecoration(labelText: "Medications", border: OutlineInputBorder()), maxLines: 2),
          const SizedBox(height: 16),
          TextFormField(controller: _allergiesController, decoration: const InputDecoration(labelText: "Allergies", border: OutlineInputBorder())),
          const SizedBox(height: 16),
          TextFormField(controller: _restrictedDietController, decoration: const InputDecoration(labelText: "Diet Restrictions", border: OutlineInputBorder())),
          const SizedBox(height: 16),
          TextFormField(controller: _notesController, decoration: const InputDecoration(labelText: "Notes", border: OutlineInputBorder()), maxLines: 3),
        ],
      ),
    );
  }
}