import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:nutricare_client_management/meal_planner/screen/disease_history_entry.dart';
import 'package:nutricare_client_management/meal_planner/screen/disease_master_model.dart';
import 'package:nutricare_client_management/meal_planner/screen/disease_master_service.dart';

// 🎯 ADJUST THESE IMPORTS TO YOUR PROJECT STRUCTURE
import 'package:nutricare_client_management/modules/client/model/vitals_model.dart';
import 'package:nutricare_client_management/modules/client/services/vitals_service.dart';


// ----------------------------------------------------------------------
// --- STUB DEFINITIONS (Necessary Helpers) ---
// ----------------------------------------------------------------------

// 1. LabTest class with referenceRange (UNCHANGED)
class LabTest {
  final String displayName;
  final String unit;
  final String category;
  final String referenceRange;

  const LabTest({
    required this.displayName,
    required this.unit,
    required this.category,
    required this.referenceRange,
  });
}

// 2. EXPANDED LAB VITAL DATA (UNCHANGED)
class LabVitalsData {
  static const Map<String, LabTest> allLabTests = {
    // --- BLOOD SUGAR / DIABETES PROFILE ---
    'fasting_glucose': LabTest(
      displayName: 'Fasting Glucose',
      unit: 'mg/dL',
      category: 'Blood Sugar',
      referenceRange: '< 100',
    ),
    'pp_glucose': LabTest(
      displayName: 'Postprandial Glucose',
      unit: 'mg/dL',
      category: 'Blood Sugar',
      referenceRange: '< 140',
    ),
    'hba1c': LabTest(
      displayName: 'HbA1c',
      unit: '%',
      category: 'Blood Sugar',
      referenceRange: '4.0 - 5.6',
    ),

    // --- LIPID PROFILE ---
    'total_cholesterol': LabTest(
      displayName: 'Total Cholesterol',
      unit: 'mg/dL',
      category: 'Lipid Profile',
      referenceRange: '< 200',
    ),
    'hdl_cholesterol': LabTest(
      displayName: 'HDL Cholesterol',
      unit: 'mg/dL',
      category: 'Lipid Profile',
      referenceRange: '> 40',
    ),
    'ldl_cholesterol': LabTest(
      displayName: 'LDL Cholesterol',
      unit: 'mg/dL',
      category: 'Lipid Profile',
      referenceRange: '< 100',
    ),
    'triglycerides': LabTest(
      displayName: 'Triglycerides',
      unit: 'mg/dL',
      category: 'Lipid Profile',
      referenceRange: '< 150',
    ),

    // --- LIVER FUNCTION TEST (LFT) ---
    'sgpt_alt': LabTest(
      displayName: 'SGPT/ALT',
      unit: 'U/L',
      category: 'Liver Profile',
      referenceRange: '< 45',
    ),
    'sgot_ast': LabTest(
      displayName: 'SGOT/AST',
      unit: 'U/L',
      category: 'Liver Profile',
      referenceRange: '< 35',
    ),
    'total_bilirubin': LabTest(
      displayName: 'Total Bilirubin',
      unit: 'mg/dL',
      category: 'Liver Profile',
      referenceRange: '0.3 - 1.2',
    ),

    // --- KIDNEY FUNCTION TEST (KFT) ---
    'serum_creatinine': LabTest(
      displayName: 'Serum Creatinine',
      unit: 'mg/dL',
      category: 'Kidney Profile',
      referenceRange: '0.6 - 1.2',
    ),
    'bun': LabTest(
      displayName: 'BUN (Urea)',
      unit: 'mg/dL',
      category: 'Kidney Profile',
      referenceRange: '7 - 20',
    ),

    // --- THYROID PROFILE ---
    'tsh': LabTest(
      displayName: 'TSH',
      unit: 'mIU/L',
      category: 'Thyroid',
      referenceRange: '0.4 - 4.0',
    ),
    'free_t3': LabTest(
      displayName: 'Free T3',
      unit: 'pg/mL',
      category: 'Thyroid',
      referenceRange: '2.0 - 4.4',
    ),
    'free_t4': LabTest(
      displayName: 'Free T4',
      unit: 'ng/dL',
      category: 'Thyroid',
      referenceRange: '0.8 - 1.8',
    ),

    // --- VITAMINS, MINERALS & OTHERS ---
    'vitamin_d': LabTest(
      displayName: 'Vitamin D (25-OH)',
      unit: 'ng/mL',
      category: 'Vitamins & Minerals',
      referenceRange: '30 - 100',
    ),
    'ferritin': LabTest(
      displayName: 'Ferritin',
      unit: 'ng/mL',
      category: 'Vitamins & Minerals',
      referenceRange: '15 - 150 (F) | 20 - 250 (M)',
    ),
    'serum_iron': LabTest(
      displayName: 'Serum Iron',
      unit: 'µg/dL',
      category: 'Vitamins & Minerals',
      referenceRange: '60 - 170',
    ),
    'uric_acid': LabTest(
      displayName: 'Uric Acid',
      unit: 'mg/dL',
      category: 'Vitamins & Minerals',
      referenceRange: '2.4 - 6.0 (F) | 3.4 - 7.0 (M)',
    ),
    'crp': LabTest(
      displayName: 'C-Reactive Protein (CRP)',
      unit: 'mg/L',
      category: 'Inflammation',
      referenceRange: '< 1.0',
    ),

    // --- ELECTROLYTES ---
    'sodium': LabTest(
      displayName: 'Sodium (Na+)',
      unit: 'mmol/L',
      category: 'Electrolytes',
      referenceRange: '135 - 145',
    ),
    'potassium': LabTest(
      displayName: 'Potassium (K+)',
      unit: 'mmol/L',
      category: 'Electrolytes',
      referenceRange: '3.5 - 5.1',
    ),
  };

