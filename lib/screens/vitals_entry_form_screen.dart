import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nutricare_client_management/admin/lab_test_config_model.dart';
import 'package:nutricare_client_management/admin/lab_test_config_service.dart';
import 'package:nutricare_client_management/admin/labvital/global_service_provider.dart';
import 'package:nutricare_client_management/modules/client/model/client_model.dart';

// --- Project Imports ---
import 'package:nutricare_client_management/modules/client/model/vitals_model.dart';
import 'package:nutricare_client_management/modules/client/services/vitals_service.dart';

class VitalsEntryScreen extends ConsumerStatefulWidget {
  final String clientId;
  final String clientName;
  final String? sessionId; // 🎯 Add this
  final bool isReadOnly;

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
    this.sessionId,        // 🎯 Initialize
    this.isReadOnly = false,
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
  final _waistController = TextEditingController();
  final _hipController = TextEditingController();
  final _systolicController = TextEditingController();
  final _diastolicController = TextEditingController();
  final _heartRateController = TextEditingController();
  final _bmiController = TextEditingController();
  final _ibwController = TextEditingController();

  // --- Dynamic Lab Controllers ---
  final Map<String, TextEditingController> _labControllers = {};

  // --- State Variables ---
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  bool _isLabControllersInitialized = false;
  ClientModel? clientData;

  bool _isHeightInCm = true; // Toggle for height unit
  final _feetController = TextEditingController();
  final _inchesController = TextEditingController();
  String _selectedGender = 'Male';

