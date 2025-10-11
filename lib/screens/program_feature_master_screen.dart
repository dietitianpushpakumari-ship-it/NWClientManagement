// lib/screens/program_feature_master_screen.dart
import 'package:flutter/material.dart';
import 'package:nutricare_client_management/models/programme_feature_model.dart';
import '../services/program_feature_service.dart';

// Helper to define feature types
const List<String> _featureTypes = ['Dietary', 'Workout', 'Support', 'Tracking'];

class ProgramFeatureMasterScreen extends StatelessWidget {
  const ProgramFeatureMasterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = ProgramFeatureService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Program Features Master'),
        backgroundColor: Colors.blueAccent,
      ),
      body: StreamBuilder<List<ProgramFeatureModel>>(
        stream: service.streamAllFeatures(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final features = snapshot.data ?? [];

          if (features.isEmpty) {
            return const Center(child: Text('No program features defined.'));
          }

          return ListView.builder(
            itemCount: features.length,
            itemBuilder: (context, index) {
              final feature = features[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                elevation: 2,
                child: ListTile(
                  leading: Icon(feature.isActive ? Icons.check_circle : Icons.remove_circle,
                      color: feature.isActive ? Colors.green : Colors.red),
                  title: Text(feature.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${feature.featureType} | ${feature.description}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showFeatureForm(context, feature),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(context, feature),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFeatureForm(context),
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showFeatureForm(BuildContext context, [ProgramFeatureModel? feature]) {
    showDialog(
      context: context,
      builder: (ctx) => _FeatureForm(featureToEdit: feature),
    );
  }

  Future<void> _confirmDelete(BuildContext context, ProgramFeatureModel feature) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Delete "${feature.name}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await ProgramFeatureService().deleteFeature(feature.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Feature deleted.')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete: ${e.toString()}')),
          );
        }
      }
    }
  }
}

// --- Feature Form Dialog Widget ---
class _FeatureForm extends StatefulWidget {
  final ProgramFeatureModel? featureToEdit;
  const _FeatureForm({this.featureToEdit});

  @override
  State<_FeatureForm> createState() => _FeatureFormState();
}

class _FeatureFormState extends State<_FeatureForm> {
  final _formKey = GlobalKey<FormState>();
  final ProgramFeatureService _service = ProgramFeatureService();
  late String _name;
  late String _description;
  late String _featureType;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    final feature = widget.featureToEdit;
    _name = feature?.name ?? '';
    _description = feature?.description ?? '';
    _featureType = feature?.featureType ?? _featureTypes.first;
    _isActive = feature?.isActive ?? true;
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final newFeature = ProgramFeatureModel(
      // ID is required for edit, new feature will get ID from Firestore add()
      id: widget.featureToEdit?.id ?? '',
      name: _name,
      description: _description,
      featureType: _featureType,
      isActive: _isActive,
    );

    try {
      if (widget.featureToEdit == null) {
        await _service.addFeature(newFeature);
      } else {
        await _service.editFeature(newFeature);
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
      title: Text(widget.featureToEdit == null ? 'Add Program Feature' : 'Edit Program Feature'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: _name,
                decoration: const InputDecoration(labelText: 'Feature Name'),
                validator: (value) => value!.isEmpty ? 'Name is required.' : null,
                onSaved: (value) => _name = value!,
              ),
              TextFormField(
                initialValue: _description,
                decoration: const InputDecoration(labelText: 'Description'),
                onSaved: (value) => _description = value!,
                minLines: 1,
                maxLines: 3,
              ),
              DropdownButtonFormField<String>(
                value: _featureType,
                decoration: const InputDecoration(labelText: 'Feature Type'),
                items: _featureTypes.map((type) =>
                    DropdownMenuItem(value: type, child: Text(type))
                ).toList(),
                onChanged: (newValue) => setState(() => _featureType = newValue!),
                onSaved: (value) => _featureType = value!,
              ),
              ListTile(
                title: const Text('Is Active'),
                trailing: Switch(
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton(onPressed: _saveForm, child: const Text('Save')),
      ],
    );
  }
}