  static List<String> get labCategories =>
      allLabTests.values.map((v) => v.category).toSet().toList();
}

// ----------------------------------------------------------------------
final List<String> _foodHabits = ['Non-Vegetarian', 'Vegetarian', 'Eggetarian', 'Vegan'];
final List<String> _activityTypes = [
  'Sedentary (Little to no exercise)',
  'Light (1-3 days/week)',
  'Moderate (3-5 days/week)',
  'Active (6-7 days/week)',
  'Very Active (Intense daily)'
];
final List<String> _drinkingOptions = ['No', 'Socially/Occasional', 'Weekly', 'Daily'];
final List<String> _smokingOptions = ['No', 'Occasionally', 'Daily (Few)', 'Daily (Heavy)'];

// ----------------------------------------------------------------------

class DiseaseHistoryEntry {
  final String diseaseId;
  final String diseaseName;
  final String duration;

  const DiseaseHistoryEntry({
    required this.diseaseId,
    required this.diseaseName,
    required this.duration,
  });

  DiseaseHistoryEntry copyWith({
    String? diseaseId,
    String? diseaseName,
    String? duration,
  }) {
    return DiseaseHistoryEntry(
      diseaseId: diseaseId ?? this.diseaseId,
      diseaseName: diseaseName ?? this.diseaseName,
      duration: duration ?? this.duration,
    );
  }
}
class VitalsEntryPage extends StatefulWidget {
  final String clientId;
  final String clientName;
  final VitalsModel? vitalsToEdit;
  final VoidCallback onVitalsSaved;
  final bool isFirstConsultation;

  const VitalsEntryPage({
    super.key,
    required this.clientId,
    required this.clientName,
    this.vitalsToEdit,
    required this.onVitalsSaved,
    required this.isFirstConsultation
  });

  @override
  State<VitalsEntryPage> createState() => _VitalsEntryPageState();
}