  @override
  void initState() {
    super.initState();
    _prefillForm(widget.vitalToEdit);

    // 🎯 Auto-calculation Listeners
    _weightController.addListener(_calculateAutoMetrics);
    _heightController.addListener(_calculateAutoMetrics);
    _feetController.addListener(_calculateAutoMetrics);
    _inchesController.addListener(_calculateAutoMetrics);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchClientData();
    });
  }

  Future<void> _fetchClientData() async {
    try {
      // Access the ClientService via Riverpod
      final clientService = ref.read(clientServiceProvider);

      // Fetch the full client object by ID
      final client= await clientService.getClientById(widget.clientId);

      if (mounted) {
        setState(() {
          clientData = client;
        });

        // 🎯 Once client is loaded, run auto-calculations if needed
        if (clientData != null) {
          _calculateAutoMetrics();
        }
      }
    } catch (e) {
      debugPrint("Error fetching client in initState: $e");
    }
  }

  void _calculateAutoMetrics() {
    double weight = double.tryParse(_weightController.text.trim()) ?? 0;
    double heightCm = 0;

    // 1. Determine Height in CM
    if (_isHeightInCm) {
      heightCm = double.tryParse(_heightController.text.trim()) ?? 0;
    } else {
      double feet = double.tryParse(_feetController.text.trim()) ?? 0;
      double inches = double.tryParse(_inchesController.text.trim()) ?? 0;
      heightCm = (feet * 30.48) + (inches * 2.54);

      // Sync the master height controller used for saving to DB
      if (heightCm > 0 && !_isHeightInCm) {
        _heightController.text = heightCm.toStringAsFixed(1);
      }
    }

    if (weight > 0 && heightCm > 100) {
      // 2. BMI Calculation (kg/m²)
      double heightInMeters = heightCm / 100;
      double bmi = weight / (heightInMeters * heightInMeters);
      _bmiController.text = bmi.toStringAsFixed(1);

      // 3. IBW Calculation (Devine Formula)
      // Gender pulled from widget.client.gender
      double inchesOver5Feet = (heightCm - 152.4) / 2.54;
      double ibw = 0;

      bool isMale = !clientData!.gender.toLowerCase().contains('Female') || // Fallback if gender string is missing
          (widget.clientId.isNotEmpty); // Replace with widget.client.gender check

      // Standard Devine Formula
      if (isMale) {
        ibw = 50 + (2.3 * inchesOver5Feet);
      } else {
        ibw = 45.5 + (2.3 * inchesOver5Feet);
      }

      _ibwController.text = ibw.toStringAsFixed(1);
    } else {
      _bmiController.clear();
      _ibwController.clear();
    }
  }

  void _prefillForm(VitalsModel? vital) {
    if (vital != null) {
      _selectedDate = vital.date;
      _dateController.text = DateFormat('dd MMM yyyy').format(vital.date);
      _weightController.text = vital.weightKg.toString();
      _heightController.text = vital.heightCm.toString();
      _waistController.text = vital.waistCm?.toString() ?? '';
      _hipController.text = vital.hipCm?.toString() ?? '';
      _systolicController.text = vital.bloodPressureSystolic?.toString() ?? '';
      _diastolicController.text = vital.bloodPressureDiastolic?.toString() ?? '';
      _heartRateController.text = vital.heartRate?.toString() ?? '';
      _bmiController.text = vital.bmi.toString();
      _ibwController.text = vital.idealBodyWeightKg.toString();
    } else {
      _dateController.text = DateFormat('dd MMM yyyy').format(_selectedDate);
    }
  }

  void _initializeLabControllers(List<LabTestConfigModel> tests) {
    if (_isLabControllersInitialized) return;
    for (var config in tests) {
      _labControllers[config.id] = TextEditingController();
    }
    if (widget.vitalToEdit != null) {
      widget.vitalToEdit!.labResults.forEach((key, value) {
        if (_labControllers.containsKey(key)) {
          _labControllers[key]!.text = value.toString();
        }
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _isLabControllersInitialized = true);
    });
  }

  @override
  void dispose() {
    _weightController.removeListener(_calculateAutoMetrics);
    _heightController.removeListener(_calculateAutoMetrics);
    _dateController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _waistController.dispose();
    _hipController.dispose();
    _systolicController.dispose();
    _diastolicController.dispose();
    _heartRateController.dispose();
    _bmiController.dispose();
    _ibwController.dispose();
    _labControllers.values.forEach((c) => c.dispose());
    super.dispose();
  }

  Future<void> _saveVitals() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final vitalsService = ref.read(vitalsServiceProvider);
    final Map<String, double> labResults = {};
    _labControllers.forEach((key, controller) {
      final value = double.tryParse(controller.text.trim());
      if (value != null) labResults[key] = value;
    });

    final vitalToSave = VitalsModel(
      id: widget.vitalToEdit?.id ?? '',
      clientId: widget.clientId,
      date: _selectedDate,
      weightKg: double.tryParse(_weightController.text.trim()) ?? 0.0,
      heightCm: double.tryParse(_heightController.text.trim()) ?? 0.0,
      waistCm: double.tryParse(_waistController.text.trim()),
      hipCm: double.tryParse(_hipController.text.trim()),
      bmi: double.tryParse(_bmiController.text.trim()) ?? 0.0,
      idealBodyWeightKg: double.tryParse(_ibwController.text.trim()) ?? 0.0,
      bloodPressureSystolic: int.tryParse(_systolicController.text.trim()),
      bloodPressureDiastolic: int.tryParse(_diastolicController.text.trim()),
      heartRate: int.tryParse(_heartRateController.text.trim()),
      bodyFatPercentage: 0.0,
      isFirstConsultation: widget.isFirstConsultation,
     );   fuv                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           zZza

    try {
      await vitalsService.saveVitals(vitalToSave);
      widget.onVitalsSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F8), // Soft neutral background
      body: Column(
        children: [
          _buildUltraPremiumHeader(),
          Expanded(
            child: AbsorbPointer(
              absorbing: widget.isReadOnly,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    _buildSectionTitle("Body Composition"),
                    _buildAnthroGrid(), // Premium 2x2 grid for Wt, Ht, BMI
                    const SizedBox(height: 24),
                    _buildSectionTitle("Clinical Vitals"),
                    _buildVitalsCard(), // BP, Sugar, Heart Rate
                    const SizedBox(height: 24),
                    _buildSectionTitle("Biochemical Lab Results"),
                    _buildLabList(),
                    const SizedBox(height: 120), // Bottom padding
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildPremiumSaveButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildMetricDisplayCard(String label, double value, String unit, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6), // Subtle glass effect
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.blueGrey),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blueGrey)),
            ],
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value == 0 ? "--" : value.toStringAsFixed(1),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF2D3142)),
              ),
              const SizedBox(width: 4),
              Text(unit, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: Colors.indigo.withOpacity(0.8),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildUltraPremiumHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 48, 24, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: Row(
        children: [
          _buildCircularBackButton(),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isReadOnly ? "Archived Session" : "Active Consultation",
                  style: const TextStyle(fontSize: 14, color: Colors.indigo, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                ),
                Text(
                  widget.clientName,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1A1C1E)),
                ),
              ],
            ),
          ),
          if (widget.isReadOnly)
            _buildStatusChip("ARCHIVED", Colors.blueGrey)
          else
            _buildStatusChip("LIVE", Colors.green),
        ],
      ),
    );
  }

  Widget _buildCircularBackButton() {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Icon(Icons.arrow_back_ios_new, size: 16, color: Colors.black),
      ),
    );
  }
  Widget _buildAnthroGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.4,
      children: [
        _buildPremiumInputCard("Weight", _weightController, "kg", Icons.monitor_weight_outlined),
        _buildPremiumInputCard("Height", _heightController, "cm", Icons.height),
        _buildMetricDisplayCard("BMI", _bmiValue, "kg/m²", Icons.speed),
        _buildMetricDisplayCard("Fat %", _fatValue, "%", Icons.opacity),
      ],
    );
  }

  Widget _buildPremiumInputCard(String label, TextEditingController controller, String unit, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.indigo.withOpacity(0.05), blurRadius: 15)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.indigo),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
            ],
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                  decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                ),
              ),
              Text(unit, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumSaveButton() {
    if (widget.isReadOnly) return const SizedBox.shrink();

    return Container(
      width: MediaQuery.of(context).size.width * 0.8,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF4338CA), Color(0xFF6366F1)]),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: Colors.indigo.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: _saveVitals,
          child: const Center(
            child: Text(
              "Finalize Vitals",
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
          ),
        ),
      ),
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
  Widget _buildAnthroSection() {
    return _buildCard(
      title: "Anthropometry",
      icon: Icons.scale,
      color: Colors.red,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildField(_weightController, "Weight (kg)", Icons.line_weight, isNumber: true)),
              const SizedBox(width: 15),
              // Height Unit Switcher
              Column(
                children: [
                  const Text("Unit", style: TextStyle(fontSize: 10, color: Colors.grey)),
                  Switch(
                    value: _isHeightInCm,
                    onChanged: (val) {
                      setState(() => _isHeightInCm = val);
                      _calculateAutoMetrics();
                    },
                  ),
                  Text(_isHeightInCm ? "CM" : "FT/IN", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),

          // Conditional Height Input Layout
          if (_isHeightInCm)
            _buildField(_heightController, "Height (cm)", Icons.height, isNumber: true)
          else
            Row(
              children: [
                Expanded(child: _buildField(_feetController, "Feet", Icons.height, isNumber: true)),
                const SizedBox(width: 10),
                Expanded(child: _buildField(_inchesController, "Inches", Icons.height, isNumber: true)),
              ],
            ),

          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(child: _buildField(_waistController, "Waist (cm)", Icons.straighten, isNumber: true)),
              const SizedBox(width: 10),
              Expanded(child: _buildField(_hipController, "Hip (cm)", Icons.straighten, isNumber: true)),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              // Auto-calculated fields set to ReadOnly
              Expanded(child: _buildField(_bmiController, "BMI (Auto)", Icons.calculate, isReadOnly: true)),
              const SizedBox(width: 10),
              Expanded(child: _buildField(_ibwController, "Ideal Weight", Icons.star, isReadOnly: true)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVitalsSection() => _buildCard(
    title: "Cardio Metrics",
    icon: Icons.monitor_heart,
    color: Colors.pink,
    child: Column(
      children: [
        Row(children: [
          Expanded(child: _buildField(_systolicController, "BP Sys", Icons.arrow_upward, isNumber: true)),
          const SizedBox(width: 10),
          Expanded(child: _buildField(_diastolicController, "BP Dias", Icons.arrow_downward, isNumber: true)),
        ]),
        const SizedBox(height: 10),
        _buildField(_heartRateController, "Heart Rate (BPM)", Icons.favorite, isNumber: true),
      ],
    ),
  );

  // --- Helpers ---
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
          Row(children: [Icon(icon, color: color, size: 20), const SizedBox(width: 10), Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]),
          const Divider(height: 25),
          child,
        ],
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon, {bool isNumber = false, String? helperText, bool isReadOnly = false}) {
    return TextFormField(
      controller: ctrl,
      readOnly: isReadOnly,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        helperText: helperText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: isReadOnly ? Colors.blueGrey.shade50 : Colors.grey.shade50,
      ),
      validator: (v) => (v!.isNotEmpty && isNumber && double.tryParse(v) == null) ? 'Invalid number' : null,
    );
  }

  Widget _buildDateSection() => _buildCard(
    title: "Record Date",
    icon: Icons.calendar_today,
    color: Colors.blue,
    child: TextFormField(
      controller: _dateController,
      readOnly: true,
      decoration: InputDecoration(
        labelText: "Date",
        prefixIcon: const Icon(Icons.calendar_today),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
        );
        if (picked != null) setState(() {
          _selectedDate = picked;
          _dateController.text = DateFormat('dd MMM yyyy').format(picked);
        });
      },
    ),
  );

  Widget _buildLabVitalsSection(List<LabTestConfigModel> labTests) {
    final Map<String, List<LabTestConfigModel>> categorizedTests = {};
    for (var config in labTests) {
      categorizedTests.putIfAbsent(config.category, () => []).add(config);
    }
    return _buildCard(
      title: "Lab Test Results",
      icon: Icons.science,
      color: Colors.indigo,
      child: Column(
        children: categorizedTests.keys.map((category) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(padding: const EdgeInsets.only(top: 15, bottom: 8), child: Text(category, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
              Wrap(
                spacing: 10, runSpacing: 10,
                children: categorizedTests[category]!.map((config) {
                  return SizedBox(
                    width: 180,
                    child: _buildField(_labControllers[config.id]!, config.displayName, Icons.numbers, isNumber: true, helperText: config.unit),
                  );
                }).toList(),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildErrorCard(String title, String message) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.red)),
    child: Text("$title: $message", style: TextStyle(color: Colors.red.shade800)),
  );
}