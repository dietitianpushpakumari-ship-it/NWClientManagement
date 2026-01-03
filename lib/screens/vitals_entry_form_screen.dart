import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nutricare_client_management/admin/database_provider.dart';
import 'package:nutricare_client_management/admin/lab_report_scanner_service.dart';
import 'package:nutricare_client_management/admin/lab_test_config_model.dart';
import 'package:nutricare_client_management/admin/lab_test_config_service.dart';
import 'package:nutricare_client_management/admin/labvital/global_service_provider.dart';
import 'package:nutricare_client_management/helper/lab_vitals_data.dart';
import 'package:nutricare_client_management/image_compressor.dart';
import 'package:nutricare_client_management/modules/client/model/vitals_model.dart';
import 'package:nutricare_client_management/admin/consultation_session_service.dart';
import 'package:collection/collection.dart';

class VitalsEntryScreen extends ConsumerStatefulWidget {
  final String clientId;
  final String clientName;
  final VitalsModel? vitalToEdit;
  final VitalsModel? previousVital;
  final String? sessionId;
  final bool isReadOnly;
  final VoidCallback onVitalsSaved;

  const VitalsEntryScreen({
    super.key,
    required this.clientId,
    required this.clientName,
    required this.onVitalsSaved,
    this.vitalToEdit,
    this.previousVital,
    this.sessionId,
    this.isReadOnly = false,
  });

  @override
  ConsumerState<VitalsEntryScreen> createState() => _VitalsEntryScreenState();
}

class _VitalsEntryScreenState extends ConsumerState<VitalsEntryScreen> {
  bool _isLoading = false;
  bool _isScanning = false;
  late TextEditingController _weightController;
  late TextEditingController _heightController;
  late TextEditingController _sysController;
  late TextEditingController _diaController;
  late TextEditingController _hrController;
  late TextEditingController _waistController;
  late TextEditingController _hipController;
  double _idealBodyWeight = 0.0;

  final Map<String, TextEditingController> _labControllers = {};
  bool _isLabControllersInitialized = false;
  List<LabTestConfigModel> _allAvailableTests = [];
  double _bmiValue = 0.0;
  double _fatValue = 0.0;
  bool isCm = true;

  @override
  void initState() {
    super.initState();

    _weightController = TextEditingController(text: widget.vitalToEdit?.weightKg.toString() ?? '');
    _heightController = TextEditingController(text: widget.vitalToEdit?.heightCm?.toString() ?? '');
    _sysController = TextEditingController(text: widget.vitalToEdit?.bloodPressureSystolic?.toString() ?? '');
    _diaController = TextEditingController(text: widget.vitalToEdit?.bloodPressureDiastolic?.toString() ?? '');
    _hrController = TextEditingController(text: widget.vitalToEdit?.heartRate?.toString() ?? '');
    _fatValue = widget.vitalToEdit?.bodyFatPercentage ?? 0.0;
    _waistController = TextEditingController(text: widget.vitalToEdit?.waistCm?.toString() ?? '');
    _hipController = TextEditingController(text: widget.vitalToEdit?.hipCm?.toString() ?? '');

    _calculateBMI();
    _weightController.addListener(_calculateBMI);
    _heightController.addListener(_calculateBMI);
  }

  void _calculateBMI() {
    final w = double.tryParse(_weightController.text);
    final h = double.tryParse(_heightController.text);
    if (w != null && h != null && h > 0) {
      setState(() {
        _bmiValue = w / ((h / 100) * (h / 100));
        _idealBodyWeight = 22 * ((h / 100) * (h / 100));
      });
    }
  }

  void _initializeLabControllers(List<LabTestConfigModel> tests) {
    _allAvailableTests = tests;
    for (var test in tests) {
      final existingValue = widget.vitalToEdit?.labResults?[test.id];
      _labControllers[test.id] = TextEditingController(
          text: existingValue != null ? existingValue.toString() : ''
      );
    }
    _isLabControllersInitialized = true;
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _sysController.dispose();
    _diaController.dispose();
    _hrController.dispose();
    _labControllers.forEach((_, c) => c.dispose());
    super.dispose();
  }
  Future<void> _pickAndScanReport() async {
    if (_allAvailableTests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lab tests not loaded yet.")));
      return;
    }

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image == null) return;

      setState(() => _isScanning = true);

      // 1. Compress Image (Optional but recommended for API limits)
      File fileToScan = File(image.path);
      File? compressed = await ImageCompressor.compressAndGetFile(fileToScan);
      if (compressed != null) fileToScan = compressed;