class _VitalsEntryPageState extends State<VitalsEntryPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;

  // 🎯 Master Data Service and Future
  final DiseaseMasterService _diseaseService = DiseaseMasterService();
  late Future<List<DiseaseMasterModel>> _diseaseMasterFuture;

  // 🎯 NEW: Store fetched master list and current dropdown selection
  List<DiseaseMasterModel> _availableDiseases = [];
  String? _currentSelectedDiseaseName;

  // --- EXISTING CONTROLLERS ---
  final _heightController = TextEditingController();
  final _heightFeetController = TextEditingController();
  final _heightInchesController = TextEditingController();
  String _heightUnit = 'cm';
  final _weightController = TextEditingController();
  final _bfpController = TextEditingController();
  final _notesController = TextEditingController();

  // Measurement Controllers
  final _waistController = TextEditingController();
  final _hipController = TextEditingController();
  final _chestController = TextEditingController();

  // Lab Controllers
  final Map<String, TextEditingController> _labControllers = Map.fromIterable(
    LabVitalsData.allLabTests.keys,
    key: (key) => key,
    value: (_) => TextEditingController(),
  );

  // Lifestyle Habits
  String? _foodHabit;
  String? _activityType;
  String? _drinkingStatus;
  final _drinkingLimitController = TextEditingController();
  String? _smokingStatus;
  final _smokingLimitController = TextEditingController();
  final _otherHabitsController = TextEditingController();

  // 🎯 CLINICAL CONTROLLERS
  final TextEditingController _complaintsController = TextEditingController();
  final TextEditingController _medicationController = TextEditingController();
  final TextEditingController _allergiesController = TextEditingController();
  final TextEditingController _restrictedDietController = TextEditingController();

  // Medical History State
  final Map<String, TextEditingController> _historyDurationControllers = {};
  List<DiseaseHistoryEntry> _diseaseHistory = [];
  // --------------------------------------

  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  double _bmi = 0.0;
  double _idealBodyWeightKg = 0.0;

  VitalsService vitalsService = VitalsService();
  bool _isMeasurementsExpanded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // 🎯 INITIALIZE FUTURE TO FETCH DISEASE MASTER DATA
    _diseaseMasterFuture = _diseaseService.getActiveDiseasesList();

    // Listeners for Vitals calculation
    _heightController.addListener(_calculateVitals);
    _heightFeetController.addListener(_handleFeetInchChange);
    _heightInchesController.addListener(_handleFeetInchChange);
    _weightController.addListener(_calculateVitals);

    // 🎯 UPDATED: Initialize history state for editing based on the saved string.
    if (widget.vitalsToEdit != null) {
      if (widget.vitalsToEdit!.medicalHistoryDurations != null) {
        final historyStrings = widget.vitalsToEdit!.medicalHistoryDurations!.split(',');
        _diseaseHistory = historyStrings
            .where((s) => s.contains(':'))
            .map((s) {
          final parts = s.split(':');
          final diseaseName = parts[0].trim();
          final duration = parts[1].trim();

          final controller = TextEditingController(text: duration);
          _historyDurationControllers[diseaseName] = controller;

          // Attach listener to loaded controllers
          controller.addListener(() {
            _updateHistoryDuration(diseaseName, controller.text.trim());
          });

          return DiseaseHistoryEntry(
            diseaseName: diseaseName,
            duration: duration,
            // In a real app, you'd map the name back to an ID if needed
            diseaseId: diseaseName,
          );
        }).toList();
      }

      _initializeForEdit(widget.vitalsToEdit!);
    } else {
      _calculateVitals();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _heightController.removeListener(_calculateVitals);
    _heightFeetController.removeListener(_handleFeetInchChange);
    _heightInchesController.removeListener(_handleFeetInchChange);

    _heightController.dispose();
    _heightFeetController.dispose();
    _heightInchesController.dispose();

    _weightController.removeListener(_calculateVitals);
    _weightController.dispose();
    _bfpController.dispose();

    _complaintsController.dispose();
    _medicationController.dispose();
    _allergiesController.dispose();
    _restrictedDietController.dispose();

    // 🎯 Dispose all history duration controllers
    _historyDurationControllers.values.forEach((controller) => controller.dispose());

    _notesController.dispose();
    _labControllers.values.forEach((controller) => controller.dispose());
    _waistController.dispose();
    _hipController.dispose();
    _chestController.dispose();
    _drinkingLimitController.dispose();
    _smokingLimitController.dispose();
    _otherHabitsController.dispose();

    super.dispose();
  }

  // ----------------------------------------------------------------------
  // --- MEDICAL HISTORY CRUD METHODS ---
  // ----------------------------------------------------------------------

  void _addDiseaseToHistory() {
    if (_currentSelectedDiseaseName != null) {
      final diseaseName = _currentSelectedDiseaseName!;

      // Safety check for duplicates (shouldn't happen with filtered dropdown, but good practice)
      final isAlreadyAdded = _diseaseHistory.any((e) => e.diseaseName == diseaseName);
      if (isAlreadyAdded) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$diseaseName is already added.')),
        );
        return;
      }

      final disease = _availableDiseases.firstWhere(
            (d) => d.enName == diseaseName,
        // Fallback is defensive
        orElse: () => const DiseaseMasterModel(id: '', enName: '', nameLocalized: {}),
      );

      if (disease.id.isNotEmpty) {
        final newEntry = DiseaseHistoryEntry(
          diseaseId: disease.id,
          diseaseName: disease.enName,
          duration: '', // Initialize with empty duration
        );

        // Initialize a new controller and add it to the map
        final newController = TextEditingController();
        _historyDurationControllers[disease.enName] = newController;

        // Add a listener to update the main list when duration changes
        newController.addListener(() {
          _updateHistoryDuration(disease.enName, newController.text.trim());
        });

        setState(() {
          _diseaseHistory.add(newEntry);
          _currentSelectedDiseaseName = null; // Clear dropdown selection
        });
      }
    }
  }

  void _updateHistoryDuration(String diseaseName, String newDuration) {
    final entryIndex = _diseaseHistory.indexWhere((e) => e.diseaseName == diseaseName);
    if (entryIndex != -1) {
      // Update the duration in the list used for saving (using copyWith for immutability)
      _diseaseHistory[entryIndex] = _diseaseHistory[entryIndex].copyWith(duration: newDuration);
    }
  }

  void _removeDiseaseFromHistory(String diseaseName) {
    setState(() {
      _diseaseHistory.removeWhere((e) => e.diseaseName == diseaseName);

      // Dispose and remove controller
      final controller = _historyDurationControllers.remove(diseaseName);
      controller?.dispose();
    });
  }

  // ----------------------------------------------------------------------
  // --- END MEDICAL HISTORY CRUD METHODS ---
  // ----------------------------------------------------------------------


  void _initializeForEdit(VitalsModel vitals) {
    _selectedDate = vitals.date;
    final heightCm = vitals.heightCm;
    _heightController.text = heightCm.toStringAsFixed(1);

    if (heightCm > 0) {
      final totalInches = heightCm / 2.54;
      final feet = (totalInches / 12).floor();
      final inches = totalInches % 12;

      _heightFeetController.text = feet.toString();
      _heightInchesController.text = inches.toStringAsFixed(1);
    }

    _weightController.text = vitals.weightKg.toStringAsFixed(1);
    _bfpController.text = vitals.bodyFatPercentage.toStringAsFixed(1);
    _notesController.text = vitals.notes ?? '';

    _bmi = vitals.bmi;
    _idealBodyWeightKg = vitals.idealBodyWeightKg;

    // Existing Lifestyle
    final storedFoodHabit = vitals.foodHabit;
    if (storedFoodHabit != null && storedFoodHabit.isNotEmpty && _foodHabits.contains(storedFoodHabit)) {
      _foodHabit = storedFoodHabit;
    } else {
      _foodHabit = null;
    }

    final storedActivityType = vitals.activityType;
    if (storedActivityType != null && storedActivityType.isNotEmpty && _activityTypes.contains(storedActivityType)) {
      _activityType = storedActivityType;
    } else {
      _activityType = null;
    }

    // Measurements
    if (vitals.measurements.containsKey('waist')) {
      _waistController.text = vitals.measurements['waist']!.toStringAsFixed(1);
    }
    if (vitals.measurements.containsKey('hip')) {
      _hipController.text = vitals.measurements['hip']!.toStringAsFixed(1);
    }
    if (vitals.measurements.containsKey('chest')) {
      _chestController.text = vitals.measurements['chest']!.toStringAsFixed(1);
    }

    // Lab Results
    LabVitalsData.allLabTests.keys.forEach((key) {
      if (vitals.labResults.containsKey(key)) {
        _labControllers[key]!.text = vitals.labResults[key]!;
      }
    });

    // Lifestyle Habits
    final Map<String, String> habits = vitals.otherLifestyleHabits ?? {};
    _drinkingStatus = habits['drinkingStatus'];
    _drinkingLimitController.text = habits['drinkingLimit'] ?? '';
    _smokingStatus = habits['smokingStatus'];
    _smokingLimitController.text = habits['smokingLimit'] ?? '';
    _otherHabitsController.text = habits['otherHabits'] ?? '';

    // CLINICAL FIELDS INITIALIZATION
    _complaintsController.text = vitals.complaints ?? '';
    _medicationController.text = vitals.existingMedication ?? '';
    _allergiesController.text = vitals.foodAllergies ?? '';
    _restrictedDietController.text = vitals.restrictedDiet ?? '';
  }

  void _handleFeetInchChange() {
    if (!mounted || _heightUnit != 'ft/in') {
      return;
    }

    final feet = double.tryParse(_heightFeetController.text) ?? 0.0;
    final inches = double.tryParse(_heightInchesController.text) ?? 0.0;

    double heightCm = 0.0;
    if (feet > 0 || inches > 0) {
      final totalInches = (feet * 12) + inches;
      heightCm = totalInches * 2.54;
    }

    if (_heightController.text != heightCm.toString()) {
      _heightController.text = heightCm.toString();
      _calculateVitals();
    }
  }

  void _calculateVitals() {
    if (!mounted) return;

    final heightCm = double.tryParse(_heightController.text) ?? 0.0;
    final weightKg = double.tryParse(_weightController.text) ?? 0.0;

    double newBmi = 0.0;
    double newIbw = 0.0;

    if (heightCm > 0 && weightKg > 0) {
      final heightMeters = heightCm / 100;
      newBmi = weightKg / (heightMeters * heightMeters);

      final heightInches = heightCm / 2.54;
      final inchesOver5Feet = heightInches - 60;

      if (inchesOver5Feet > 0) {
        newIbw = 50.0 + (2.3 * inchesOver5Feet);
      } else {
        newIbw = 50.0;
      }
    }

    if (_bmi.toStringAsFixed(1) != newBmi.toStringAsFixed(1) ||
        _idealBodyWeightKg.toStringAsFixed(1) != newIbw.toStringAsFixed(1)) {
      setState(() {
        _bmi = newBmi;
        _idealBodyWeightKg = newIbw;
      });
    }
  }

  // --- GETTERS ---

  Map<String, double> _getMeasurements() {
    final results = <String, double>{};
    void addMeasurement(String key, TextEditingController controller) {
      final value = double.tryParse(controller.text.trim());
      if (value != null && value > 0) {
        results[key] = value;
      }
    }
    addMeasurement('waist', _waistController);
    addMeasurement('hip', _hipController);
    addMeasurement('chest', _chestController);
    return results;
  }

  Map<String, String> _getLabResults() {
    final results = <String, String>{};
    _labControllers.forEach((key, controller) {
      if (controller.text.isNotEmpty) {
        results[key] = controller.text.trim();
      }
    });
    return results;
  }

  Map<String, String> _getLifestyleHabits() {
    final habits = <String, String>{};
    habits['drinkingStatus'] = _drinkingStatus ?? '';
    if (_drinkingStatus != 'No' && _drinkingStatus != null) {
      habits['drinkingLimit'] = _drinkingLimitController.text.trim();
    } else {
      habits['drinkingLimit'] = '';
    }
    habits['smokingStatus'] = _smokingStatus ?? '';
    if (_smokingStatus != 'No' && _smokingStatus != null) {
      habits['smokingLimit'] = _smokingLimitController.text.trim();
    } else {
      habits['smokingLimit'] = '';
    }
    habits['otherHabits'] = _otherHabitsController.text.trim();
    return habits;
  }


  void _saveForm() async {
    if (!_formKey.currentState!.validate()) {
      _tabController.animateTo(0);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    _calculateVitals();
    final vitalsId = widget.vitalsToEdit?.id ?? '';

    // 🎯 CREATE THE SAVING STRING FROM THE FINAL STATE LIST
    final medicalHistoryString = _diseaseHistory
        .map((e) => '${e.diseaseName}:${e.duration}')
        .join(',');

    final VitalsModel newVitals = VitalsModel(
      id: vitalsId,
      clientId: widget.clientId,
      date: _selectedDate,
      heightCm: double.tryParse(_heightController.text) ?? 0.0,
      bmi: _bmi,
      idealBodyWeightKg: _idealBodyWeightKg,
      weightKg: double.tryParse(_weightController.text) ?? 0.0,
      bodyFatPercentage: double.tryParse(_bfpController.text) ?? 0.0,
      measurements: _getMeasurements(),
      labResults: _getLabResults(),
      notes: _notesController.text.isEmpty
          ? null
          : _notesController.text.trim(),
      labReportUrls: widget.vitalsToEdit?.labReportUrls ?? [],
      foodHabit: _foodHabit,
      activityType: _activityType,
      otherLifestyleHabits: _getLifestyleHabits(),

      // CAPTURE NEW CLINICAL FIELDS
      complaints: _complaintsController.text.trim(),
      existingMedication: _medicationController.text.trim(),
      foodAllergies: _allergiesController.text.trim(),
      restrictedDiet: _restrictedDietController.text.trim(),
      medicalHistoryDurations: medicalHistoryString, isFirstConsultation:widget.isFirstConsultation ,
    );

    try {
      if (widget.vitalsToEdit?.id != null) {
        await vitalsService.updateVitals(newVitals);
      } else {
        await vitalsService.addVitals(newVitals);
      }
      widget.onVitalsSaved();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save vitals: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  // ----------------------------------------------------------------------
  // --- BUILDER METHODS ---
  // ----------------------------------------------------------------------

  Widget _buildMedicalHistorySelector() {
    // 🎯 USE FUTUREBUILDER TO LOAD MASTER DATA
    return FutureBuilder<List<DiseaseMasterModel>>(
      future: _diseaseMasterFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(),
          ));
        }
        if (snapshot.hasError) {
          return Center(child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Error loading diseases: ${snapshot.error}'),
          ));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('No diseases found in master data.'),
          ));
        }

        // Store fetched data for use in the 'Add' method
        _availableDiseases = snapshot.data!;
        final availableDiseaseNames = _availableDiseases.map((d) => d.enName).toList();

        // Filter out diseases already in _diseaseHistory from the dropdown options
        final currentlyAddedNames = _diseaseHistory.map((e) => e.diseaseName).toSet();
        final dropdownOptions = availableDiseaseNames
            .where((name) => !currentlyAddedNames.contains(name))
            .toList();


        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add Chronic Diseases:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.indigo.shade700,
                  ),
                ),
                const SizedBox(height: 10),

                // 🎯 DROPDOWN AND ADD BUTTON
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: _currentSelectedDiseaseName,
                        decoration: const InputDecoration(
                          labelText: 'Select Disease',
                          border: OutlineInputBorder(borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(5),
                            bottomLeft: Radius.circular(5),
                            topRight: Radius.circular(0),
                            bottomRight: Radius.circular(0),
                          )),
                          isDense: true,
                        ),
                        items: dropdownOptions
                            .map((name) => DropdownMenuItem(value: name, child: Text(name)))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _currentSelectedDiseaseName = value;
                          });
                        },
                      ),
                    ),
                    Container(
                      height: 48, // Match the height of DropdownButtonFormField
                      decoration: BoxDecoration(
                        color: _currentSelectedDiseaseName != null ? Colors.indigo : Colors.grey.shade400,
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(5),
                          bottomRight: Radius.circular(5),
                        ),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.add, color: Colors.white),
                        onPressed: _currentSelectedDiseaseName != null ? _addDiseaseToHistory : null,
                        tooltip: 'Add Disease',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                // 🎯 LIST OF ADDED DISEASES WITH DURATION INPUT
                if (_diseaseHistory.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Added Diseases:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Use a Column here since the parent is a SingleChildScrollView/TabbarView
                      ..._diseaseHistory.map((entry) {
                        final controller = _historyDurationControllers[entry.diseaseName]!;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: controller,
                                  decoration: InputDecoration(
                                    labelText: entry.diseaseName,
                                    hintText: 'Duration (e.g., 5 years)',
                                    isDense: true,
                                    border: const OutlineInputBorder(),
                                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _removeDiseaseFromHistory(entry.diseaseName),
                                tooltip: 'Remove ${entry.diseaseName}',
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  )
                else
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text('No diseases added yet.', style: TextStyle(color: Colors.grey)),
                  )
              ],
            ),
          ),
        );
      },
    );
  }


  Widget _buildVitalsSection() {
    return Column(
      children: [
        const _SectionHeader(
          title: 'Physical Vitals',
          icon: Icons.monitor_weight,
        ),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // --- DATE SELECTION ---
                _buildDateSelection(),
                const SizedBox(height: 16),

                // --- UNIT TOGGLE ---
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Height Unit',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      ToggleButtons(
                        isSelected: [
                          _heightUnit == 'cm',
                          _heightUnit == 'ft/in',
                        ],
                        onPressed: (index) {
                          setState(() {
                            _heightUnit = index == 0 ? 'cm' : 'ft/in';
                            _calculateVitals();
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        children: const [
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text('cm'),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text('ft/in'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // --- HEIGHT INPUT (CONDITIONAL) ---
                if (_heightUnit == 'cm')
                  TextFormField(
                    controller: _heightController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Height (cm)*',
                      border: OutlineInputBorder(),
                      suffixText: 'cm',
                    ),
                    validator: (value) {
                      final val = double.tryParse(value ?? '');
                      if (val == null || val <= 0) {
                        return 'Please enter a valid height in cm';
                      }
                      return null;
                    },
                  )
                else // _heightUnit == 'ft/in'
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _heightFeetController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Feet (ft)*',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            final feet = double.tryParse(value ?? '') ?? 0;
                            final inches =
                                double.tryParse(_heightInchesController.text) ??
                                    0;
                            if (feet <= 0 && inches <= 0) {
                              return 'Enter height in ft/in';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _heightInchesController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d*'),
                            ),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Inches (in)*',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (_heightUnit == 'ft/in' &&
                                (double.tryParse(value ?? '') ?? 0) < 0) {
                              return 'Invalid inches';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 16),

                // --- WEIGHT INPUT ---
                TextFormField(
                  controller: _weightController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Weight (kg)*',
                    border: OutlineInputBorder(),
                    suffixText: 'kg',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter weight';
                    }
                    if (double.tryParse(value)! <= 0) {
                      return 'Please enter a valid weight';
                    }
                    return null;
                  },
                ),
              //  const SizedBox(height: 16),

                // --- BODY FAT PERCENTAGE INPUT ---
             /*   TextFormField(
                  controller: _bfpController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Body Fat Percentage (%)',
                    border: OutlineInputBorder(),
                    suffixText: '%',
                  ),
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final val = double.tryParse(value);
                      if (val == null || val < 0 || val > 100) {
                        return 'Please enter a valid percentage (0-100)';
                      }
                    }
                    return null;
                  },
                ),*/

                const SizedBox(height: 24),

                // --- BMI and IBW Display ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildCalculatedValue('BMI', _bmi),
                    _buildCalculatedValue('IBW (kg)', _idealBodyWeightKg),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCalculatedValue(String label, double value) {
    return Column(
      children: [
        Text(
          value > 0 ? value.toStringAsFixed(1) : 'N/A',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: value > 0 ? Colors.indigo : Colors.grey.shade500,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildCollapsibleMeasurementsSection() {
    return Column(
      children: [
        const _SectionHeader(
          title: 'Body Measurements',
          icon: Icons.accessibility,
        ),
        Card(
          elevation: 2,
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16),
            title: const Text(
              'Capture Body Circumferences',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            initiallyExpanded: _isMeasurementsExpanded,
            onExpansionChanged: (expanded) {
              setState(() {
                _isMeasurementsExpanded = expanded;
              });
            },
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  left: 16.0,
                  right: 16.0,
                  top: 8.0,
                  bottom: 16.0,
                ),
                child: Column(
                  children: [
                    _buildMeasurementInput(
                      controller: _waistController,
                      label: 'Waist Circumference',
                      unit: 'cm',
                    ),
                    _buildMeasurementInput(
                      controller: _hipController,
                      label: 'Hip Circumference',
                      unit: 'cm',
                    ),
                    _buildMeasurementInput(
                      controller: _chestController,
                      label: 'Chest Circumference',
                      unit: 'cm',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMeasurementInput({
    required TextEditingController controller,
    required String label,
    required String unit,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
        ],
        decoration: InputDecoration(
          labelText: '$label ($unit)',
          border: const OutlineInputBorder(),
          suffixText: unit,
        ),
        validator: (value) {
          if (value != null && value.isNotEmpty) {
            final val = double.tryParse(value);
            if (val == null || val <= 0) {
              return 'Please enter a valid $label';
            }
          }
          return null;
        },
      ),
    );
  }


  Widget _buildHabitInput({
    required String title,
    required String? value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
    required String limitLabel,
    required TextEditingController limitController,
  }) {
    final showLimit = value != 'No' && value != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            labelText: title,
            border: const OutlineInputBorder(),
          ),
          items: options
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
        if (showLimit)
          Padding(
            padding: const EdgeInsets.only(top: 10.0, bottom: 16.0),
            child: TextFormField(
              controller: limitController,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                labelText: limitLabel,
                border: const OutlineInputBorder(),
              ),
              validator: (val) {
                if (showLimit && (val == null || val.isEmpty)) {
                  return 'Please specify the limit/frequency.';
                }
                return null;
              },
            ),
          )
        else
          const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildHabitsSection() {
    return Column(
      children: [
        const _SectionHeader(
          title: 'Lifestyle Habits',
          icon: Icons.person_outline,
        ),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Existing: Food Habit
                DropdownButtonFormField<String>(
                  value: _foodHabit,
                  decoration: const InputDecoration(
                    labelText: 'Food Habit',
                    border: OutlineInputBorder(),
                  ),
                  items: _foodHabits
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (value) => setState(() => _foodHabit = value),
                ),
                const SizedBox(height: 16),

                // Existing: Activity Level
                DropdownButtonFormField<String>(
                  value: _activityType,
                  decoration: const InputDecoration(
                    labelText: 'Activity Level',
                    border: OutlineInputBorder(),
                  ),
                  items: _activityTypes
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (value) => setState(() => _activityType = value),
                ),
                const SizedBox(height: 16),

                // NEW: Drinking Habit
                _buildHabitInput(
                  title: 'Drinking Habit',
                  value: (_drinkingStatus?.isEmpty ?? true) ? null : _drinkingStatus,
                  options: _drinkingOptions,
                  onChanged: (value) => setState(() => _drinkingStatus = value),
                  limitLabel: 'Frequency/Quantity (e.g., 2 drinks/week)',
                  limitController: _drinkingLimitController,
                ),

                // NEW: Smoking Habit
                _buildHabitInput(
                  title: 'Smoking Habit',
                  value: (_smokingStatus?.isEmpty ?? true) ? null : _smokingStatus,
                  options: _smokingOptions,
                  onChanged: (value) => setState(() => _smokingStatus = value),
                  limitLabel: 'Quantity/Type (e.g., 5 cigarettes/day)',
                  limitController: _smokingLimitController,
                ),

                // NEW: Other Habits
                TextFormField(
                  controller: _otherHabitsController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText:
                    'Other Lifestyle Habits (e.g., Sleep, Stress, Gut Health)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildDateSelection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Record Date: ${DateFormat('dd MMM yyyy').format(_selectedDate)}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        TextButton.icon(
          onPressed: () async {
            final DateTime? pickedDate = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime(2000),
              lastDate: DateTime.now(),
            );
            if (pickedDate != null && pickedDate != _selectedDate) {
              setState(() {
                _selectedDate = pickedDate;
              });
            }
          },
          icon: const Icon(Icons.calendar_today),
          label: const Text('Change'),
        ),
      ],
    );
  }

  Widget _buildLabVitalsInput(
      String key,
      String displayName,
      String unit,
      String referenceRange,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: _labControllers[key],
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
        ],
        decoration: InputDecoration(
          labelText: displayName,
          border: const OutlineInputBorder(),
          suffixText: unit,
          hintText: 'Ref: $referenceRange',
        ),
      ),
    );
  }

  Widget _buildGroupedLabCards() {
    final Map<String, List<String>> testsByCategory = {};
    LabVitalsData.allLabTests.forEach((key, testData) {
      final category = testData.category;
      testsByCategory.putIfAbsent(category, () => []).add(key);
    });

    return Column(
      children: testsByCategory.entries.map((entry) {
        final category = entry.key;
        final testKeys = entry.value;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                  const Divider(height: 20),
                  ...testKeys.map((key) {
                    final testData = LabVitalsData.allLabTests[key]!;
                    return _buildLabVitalsInput(
                      key,
                      testData.displayName,
                      testData.unit,
                      testData.referenceRange,
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ----------------------------------------------------------------------
  // --- TAB CONTENT WIDGETS ---
  // ----------------------------------------------------------------------

  // 🎯 TAB 1: Metrics, Measurements, and Lab Vitals
  Widget _buildMetricsLabTabContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildVitalsSection(), // Includes Date Selection
          const SizedBox(height: 20),
          _buildCollapsibleMeasurementsSection(),
          const SizedBox(height: 20),
          const _SectionHeader(
            title: 'Lab Results',
            icon: Icons.medical_services,
          ),
          _buildGroupedLabCards(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // 🎯 TAB 2: Clinical & Lifestyle Data
  Widget _buildClinicalLifestyleTabContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [

          // 2. Existing Medication
          const _SectionHeader(title: 'Existing Medication', icon: Icons.local_hospital),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextFormField(
                controller: _medicationController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Current Medications',
                  hintText: 'e.g., Metformin 500mg BID, Amlodipine 5mg OD',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 3. Medical History (UPDATED HERE)
          const _SectionHeader(title: 'Chronic Medical History', icon: Icons.history_edu),
          // 🎯 NOW USES DROPDOWN/ADD/LIST PATTERN
          _buildMedicalHistorySelector(),
          const SizedBox(height: 20),

          // 4. Allergies / Restrictions
          const _SectionHeader(title: 'Allergies & Dietary Restrictions', icon: Icons.no_food),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextFormField(
                    controller: _allergiesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Food Allergies',
                      hintText: 'e.g., Peanut, Gluten, Shellfish',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _restrictedDietController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Other Restricted Diet / Cultural Preference',
                      hintText: 'e.g., Vegan, No Onion/Garlic, Low Sodium',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 5. Lifestyle Habits
          _buildHabitsSection(),
          const SizedBox(height: 20),

          // 6. Notes
          const _SectionHeader(title: 'Notes', icon: Icons.edit_note),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextFormField(
                controller: _notesController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Additional Notes/Comments (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  // ----------------------------------------------------------------------
  // --- MODIFIED build method ---
  // ----------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
         widget.vitalsToEdit != null ? 'Edit Vitals' : 'New Vitals Entry',
       ),
        centerTitle: true,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,

        // 🎯 ACTION BUTTON: SAVE
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveForm,
              tooltip: widget.vitalsToEdit != null ? 'Save Changes' : 'Add Vitals',
            ),
        ],

        // TabBar at the bottom of the AppBar
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.monitor_weight), text: 'Metrics & Labs'),
            Tab(icon: Icon(Icons.medical_services), text: 'Clinical Profile'),
          ],
        ),
      ),

      body: SafeArea(child: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildMetricsLabTabContent(),
                  _buildClinicalLifestyleTabContent(),
                ],
              ),
            ),
          ],
        ),
      ),),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.indigo, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
          ),
        ],
      ),
    );
  }
}