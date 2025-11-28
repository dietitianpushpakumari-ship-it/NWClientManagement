import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nutricare_client_management/models/programme_feature_model.dart';
import 'package:nutricare_client_management/modules/package/service/program_feature_service.dart';

class ProgramFeatureEntryForm extends StatefulWidget {
  final ProgramFeatureModel? featureToEdit;

  const ProgramFeatureEntryForm({super.key, this.featureToEdit});

  @override
  State<ProgramFeatureEntryForm> createState() => _ProgramFeatureEntryFormState();
}

class _ProgramFeatureEntryFormState extends State<ProgramFeatureEntryForm> {
  final _formKey = GlobalKey<FormState>();
  final ProgramFeatureService _service = ProgramFeatureService();

  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  String _featureType = 'Dietary';
  bool _isActive = true;
  bool _isSaving = false;

  final List<String> _types = ['Dietary', 'Workout', 'Consultation', 'Support', 'Other'];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.featureToEdit?.name ?? '');
    _descCtrl = TextEditingController(text: widget.featureToEdit?.description ?? '');
    _featureType = widget.featureToEdit?.featureType ?? 'Dietary';
    _isActive = widget.featureToEdit?.isActive ?? true;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final newFeature = ProgramFeatureModel(
        id: widget.featureToEdit?.id ?? '', // Service handles ID generation if empty
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        featureType: _featureType,
        isActive: _isActive,
      );

      // Assuming your service has a save/update method.
      // If not, we use direct Firestore here as fallback or you can add saveFeature to your service.
      if (widget.featureToEdit == null) {
        await FirebaseFirestore.instance.collection('program_features').add(newFeature.toMap());
      } else {
        await FirebaseFirestore.instance.collection('program_features').doc(newFeature.id).update(newFeature.toMap());
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Feature saved successfully!")));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.featureToEdit == null ? "New Program Feature" : "Edit Feature"),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField("Feature Name", _nameCtrl, "e.g., Weekly Diet Plan"),
              const SizedBox(height: 16),
              _buildTextField("Description", _descCtrl, "Short description of what this feature provides", maxLines: 3),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _types.contains(_featureType) ? _featureType : _types.first,
                decoration: InputDecoration(
                  labelText: "Feature Category",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setState(() => _featureType = v!),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text("Active Status"),
                subtitle: Text(_isActive ? "Visible in packages" : "Hidden"),
                value: _isActive,
                activeColor: Colors.green,
                onChanged: (v) => setState(() => _isActive = v),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("SAVE FEATURE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl, String hint, {int maxLines = 1}) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      validator: (v) => v!.trim().isEmpty ? "Required" : null,
    );
  }
}