      // 2. Call AI Service
      final scanner = LabReportScannerService();
      final results = await scanner.extractLabData(fileToScan, _allAvailableTests);

      if (results.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No matching data found in image.")));
      } else {
        // 3. Populate Controllers
        int foundCount = 0;
        results.forEach((testId, value) {
          if (_labControllers.containsKey(testId)) {
            _labControllers[testId]?.text = value.toString();
            foundCount++;
          }
        });
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Auto-filled $foundCount values from report!")));
      }

    } catch (e) {
      debugPrint("Scan Error: $e");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to scan report.")));
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }
  // --- UI COMPONENTS ---

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        // 🎯 FIX 1: Disable scaffold resize because parent BottomSheet handles padding
        resizeToAvoidBottomInset: true,
        backgroundColor: const Color(0xFFF6F8FB),
        body: Column(
          children: [
            _buildPremiumHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  children: [
                    _buildSectionHeader("Body Composition"),
                    _buildAnthroGrid(),
                    const SizedBox(height: 32),

                    _buildSectionHeader("Clinical Vitals"),
                    _buildClinicalContainer(),
                    const SizedBox(height: 32),

                    // Updated Header for Lab Results
                    //_buildLabHeaderWithScan(),

                    _buildSectionHeader("Biochemical Lab Results"),
                    ref.watch(allLabTestsStreamProvider).when(
                      data: (tests) => _buildLabResultsSection(tests),
                      loading: () => const CircularProgressIndicator(),
                      error: (err, stack) => Text("Error: $err"),
                    ),

                    const SizedBox(height: 40),

                    // 🎯 FIX 2: Button moved INSIDE the scroll view
                    // This ensures it doesn't float over the keyboard and block fields
                    if (!widget.isReadOnly)
                      _buildBottomSaveBar(),

                    SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 40),
                  ],
                ),
              ),
            ),
          ],
        ),
        // 🎯 FIX 3: Removed bottomNavigationBar to preavent it from sitting on keyboard
      ),
    );
  }

  Widget _buildBottomSaveBar() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _handleFinalize,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.indigo,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        shadowColor: Colors.indigo.withOpacity(0.4),
      ),
      child: _isLoading
          ? const CircularProgressIndicator(color: Colors.white)
          : const Text("SAVE VITALS & CONTINUE",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
    );
  }

  Widget _buildPremiumHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 24, 20), // Adjusted top padding
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15)],
      ),
      child: Row(
        children: [
          _buildCircleIcon(Icons.arrow_back_ios_new, () => Navigator.pop(context)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.isReadOnly ? "ARCHIVED RECORD" : "VITAL ASSESSMENT",
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.indigo, letterSpacing: 1.2)),
                Text(widget.clientName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1A1C1E))),
              ],
            ),
          ),
          _buildStatusBadge(),
        ],
      ),
    );
  }

  // ... [Keep _buildStatusBadge, _buildAnthroGrid, _buildHeightCard, _buildCmInput, _buildFeetInchesInput, _updateCmFromFtIn, _unitToggle, _buildMetricCard, _buildClinicalContainer, _buildBPRow, _buildLargeBPInput, _buildAnthroCard, _buildCircleIcon, _buildSectionHeader, _buildTrendIndicator, _handleFinalize, _buildIconBox, _buildVitalRow, _buildLabResultsSection, _buildLabProfileGroup exactly as before] ...

  Widget _buildStatusBadge() {
    final bool isArchived = widget.isReadOnly;
    final Color statusColor = isArchived ? Colors.blueGrey : Colors.green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: statusColor.withOpacity(0.2))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(isArchived ? Icons.lock_outline : Icons.sensors_rounded, size: 10, color: statusColor), const SizedBox(width: 4), Text(isArchived ? "LOCKED" : "ACTIVE", style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5))]),
    );
  }

  Widget _buildAnthroGrid() {
    return GridView.count(
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.8,
      children: [
        _buildAnthroCard("Weight", _weightController, "kg", Icons.monitor_weight_outlined, widget.previousVital?.weightKg),
        _buildHeightCard(),
        _buildAnthroCard("Waist", _waistController, "cm", Icons.straighten, widget.previousVital?.waistCm),
        _buildAnthroCard("Hip", _hipController, "cm", Icons.accessibility_new, widget.previousVital?.hipCm),
        _buildMetricCard("Ideal Weight", _idealBodyWeight, "kg", Icons.star_outline, null),
        _buildMetricCard("BMI", _bmiValue, "kg/m²", Icons.shutter_speed_outlined, widget.previousVital?.bmi),
      ],
    );
  }

  Widget _buildHeightCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("HEIGHT", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.blueGrey)), Container(decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.all(2), child: Row(children: [_unitToggle("cm", isCm, () => setState(() => isCm = true)), _unitToggle("ft", !isCm, () => setState(() => isCm = false))]))]), const Spacer(), isCm ? _buildCmInput() : _buildFeetInchesInput()]),
    );
  }

  Widget _buildCmInput() => TextField(controller: _heightController, keyboardType: TextInputType.number, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900), decoration: const InputDecoration(border: InputBorder.none, isDense: true, suffixText: " cm"));

  Widget _buildFeetInchesInput() {
    final feet = (double.tryParse(_heightController.text) ?? 0) / 30.48;
    final ft = feet.floor();
    final inch = ((feet - ft) * 12).round();
    return Row(children: [Expanded(child: TextField(textAlign: TextAlign.center, decoration: const InputDecoration(hintText: "ft", border: InputBorder.none, isDense: true), keyboardType: TextInputType.number, onChanged: (v) => _updateCmFromFtIn(v, null))), const Text("'"), Expanded(child: TextField(textAlign: TextAlign.center, decoration: const InputDecoration(hintText: "in", border: InputBorder.none, isDense: true), keyboardType: TextInputType.number, onChanged: (v) => _updateCmFromFtIn(null, v))), const Text('"')]);
  }

  void _updateCmFromFtIn(String? ftStr, String? inStr) {
    double currentCm = double.tryParse(_heightController.text) ?? 0;
    double ft = (ftStr != null) ? (double.tryParse(ftStr) ?? 0) : (currentCm / 30.48).floorToDouble();
    double inches = (inStr != null) ? (double.tryParse(inStr) ?? 0) : ((currentCm / 30.48) - (currentCm / 30.48).floor()) * 12;
    double totalCm = (ft * 30.48) + (inches * 2.54);
    _heightController.text = totalCm.toStringAsFixed(1);
  }

  Widget _unitToggle(String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: isActive ? Colors.indigo : Colors.transparent, borderRadius: BorderRadius.circular(6)), child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: isActive ? Colors.white : Colors.blueGrey.shade300))));
  }

  Widget _buildMetricCard(String label, double value, String unit, IconData icon, double? prevValue) {
    return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.indigo.withOpacity(0.04), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.indigo.withOpacity(0.1))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.indigo)), _buildTrendIndicator(value, prevValue)]), const Spacer(), Text(value == 0 ? "--" : value.toStringAsFixed(1), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.indigo)), Text(unit, style: const TextStyle(fontSize: 10, color: Colors.indigo, fontWeight: FontWeight.bold))]));
  }

  Widget _buildClinicalContainer() {
    return Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)), child: Column(children: [_buildBPRow(), const Divider(height: 32, thickness: 0.5), _buildVitalRow("Heart Rate", _hrController, "bpm", Icons.monitor_heart_outlined)]));
  }

  Widget _buildBPRow() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("BLOOD PRESSURE (mmHg)", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.blueGrey)), const SizedBox(height: 12), Row(children: [_buildIconBox(Icons.favorite_outline, Colors.redAccent), const SizedBox(width: 16), _buildLargeBPInput(_sysController, "SYS"), const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text("/", style: TextStyle(fontSize: 24, color: Colors.grey, fontWeight: FontWeight.w200))), _buildLargeBPInput(_diaController, "DIA")])]);
  }

  Widget _buildLargeBPInput(TextEditingController controller, String hint) {
    return Container(width: 150, padding: const EdgeInsets.symmetric(vertical: 4), decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)), child: TextField(controller: controller, textAlign: TextAlign.center, keyboardType: TextInputType.number, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: Colors.indigo), decoration: InputDecoration(hintText: hint, border: InputBorder.none, hintStyle: const TextStyle(fontSize: 14, color: Colors.grey))));
  }

  Widget _buildAnthroCard(String label, TextEditingController controller, String unit, IconData icon, double? prev) {
    return Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 0.5)), _buildTrendIndicator((double.tryParse(controller.text) ?? 0), prev)]), const Spacer(), TextField(controller: controller, keyboardType: TextInputType.number, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900), decoration: InputDecoration(border: InputBorder.none, isDense: true, suffixText: " $unit", suffixStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.indigo)))]));
  }

  Widget _buildCircleIcon(IconData icon, VoidCallback onTap) {
    return GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade200)), child: Icon(icon, size: 16, color: Colors.black)));
  }

  Widget _buildSectionHeader(String title) {
    return Padding(padding: const EdgeInsets.only(bottom: 16, left: 4), child: Text(title.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 1.1)));
  }

  Widget _buildTrendIndicator(double current, double? previous) {
    if (previous == null || previous == 0 || current == 0) return const SizedBox.shrink();
    final diff = current - previous;
    final isGood = diff < 0;
    final icon = diff < 0 ? '↓' : '↑';
    return Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: (isGood ? Colors.green : Colors.red).withOpacity(0.1), borderRadius: BorderRadius.circular(4)), child: Text("$icon ${diff.abs().toStringAsFixed(1)}", style: TextStyle(color: isGood ? Colors.green : Colors.red, fontSize: 10, fontWeight: FontWeight.bold)));
  }

  Future<void> _handleFinalize() async {
    if (_weightController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Weight is required to finalize assessment")));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final Map<String, double> labs = {};
      _labControllers.forEach((id, controller) {
        if (controller.text.isNotEmpty) labs[id] = double.tryParse(controller.text) ?? 0.0;
      });

      final data = VitalsModel(
        id: widget.vitalToEdit?.id ?? '',
        clientId: widget.clientId,
        sessionId: widget.sessionId,
        date: DateTime.now(),
        weightKg: double.tryParse(_weightController.text) ?? 0,
        heightCm: double.tryParse(_heightController.text) ?? 0,
        waistCm: double.tryParse(_waistController.text) ?? 0,
        hipCm: double.tryParse(_hipController.text) ?? 0,
        bmi: _bmiValue,
        bloodPressureSystolic: int.tryParse(_sysController.text),
        bloodPressureDiastolic: int.tryParse(_diaController.text),
        heartRate: int.tryParse(_hrController.text),
        labResults: labs, idealBodyWeightKg: 0, bodyFatPercentage: 0, isFirstConsultation: false,
      );

      final vitalsService = ref.read(vitalsServiceProvider);
      final savedVitalId = await vitalsService.saveVitals(data);

      if (widget.sessionId != null) {
        await ref.read(consultationServiceProvider).updateSessionLinks(widget.sessionId!, vitalsId: savedVitalId);

        final firestore = ref.read(firestoreProvider);
        await firestore.collection('consultation_sessions').doc(widget.sessionId).update({
          'steps.vitals': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      widget.onVitalsSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint("Finalize Error: $e");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error saving: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildIconBox(IconData icon, Color color) {
    return Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 20, color: color));
  }

  Widget _buildVitalRow(String l, TextEditingController c, String u, IconData i) {
    return Row(children: [_buildIconBox(i, Colors.indigo), const SizedBox(width: 16), Expanded(child: Text(l, style: const TextStyle(fontWeight: FontWeight.w600))), SizedBox(width: 120, child: TextField(controller: c, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18), decoration: const InputDecoration(border: InputBorder.none, hintText: "--"))), const SizedBox(width: 8), Text(u, style: const TextStyle(fontSize: 11, color: Colors.grey))]);
  }

  Widget _buildLabResultsSection(List<LabTestConfigModel> tests) {
    if (tests.isEmpty) return const Center(child: Text("No configurations found."));
    if (!_isLabControllersInitialized) _initializeLabControllers(tests);
    final grouped = groupBy(tests, (LabTestConfigModel t) => t.category);
    final sortedCategories = grouped.keys.toList()..sort();
    return Column(children: sortedCategories.map((category) {
      final categoryTests = grouped[category]!;
      categoryTests.sort((a, b) => a.displayName.compareTo(b.displayName));
      return _buildLabProfileGroup(category, categoryTests);
    }).toList());
  }

  Widget _buildLabProfileGroup(String category, List<LabTestConfigModel> tests) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Padding(padding: const EdgeInsets.only(top: 24, bottom: 12, left: 4), child: Row(children: [Container(width: 4, height: 16, decoration: BoxDecoration(color: Colors.indigo, borderRadius: BorderRadius.circular(2))), const SizedBox(width: 8), Text(category.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.indigo, letterSpacing: 1))])), ListView.separated(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: tests.length, separatorBuilder: (_, __) => const SizedBox(height: 8), itemBuilder: (context, index) { final test = tests[index]; final controller = _labControllers[test.id]; return Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(test.displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), Text(test.unit, style: const TextStyle(fontSize: 11, color: Colors.grey))])), SizedBox(width: 200, child: TextField(controller: controller, textAlign: TextAlign.right, keyboardType: TextInputType.number, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.indigo, fontSize: 16), decoration: const InputDecoration(border: InputBorder.none, hintText: "-", isDense: true)))])); })]);
  }
}