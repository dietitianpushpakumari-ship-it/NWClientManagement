// lib/widgets/feature_config_form.dart
import 'package:flutter/material.dart';
import '../models/feature_config_model.dart';
import '../services/config_service.dart';

// Helper to convert title to a safe ID slug (e.g., "Vitals Tracking" -> "vitals_tracking")
String _slugify(String title) {
  return title.toLowerCase().replaceAll(RegExp(r'\s+'), '_').replaceAll(RegExp(r'[^\w_]+'), '');
}

class FeatureConfigForm extends StatefulWidget {
  final FeatureConfigModel? featureToEdit;
  const FeatureConfigForm({super.key, this.featureToEdit});

  @override
  State<FeatureConfigForm> createState() => _FeatureConfigFormState();
}

class _FeatureConfigFormState extends State<FeatureConfigForm> {
  final _formKey = GlobalKey<FormState>();
  late String _title;
  late String _description;
  late String _section;
  late FeatureScope _scope;
  late bool _isEnabled;

  @override
  void initState() {
    super.initState();
    final feature = widget.featureToEdit;
    _title = feature?.title ?? '';
    _description = feature?.description ?? '';
    _section = feature?.section ?? 'Client Facing Features';
    _scope = feature?.scope ?? FeatureScope.global;
    _isEnabled = feature?.isEnabled ?? true;
  }

  Future<void> _saveFeature() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final service = ConfigService();
    final featureId = widget.featureToEdit?.id ?? _slugify(_title);

    final newFeature = FeatureConfigModel(
      id: featureId,
      title: _title,
      description: _description,
      section: _section,
      scope: _scope,
      isEnabled: _isEnabled,
    );

    try {
      if (widget.featureToEdit == null) {
        await service.addFeature(newFeature);
      } else {
        await service.editFeature(newFeature);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving feature: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.featureToEdit == null ? 'Add New Feature' : 'Edit Feature'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: _title,
                decoration: const InputDecoration(labelText: 'Title (e.g., Vitals Tracking)'),
                validator: (value) => value!.isEmpty ? 'Title is required.' : null,
                onSaved: (value) => _title = value!,
                enabled: widget.featureToEdit == null, // Prevent editing ID/Title for existing features
              ),
              TextFormField(
                initialValue: _description,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (value) => value!.isEmpty ? 'Description is required.' : null,
                onSaved: (value) => _description = value!,
              ),
              TextFormField(
                initialValue: _section,
                decoration: const InputDecoration(labelText: 'Section (e.g., Client Facing Features)'),
                validator: (value) => value!.isEmpty ? 'Section is required.' : null,
                onSaved: (value) => _section = value!,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<FeatureScope>(
                value: _scope,
                decoration: const InputDecoration(labelText: 'Scope'),
                items: FeatureScope.values.map((scope) {
                  return DropdownMenuItem(
                    value: scope,
                    child: Text(scope.toString().split('.').last.toUpperCase()),
                  );
                }).toList(),
                onChanged: (FeatureScope? newValue) {
                  setState(() {
                    _scope = newValue!;
                  });
                },
                validator: (value) => value == null ? 'Scope is required.' : null,
              ),
              ListTile(
                title: const Text('Is Enabled (Master Switch)'),
                trailing: Switch(
                  value: _isEnabled,
                  onChanged: (value) {
                    setState(() {
                      _isEnabled = value;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveFeature,
          child: const Text('Save'),
        ),
      ],
    );
  }
}