import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

// 🎯 NOTE: Adjust import paths for your project structure
import 'package:nutricare_client_management/helper/lab_vitals_data.dart'; //
import 'package:nutricare_client_management/helper/modules_config.dart';
import '../modules/client/model/vitals_model.dart'; //
import '../modules/client/services/vitals_service.dart'; //

final List<String> _foodHabits = [
  'Non-Vegetarian',
  'Vegetarian',
  'Eggetarian',
  'Vegan',
]; //
final List<String> _activityTypes = [
  //
  'Sedentary (Little to no exercise)',
  'Light (1-3 days/week)',
  'Moderate (3-5 days/week)',
  'Active (6-7 days/week)',
  'Very Active (Intense daily)',
];

class VitalsEntryPage extends StatefulWidget {
  final String clientId;
  final String clientName;
  final VitalsModel? vitalsToEdit;

  const VitalsEntryPage({
    super.key,
    required this.clientId,
    required this.clientName,
    this.vitalsToEdit,
  });

  @override
  State<VitalsEntryPage> createState() => _VitalsEntryPageState();
}

class _VitalsEntryPageState extends State<VitalsEntryPage> {
  final _formKey = GlobalKey<FormState>();

  // --- HEIGHT CONTROLLERS ---
  final _heightController =
  TextEditingController(); // Stores CM value internally
  final _heightFeetController = TextEditingController(); // For ft/in UI
  final _heightInchesController = TextEditingController(); // For ft/in UI
  String _heightUnit = 'cm'; // 'cm' or 'ft/in'
  // --------------------------

  final _weightController = TextEditingController();
  final _bfpController = TextEditingController();
  final _notesController = TextEditingController();

  final Map<String, TextEditingController> _labControllers = Map.fromIterable(
    LabVitalsData.allLabTests.keys,
    key: (key) => key,
    value: (_) => TextEditingController(),
  );

  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  // --- CALCULATED VITAL STATE ---
  double _bmi = 0.0;
  double _idealBodyWeightKg = 0.0;

  // --------------------------

  String? _foodHabit;
  String? _activityType;

  final VitalsService _vitalsService = VitalsService(); // Use final for service

  @override
  void initState() {
    super.initState();

    // Listeners for real-time calculations
    // The main CM controller listener is the primary trigger for calculations
    _heightController.addListener(_calculateVitals);
    _heightFeetController.addListener(
      _handleFeetInchChange,
    ); // Converts ft/in -> cm
    _heightInchesController.addListener(
      _handleFeetInchChange,
    ); // Converts ft/in -> cm
    _weightController.addListener(_calculateVitals);

    if (widget.vitalsToEdit != null) {
      _initializeForEdit(widget.vitalsToEdit!);
    } else {
      _calculateVitals();
    }
  }

