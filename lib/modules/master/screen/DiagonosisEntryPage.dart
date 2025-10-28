// lib/screens/serving_unit_entry_page.dart

import 'package:flutter/material.dart';
import 'package:nutricare_client_management/helper/language_config.dart';
import 'package:nutricare_client_management/modules/master/service/diagonosis_master_service.dart';
import 'package:provider/provider.dart';

import '../model/diagonosis_master.dart';



class DiagnosisEntryPage extends StatefulWidget {
  final DiagnosisMasterModel? diagnosisToEdit; // Null for Add, Not Null for Edit

  const DiagnosisEntryPage({super.key, this.diagnosisToEdit});

  @override
  State<DiagnosisEntryPage> createState() => _DiagnosisEntryPageState();
}

class _DiagnosisEntryPageState extends State<DiagnosisEntryPage> {
  final _formKey = GlobalKey<FormState>();
  final _enNameController = TextEditingController();

  // Controllers for all non-English supported languages
  final Map<String, TextEditingController> _localizedControllers = {};

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeLocalizedControllers();
    if (widget.diagnosisToEdit != null) {
      _initializeForEdit(widget.diagnosisToEdit!);
    }
  }

  void _initializeLocalizedControllers() {
    for (var code in supportedLanguageCodes) {
      if (code != 'en') {
        _localizedControllers[code] = TextEditingController();
      }
    }
  }

  void _initializeForEdit(DiagnosisMasterModel diagnosis) {
    _enNameController.text = diagnosis.enName;
    // Load existing translations
    diagnosis.nameLocalized.forEach((code, name) {
      if (_localizedControllers.containsKey(code)) {
        _localizedControllers[code]!.text = name;
      }
    });
  }

  @override
  void dispose() {
    _enNameController.dispose();
    _localizedControllers.values.forEach((c) => c.dispose());
    super.dispose();
  }

  // --- SAVE LOGIC ---
  Future<void> _saveDiagnoses() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final diagnosisService = Provider.of<DiagnosisMasterService>(context, listen: false);

    // 1. Collect Localized Strings
    final Map<String, String> localizedNames = {};
    _localizedControllers.forEach((code, controller) {
      final text = controller.text.trim();
      if (text.isNotEmpty) {
        localizedNames[code] = text;
      }
    });

    // 2. Create the new/updated object
    final unitToSave = DiagnosisMasterModel(
      id: widget.diagnosisToEdit?.id ?? '',
      enName: _enNameController.text.trim(),

      nameLocalized: localizedNames,
      isDeleted: widget.diagnosisToEdit?.isDeleted ?? false,
    );

    try {
      await diagnosisService.addOrUpdateDiagnosis(unitToSave);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${unitToSave.enName} saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving unit: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- UI BUILDING ---
  @override
  Widget build(BuildContext context) {
    final bool isEdit = widget.diagnosisToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Diagnoses' : 'Add New Diagnoses'),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
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
                  hintText: 'e.g., Diabetes',
                ),
                validator: (value) => value!.isEmpty ? 'English Name is required' : null,
              ),
              const SizedBox(height: 15),


              // --- Localization Section Header ---
              Text(
                'Translations',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade700,
                ),
              ),
              const Divider(),

              // --- Localization Fields ---
              // Loop through all supported languages to generate fields
              ...supportedLanguageCodes.map((code) {
                // Skip English since it's the core field
                if (code == 'en') return const SizedBox.shrink();

                final languageName = supportedLanguages[code]!;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 15.0),
                  child: TextFormField(
                    controller: _localizedControllers[code],
                    decoration: InputDecoration(
                      labelText: 'Name ($languageName)',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.translate),
                      hintText: 'Enter the translation in $languageName',
                    ),
                  ),
                );
              }).toList(),

              const SizedBox(height: 40),

              // --- Save Button ---
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveDiagnoses,
                icon: _isLoading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
                    : const Icon(Icons.save),
                label: Text(isEdit ? 'Update Diagnosis' : 'Save Diagnosis'),
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