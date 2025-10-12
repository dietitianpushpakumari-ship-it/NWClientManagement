// lib/screens/serving_unit_entry_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/serving_unit.dart';
import '../../config/language_config.dart'; // Your provided language map
// import '../../services/serving_unit_service.dart'; // Your service

class ServingUnitEntryPage extends StatefulWidget {
  final ServingUnit? unitToEdit; // Null for Add, Not Null for Edit

  const ServingUnitEntryPage({super.key, this.unitToEdit});

  @override
  State<ServingUnitEntryPage> createState() => _ServingUnitEntryPageState();
}

class _ServingUnitEntryPageState extends State<ServingUnitEntryPage> {
  final _formKey = GlobalKey<FormState>();
  final _enNameController = TextEditingController();
  final _abbreviationController = TextEditingController();
  String? _baseUnit; // 'mass' or 'volume'
  Map<String, TextEditingController> _localizedControllers = {};

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeLocalizedControllers();
    if (widget.unitToEdit != null) {
      _initializeForEdit(widget.unitToEdit!);
    }
  }

  void _initializeLocalizedControllers() {
    // Create controllers for every supported language code
    for (var code in supportedLanguageCodes) {
      _localizedControllers[code] = TextEditingController();
    }
  }

  void _initializeForEdit(ServingUnit unit) {
    _enNameController.text = unit.enName;
    _abbreviationController.text = unit.abbreviation;
    _baseUnit = unit.baseUnit.isEmpty ? null : unit.baseUnit;

    // Load localized names into their respective controllers
    unit.nameLocalized.forEach((code, name) {
      if (_localizedControllers.containsKey(code)) {
        _localizedControllers[code]!.text = name;
      }
    });
  }

  @override
  void dispose() {
    _enNameController.dispose();
    _abbreviationController.dispose();
    _localizedControllers.values.forEach((c) => c.dispose());
    super.dispose();
  }

  // --- SAVE LOGIC ---
  Future<void> _saveUnit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_baseUnit == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a Base Unit.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // 1. Collect Localized Strings
    final Map<String, String> localizedNames = {};
    _localizedControllers.forEach((code, controller) {
      final text = controller.text.trim();
      if (text.isNotEmpty) {
        localizedNames[code] = text;
      }
    });

    // 2. Create the new/updated object
    final newUnit = ServingUnit(
      id: widget.unitToEdit?.id ?? '', // Use existing ID or '' for new
      enName: _enNameController.text.trim(),
      abbreviation: _abbreviationController.text.trim(),
      baseUnit: _baseUnit!,
      nameLocalized: localizedNames,
      isDeleted: widget.unitToEdit?.isDeleted ?? false,
    );

    try {
      // 🎯 Call your service method here
      // final unitService = Provider.of<ServingUnitService>(context, listen: false);
      // if (widget.unitToEdit == null) {
      //   await unitService.addUnit(newUnit);
      // } else {
      //   await unitService.updateUnit(newUnit);
      // }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${newUnit.enName} saved successfully!'),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving unit: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- UI BUILDING ---
  @override
  Widget build(BuildContext context) {
    final bool isEdit = widget.unitToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Serving Unit' : 'Add Serving Unit'),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView( // Always ensure the form is scrollable
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Core Fields ---
              TextFormField(
                controller: _enNameController,
                decoration: const InputDecoration(
                  labelText: 'Name (English) *',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Gram',
                ),
                validator: (value) => value!.isEmpty ? 'English Name is required' : null,
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _abbreviationController,
                decoration: const InputDecoration(
                  labelText: 'Abbreviation/Symbol *',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., g',
                ),
                validator: (value) => value!.isEmpty ? 'Abbreviation is required' : null,
              ),
              const SizedBox(height: 15),

              // --- Base Unit Dropdown ---
              DropdownButtonFormField<String>(
                value: _baseUnit,
                decoration: const InputDecoration(
                  labelText: 'Base Unit Type *',
                  border: OutlineInputBorder(),
                  hintText: 'Select physical type (Mass/Volume)',
                ),
                items: const [
                  DropdownMenuItem(value: 'mass', child: Text('Mass (e.g., g, oz)')),
                  DropdownMenuItem(value: 'volume', child: Text('Volume (e.g., ml, cup)')),
                ],
                onChanged: (value) {
                  setState(() => _baseUnit = value);
                },
              ),
              const SizedBox(height: 30),

              // --- Localization Section ---
              Text(
                'Localization (Optional Translations)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey.shade700,
                ),
              ),
              const Divider(),

              // Loop through all supported languages to generate fields
              ...supportedLanguageCodes.map((code) {
                final languageName = supportedLanguages[code]!;
                // Skip English since it's the core field
                if (code == 'en') return const SizedBox.shrink();

                return Padding(
                  padding: const EdgeInsets.only(bottom: 15.0),
                  child: TextFormField(
                    controller: _localizedControllers[code],
                    decoration: InputDecoration(
                      labelText: 'Name ($languageName)',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.translate),
                    ),
                  ),
                );
              }).toList(),

              const SizedBox(height: 40),

              // --- Save Button ---
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveUnit,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(isEdit ? 'Update Unit' : 'Save Unit'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}