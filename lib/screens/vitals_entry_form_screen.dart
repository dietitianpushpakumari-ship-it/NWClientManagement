import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:nutricare_client_management/helper/lab_vitals_data.dart';

import '../../models/vitals_model.dart';
import '../../services/vitals_service.dart';
 // Uses the new data

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
  final _weightController = TextEditingController();
  final _bfpController = TextEditingController();
  final _notesController = TextEditingController();

  // Initialize controllers for ALL defined lab tests
  final Map<String, TextEditingController> _labControllers =
  Map.fromIterable(LabVitalsData.allLabTests.keys,
      key: (key) => key,
      value: (_) => TextEditingController());

  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.vitalsToEdit != null) {
      _initializeForEdit(widget.vitalsToEdit!);
    }
  }

  void _initializeForEdit(VitalsModel vitals) {
    _selectedDate = vitals.date;
    _weightController.text = vitals.weightKg.toString();
    _bfpController.text = vitals.bodyFatPercentage == 0.0 ? '' : vitals.bodyFatPercentage.toString();
    _notesController.text = vitals.notes ?? '';

    // Load existing lab results into the new, expanded controllers
    vitals.labResults.forEach((key, value) {
      if (_labControllers.containsKey(key)) {
        _labControllers[key]!.text = value;
      }
    });
  }

  @override
  void dispose() {
    _weightController.dispose();
    _bfpController.dispose();
    _notesController.dispose();
    _labControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveVitals() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    VitalsService vitalsService = VitalsService();

    final double weight = double.tryParse(_weightController.text) ?? 0.0;
    final double bfp = double.tryParse(_bfpController.text) ?? 0.0;

    // Filter out empty lab results before saving
    final Map<String, String> labResults = Map.fromEntries(
        _labControllers.entries.map((entry) {
          return MapEntry(entry.key, entry.value.text.trim());
        }).where((entry) => entry.value.isNotEmpty)
    );

    final recordId = widget.vitalsToEdit?.id ?? '';

    final vitals = VitalsModel(
      id: recordId,
      clientId: widget.clientId,
      date: _selectedDate,
      weightKg: weight,
      bodyFatPercentage: bfp,
      measurements: {},
      labResults: labResults,
      notes: _notesController.text.trim(),
    );

    try {
      if (widget.vitalsToEdit != null) {
        await vitalsService.updateVitals(vitals);
      } else {
        await vitalsService.addVitals(vitals);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Vitals ${widget.vitalsToEdit != null ? 'updated' : 'saved'} successfully!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save vitals: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // UPDATE: Now takes a LabTest object to display reference value
  Widget _buildLabInput(LabTest test) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _labControllers[test.key],
          keyboardType: TextInputType.text,
          // Allow number and some punctuation (for units like /)
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d.,/-]')),
          ],
          decoration: InputDecoration(
            labelText: '${test.displayName} (${test.unit})',
            isDense: true,
            border: const OutlineInputBorder(),
          ),
        ),
        // Display Reference Range
        if (test.referenceRange.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4.0, left: 2.0),
            child: Text('Ref: ${test.referenceRange} ${test.unit}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          ),
      ],
    );
  }

  // Builds the grouped lab cards dynamically based on LabVitalsData
  Widget _buildGroupedLabCards() {
    return Column(
      children: LabVitalsData.labTestGroups.entries.map((entry) {
        final groupName = entry.key;
        final testKeys = entry.value;

        final tests = testKeys.map((key) => LabVitalsData.allLabTests[key]).whereType<LabTest>().toList();

        if (tests.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(bottom: 20.0), // Spacing between groups
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(title: groupName, icon: LabVitalsData.groupIcons[groupName] ?? Icons.science),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 15,
                      childAspectRatio: 2.5, // Adjusted to fit reference text
                    ),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: tests.length,
                    itemBuilder: (context, index) {
                      return _buildLabInput(tests[index]);
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.vitalsToEdit != null ? 'Edit' : 'Enter'} Vitals for ${widget.clientName}'),
        backgroundColor: Colors.indigo,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveVitals,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Date Picker ---
              Card(
                elevation: 2,
                child: ListTile(
                  leading: const Icon(Icons.calendar_today, color: Colors.indigo),
                  title: Text(
                    'Record Date: ${DateFormat.yMMMd().format(_selectedDate)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _selectDate(context),
                ),
              ),
              const SizedBox(height: 20),

              // --- Physical Vitals ---
              const _SectionHeader(title: 'Physical Measurements', icon: Icons.straighten),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _weightController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                        decoration: const InputDecoration(
                          labelText: 'Weight (kg)',
                          border: OutlineInputBorder(),
                          suffixText: 'kg',
                        ),
                        validator: (value) => value == null || value.isEmpty ? 'Weight is required' : null,
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _bfpController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                        decoration: const InputDecoration(
                          labelText: 'Body Fat Percentage (Optional)',
                          border: OutlineInputBorder(),
                          suffixText: '%',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // --- Lab Vitals Grouped Cards ---
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
            ],
          ),
        ),
      ),
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