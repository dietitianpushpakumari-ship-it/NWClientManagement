import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nutricare_client_management/admin/labvital/global_service_provider.dart';


// --- Project Imports ---
import 'package:nutricare_client_management/modules/client/model/vitals_model.dart';
import 'package:nutricare_client_management/modules/client/services/vitals_service.dart';
import 'package:nutricare_client_management/helper/lab_vitals_data.dart'; // LabTestConfig definitions
import 'package:nutricare_client_management/modules/master/service/diagonosis_master_service.dart'; // Diagnosis service


class VitalsEntryScreen extends ConsumerStatefulWidget {
  final String clientId;
  final String clientName;
  final VitalsModel? vitalToEdit;
  final VoidCallback onVitalsSaved;
  final bool isFirstConsultation;

  const VitalsEntryScreen({
    super.key,
    required this.clientId,
    required this.clientName,
    required this.onVitalsSaved,
    this.vitalToEdit,
    this.isFirstConsultation = false,
  });

  @override
  ConsumerState<VitalsEntryScreen> createState() => _VitalsEntryScreenState();
}

class _VitalsEntryScreenState extends ConsumerState<VitalsEntryScreen> {
  final _formKey = GlobalKey<FormState>();

  // --- Controllers for Anthro/Vitals ---
  final _dateController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _systolicController = TextEditingController();
  final _diastolicController = TextEditingController();
  final _notesController = TextEditingController();

  // --- Dynamic Lab Controllers (Map<lab_key, controller>) ---
  final Map<String, TextEditingController> _labControllers = {};

  // --- State Variables ---
  DateTime _selectedDate = DateTime.now();
 // List<String> _selectedDiagnosisIds = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize ALL possible lab controllers
    LabVitalsData.allLabTests.keys.forEach((key) {
      _labControllers[key] = TextEditingController();
    });