  @override
  void dispose() {
    // Remove all listeners and dispose controllers
    _heightController.removeListener(_calculateVitals);
    _heightFeetController.removeListener(_handleFeetInchChange);
    _heightInchesController.removeListener(_handleFeetInchChange);

    _heightController.dispose();
    _heightFeetController.dispose();
    _heightInchesController.dispose();

    _weightController.removeListener(_calculateVitals);
    _weightController.dispose();
    _bfpController.dispose();
    _notesController.dispose();
    _labControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  void _initializeForEdit(VitalsModel vitals) {
    _selectedDate = vitals.date;

    // Height initialization: Set CM value and derive FT/IN values
    final heightCm = vitals.heightCm;
    _heightController.text = heightCm.toStringAsFixed(1);

    // If the height is valid, calculate feet/inches for the alternative input mode
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

    // Initialize calculated values for display
    _bmi = vitals.bmi;
    _idealBodyWeightKg = vitals.idealBodyWeightKg;

    _foodHabit = vitals.foodHabit;
    _activityType = vitals.activityType;

    vitals.labResults.forEach((key, value) {
      if (_labControllers.containsKey(key)) {
        _labControllers[key]!.text = value;
      }
    });
  }

  /// Converts feet/inches input to centimeters and updates the CM controller.
  void _handleFeetInchChange() {
    if (!mounted || _heightUnit != 'ft/in') {
      _calculateVitals(); // Still recalculate if weight changes in CM mode
      return;
    }

    final feet = double.tryParse(_heightFeetController.text) ?? 0.0;
    final inches = double.tryParse(_heightInchesController.text) ?? 0.0;

    double heightCm = 0.0;
    if (feet > 0 || inches > 0) {
      final totalInches = (feet * 12) + inches;
      // 1 inch = 2.54 cm
      heightCm = totalInches * 2.54;
    }

    // Update the main CM controller silently
    // This value is what is used for calculation and saving
    _heightController.text = heightCm.toString();

    _calculateVitals(); // Trigger main calculation
  }

  /// Calculates BMI and Ideal Body Weight based on CM and KG controllers.
  void _calculateVitals() {
    if (!mounted) return;

    // Always parse from _heightController which contains the CM value
    final heightCm = double.tryParse(_heightController.text) ?? 0.0;
    final weightKg = double.tryParse(_weightController.text) ?? 0.0;

    double newBmi = 0.0;
    double newIbw = 0.0;

    if (heightCm > 0 && weightKg > 0) {
      // --- BMI Calculation: kg / (m * m) ---
      final heightMeters = heightCm / 100;
      newBmi = weightKg / (heightMeters * heightMeters);

      // --- Ideal Body Weight (IBW) Calculation (Devine Formula - Placeholder) ---
      // NOTE: Gender specific formula should be used in a production app.
      // This is a common simplified version.
      final heightInches = heightCm / 2.54;
      final inchesOver5Feet = heightInches - 60; // 5 feet = 60 inches

      if (inchesOver5Feet > 0) {
        // Devine Formula (Male - simplified): 50.0 kg + 2.3 kg * (heightInches - 60)
        newIbw = 50.0 + (2.3 * inchesOver5Feet);
      } else {
        // Baseline if 5 feet or less (assuming 50kg baseline)
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

  // --- Helper Methods ---
  Map<String, double> _getMeasurements() => {}; // Placeholder
  Map<String, String> _getLabResults() {
    final results = <String, String>{};
    _labControllers.forEach((key, controller) {
      if (controller.text.isNotEmpty) {
        results[key] = controller.text.trim();
      }
    });
    return results;
  }

  // ----------------------

  void _saveForm() async {
    // 1. Validate the form. The height fields have their own validators.
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Ensure final calculation is performed before saving
    _calculateVitals();

    final vitalsId =
        widget.vitalsToEdit?.id ??
            'VITAL_${DateTime.now().millisecondsSinceEpoch}';

    // 2. HEIGHT SAVED FROM THE CM CONTROLLER (the guaranteed CM source)
    final heightCm = double.tryParse(_heightController.text) ?? 0.0;

    final VitalsModel newVitals = VitalsModel(
      id: vitalsId,
      clientId: widget.clientId,
      date: _selectedDate,

      // NEW FIELDS
      heightCm: heightCm,
      bmi: _bmi,
      idealBodyWeightKg: _idealBodyWeightKg,

      // EXISTING FIELDS
      weightKg: double.tryParse(_weightController.text) ?? 0.0,
      bodyFatPercentage: double.tryParse(_bfpController.text) ?? 0.0,

      measurements: _getMeasurements(),
      labResults: _getLabResults(),
      notes: _notesController.text.isEmpty
          ? null
          : _notesController.text.trim(),
      labReportUrls: widget.vitalsToEdit?.labReportUrls ?? [],
      foodHabit: _foodHabit,
      activityType: _activityType, isFirstConsultation: false,
    );

    try {
      await _vitalsService.addVitals(newVitals);
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

  // --- UI Build Methods ---

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
                // --- UNIT TOGGLE (NEW) ---
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
                            _calculateVitals(); // Recalculate just in case
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

                      //],
                      //),
                      const SizedBox(height: 16),

                      // --- Weight Input (Existing) ---
                      TextFormField(
                        controller: _weightController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*'),
                          ),
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
                          if (double.tryParse(value) == null ||
                              double.parse(value)! <= 0) {
                            return 'Please enter a valid weight';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // --- Body Fat Percentage (Existing) ---
                      TextFormField(
                        controller: _bfpController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*'),
                          ),
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
                      ),

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
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLabVitalsInput(String key, String displayName, String unit) {
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
        ),
      ),
    );
  }

  Widget _buildGroupedLabCards() {
    // Group tests by category
    final Map<String, List<String>> testsByCategory = {};
    LabVitalsData.allLabTests.forEach((key, testData) {
      // FIX: Use testData.category instead of testData['category']
      final category = testData.displayName;
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
                  Text(category, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo)),
                  const Divider(height: 20),
                  ...testKeys.map((key) {
                    final testData = LabVitalsData.allLabTests[key]!;
                    // FIX: Use testData.displayName and testData.unit instead of map notation
                    return _buildLabVitalsInput(
                      key,
                      testData.displayName,
                      testData.unit,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.vitalsToEdit != null ? 'Edit Vitals' : 'New Vitals Entry',
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- Date Selection ---
                _buildDateSelection(),
                const SizedBox(height: 20),

                // --- Vitals Section (with new Height/BMI/IBW) ---
                _buildVitalsSection(),
                const SizedBox(height: 20),

                // --- Habits Section ---
                _buildHabitsSection(),
                const SizedBox(height: 20),

                // --- Measurements (Placeholder) ---
                const _SectionHeader(
                  title: 'Body Measurements',
                  icon: Icons.accessibility,
                ),
                const Card(
                  elevation: 2,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Measurement inputs (waist, hip, etc.) go here.',
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // --- Lab Vitals Grouped Cards ---
                const _SectionHeader(
                  title: 'Lab Results',
                  icon: Icons.medical_services,
                ),
                _buildGroupedLabCards(),

                // --- Notes ---
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
                const SizedBox(height: 30),

                // --- Save Button ---
                Center(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveForm,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                      widget.vitalsToEdit != null
                          ? 'Save Changes'
                          : 'Add Vitals',
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Helper Widget for Section Header
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