    _prefillForm(widget.vitalToEdit);
  }

  void _prefillForm(VitalsModel? vital) {
    if (vital != null) {
      _selectedDate = vital.date;
      _dateController.text = DateFormat('dd MMM yyyy').format(vital.date);
      _weightController.text = vital.weightKg.toString();
      _heightController.text = vital.heightCm.toString();
      _systolicController.text = vital.bloodPressureSystolic?.toString() ?? '';
      _diastolicController.text = vital.bloodPressureDiastolic?.toString() ?? '';
      //_notesController.text = vital.notes ?? '';
  //    _selectedDiagnosisIds = List.from(vital.diagnosis);

      // Pre-fill lab values
      vital.labResults.forEach((key, value) {
        if (_labControllers.containsKey(key)) {
          // Use the value's string representation for the controller text
          _labControllers[key]!.text = value.toString();
        }
      });
    } else {
      // Default for new entry
      _dateController.text = DateFormat('dd MMM yyyy').format(_selectedDate);
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _systolicController.dispose();
    _diastolicController.dispose();
    //_notesController.dispose();
    _labControllers.values.forEach((c) => c.dispose());
    super.dispose();
  }

  // --- SAVE LOGIC ---

  Future<void> _saveVitals() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    // Access VitalsService via Riverpod
    final vitalsService = ref.read(vitalsServiceProvider);

    // 1. Gather Lab Results (Map<String, double>)
    final Map<String, double> labResults = {};
    _labControllers.forEach((key, controller) {
      final value = double.tryParse(controller.text.trim());
      if (value != null) {
        labResults[key] = value;
      }
    });

    // 2. Build Model
    // 💡 Note: BMI and idealBodyWeightKg should ideally be calculated here,
    // but are set to 0.0 as placeholders based on the provided model structure.
    final vitalToSave = VitalsModel(
      id: widget.vitalToEdit?.id ?? '',
      clientId: widget.clientId,
      date: _selectedDate,

      // Anthro/Vitals Metrics (Safely parse and default to 0/null)
      weightKg: double.tryParse(_weightController.text.trim()) ?? 0.0,
      heightCm: double.tryParse(_heightController.text.trim()) ?? 0.0,
      bmi: 0.0,
      idealBodyWeightKg: 0.0,

      bloodPressureSystolic: int.tryParse(_systolicController.text.trim()),
      bloodPressureDiastolic: int.tryParse(_diastolicController.text.trim()),

      // Mandatory Fields (set to defaults or ensure parsing)
      bodyFatPercentage: 0.0,
      measurements: const {},
      isFirstConsultation: widget.isFirstConsultation,

      // Clinical Data
      //diagnosis: _selectedDiagnosisIds,
      labResults: labResults, // 🎯 Dynamic Lab Results
     // notes: _notesController.text.trim(),

      // Placeholder safety fields
      complaints: null, heartRate: null, spO2Percentage: null, waistCm: null, hipCm: null,
      labReportUrls: const [], medicalHistory: {}, prescribedMedications: const [],
      existingMedication: null, foodAllergies: [],
      restrictedDiet: null, foodHabit: null, activityType: null, otherLifestyleHabits: const {},
      assignedDietPlanIds: const [],
    );

    // 3. Save
    try {
      await vitalsService.saveVitals(vitalToSave);
      widget.onVitalsSaved(); // Execute callback
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- UI BUILDERS ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      // ❌ NO APPBARR - Custom header used to maintain premium layout

      body: Column(
        children: [
          // 1. 🎯 Custom Header (Replaces AppBar functionality)
          Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 10,
              left: 16,
              right: 16,
              bottom: 8,
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black87),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 10),
                Text(
                  widget.vitalToEdit == null ? 'New Vitals Record' : 'Edit Vitals Record',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
                ),
              ],
            ),
          ),

          // 2. Form Body (Expanded and Scrollable)
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildDateSection(),
                  _buildAnthroSection(),
                  _buildVitalsSection(),
                  _buildLabVitalsSection(ref), // Dynamic Lab Inputs
              //    _buildDiagnosisSection(ref),
                 // _buildNotesSection(),

                  // --- Save Button (Inside ListView) ---
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _saveVitals,
                    icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.check_circle_outline),
                    label: Text(widget.vitalToEdit == null ? "SAVE NEW RECORD" : "UPDATE RECORD"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
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

  // 🎯 DYNAMIC LAB INPUT SECTION (FIXED Logic for MapEntry)
  Widget _buildLabVitalsSection(WidgetRef ref) {
    // Group tests by category, storing MapEntry (key and value)
    final Map<String, List<MapEntry<String, LabTestConfig>>> categorizedTests = {};

    // Iterate over entries to keep both the key (ID) and the config (display data)
    LabVitalsData.allLabTests.entries.forEach((entry) {
      final category = entry.value.category;
      if (!categorizedTests.containsKey(category)) {
        categorizedTests[category] = [];
      }
      categorizedTests[category]!.add(entry);
    });

    return _buildCard(
      title: "Lab Test Results",
      icon: Icons.science,
      color: Colors.indigo,
      child: Column(
        children: LabVitalsData.labCategories.where((cat) => categorizedTests.containsKey(cat)).map((category) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 15, bottom: 8),
                child: Text(category, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
              Wrap(
                spacing: 10, runSpacing: 10,
                children: categorizedTests[category]!.map((entry) {
                  final String key = entry.key; // The string ID (e.g., 'fbs')
                  final LabTestConfig config = entry.value;

                  final controller = _labControllers[key];
                  if (controller == null) return const SizedBox.shrink();

                  return SizedBox(
                    width: 180,
                    child: _buildField(
                      controller,
                      "${config.displayName} (${config.unit})",
                      Icons.numbers,
                      isNumber: true,
                      helperText: config.referenceRangeDisplay,
                    ),
                  );
                }).toList(),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

 /* Widget _buildDiagnosisSection(WidgetRef ref) {
    // 🎯 FIX: Access DiagnosisMasterService via Riverpod
    final diagnosisService = ref.read(diagnosisMasterServiceProvider);

    // Fetch all diagnoses for the dropdown/chip list
    final diagnosisAsync = ref.read(
        FutureProvider.autoDispose((ref) => diagnosisService.fetchAllDiagnosisMaster())
    );

    return _buildCard(
      title: "Diagnosis",
      icon: Icons.local_hospital,
      color: Colors.purple,
      child: diagnosisAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        error: (err, stack) => Text('Error loading diagnosis: $err'),
        data: (list) {
          return Wrap(
            spacing: 8.0,
            children: list.map((diag) {
              final isSelected = _selectedDiagnosisIds.contains(diag.id);
              return FilterChip(
                label: Text(diag.enName),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedDiagnosisIds.add(diag.id);
                    } else {
                      _selectedDiagnosisIds.remove(diag.id);
                    }
                  });
                },
                selectedColor: Colors.purple.shade100,
                checkmarkColor: Colors.purple.shade900,
                labelStyle: TextStyle(color: isSelected ? Colors.purple.shade900 : Colors.black87),
              );
            }).toList(),
          );
        },
      ),
    );
  }*/

  /*Widget _buildNotesSection() {
    return _buildCard(
      title: "Consultation Notes",
      icon: Icons.notes,
      color: Colors.teal,
      child: _buildMultiLineField(_notesController, "Notes on current vitals/status"),
    );
  }*/

  // -----------------------------------------------------------------
  // --- COMMON HELPERS ---
  // -----------------------------------------------------------------

  Widget _buildDateSection() {
    return _buildCard(
      title: "Record Date",
      icon: Icons.calendar_today,
      color: Colors.blue,
      child: TextFormField(
        controller: _dateController,
        readOnly: true,
        decoration: _inputDec("Date", Icons.calendar_today),
        onTap: () async {
          final DateTime? picked = await showDatePicker(
            context: context,
            initialDate: _selectedDate,
            firstDate: DateTime(2000),
            lastDate: DateTime.now(),
          );
          if (picked != null && picked != _selectedDate) {
            setState(() {
              _selectedDate = picked;
              _dateController.text = DateFormat('dd MMM yyyy').format(picked);
            });
          }
        },
      ),
    );
  }

  Widget _buildAnthroSection() {
    return _buildCard(
      title: "Anthropometry",
      icon: Icons.scale,
      color: Colors.red,
      child: Row(
        children: [
          Expanded(child: _buildField(_weightController, "Weight (kg)", Icons.line_weight)),
          const SizedBox(width: 10),
          Expanded(child: _buildField(_heightController, "Height (cm)", Icons.height)),
        ],
      ),
    );
  }

  Widget _buildVitalsSection() {
    return _buildCard(
      title: "Cardio Metrics",
      icon: Icons.monitor_heart,
      color: Colors.pink,
      child: Row(
        children: [
          Expanded(child: _buildField(_systolicController, "BP Sys", Icons.arrow_upward, isNumber: true)),
          const SizedBox(width: 10),
          Expanded(child: _buildField(_diastolicController, "BP Dias", Icons.arrow_downward, isNumber: true)),
        ],
      ),
    );
  }

  Widget _buildCard({required String title, required IconData icon, required Color color, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const Divider(height: 25),
          child,
        ],
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon, {bool isNumber = false, String? helperText}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      decoration: _inputDec(label, icon).copyWith(
        helperText: helperText,
        helperStyle: const TextStyle(color: Colors.grey, fontSize: 11),
      ),
      validator: (v) {
        if (v!.isNotEmpty && isNumber && double.tryParse(v) == null) {
          return 'Enter a valid number.';
        }
        return null;
      },
    );
  }

  Widget _buildMultiLineField(TextEditingController ctrl, String label) {
    return TextFormField(
      controller: ctrl,
      decoration: _inputDec(label, Icons.edit),
      maxLines: 4,
    );
  }

  InputDecoration _inputDec(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
      fillColor: Colors.grey.shade50,
      filled: true,
    );
  }
}