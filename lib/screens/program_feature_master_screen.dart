import 'package:flutter/material.dart';
import 'package:nutricare_client_management/models/programme_feature_model.dart';
import '../modules/package/service/program_feature_service.dart';
import 'package:nutricare_client_management/admin/custom_gradient_app_bar.dart';

// Helper to define feature types
const List<String> _featureTypes = ['Dietary', 'Workout', 'Support', 'Tracking', 'Other'];

class ProgramFeatureMasterScreen extends StatelessWidget {
  const ProgramFeatureMasterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = ProgramFeatureService();
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: CustomGradientAppBar(
        title: const Text('Program Features Master'),
      ),
      body: SafeArea(
        child: StreamBuilder<List<ProgramFeatureModel>>(
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
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star_border_rounded, size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    const Text(
                      'No program features defined.',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => _showFeatureForm(context),
                      icon: const Icon(Icons.add),
                      label: const Text("Create First Feature"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 80, top: 10),
              itemCount: features.length,
              itemBuilder: (context, index) {
                return _buildFeatureCard(context, features[index]);
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFeatureForm(context),
        backgroundColor: colorScheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("New Feature", style: TextStyle(color: Colors.white)),
      ),
    );
  }

  // 🎯 REVAMPED CARD WIDGET
  Widget _buildFeatureCard(BuildContext context, ProgramFeatureModel feature) {
    final bool isActive = feature.isActive;
    final Color statusColor = isActive ? Colors.green.shade700 : Colors.grey.shade600;
    final Color lightStatusColor = isActive ? Colors.green.shade50 : Colors.grey.shade100;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isActive ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER: Icon, Name, Status ---
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: lightStatusColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isActive ? Icons.check_circle_rounded : Icons.remove_circle_outline,
                    color: statusColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feature.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: lightStatusColor,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: statusColor.withOpacity(0.3), width: 0.5),
                        ),
                        child: Text(
                          isActive ? 'ACTIVE' : 'INACTIVE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // --- BODY: Description ---
            if (feature.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Text(
                  feature.description,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.only(bottom: 12.0),
                child: Text(
                  "No description provided.",
                  style: TextStyle(fontSize: 13, color: Colors.grey, fontStyle: FontStyle.italic),
                ),
              ),

            // --- FOOTER: Type Chip & Actions ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Type Chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Text(
                    feature.featureType,
                    style: TextStyle(
                      color: Colors.blue.shade800,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                // Action Buttons
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Colors.indigo, size: 22),
                      tooltip: 'Edit Feature',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _showFeatureForm(context, feature),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
                      tooltip: 'Delete Feature',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _confirmDelete(context, feature),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
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
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
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
                decoration: const InputDecoration(
                  labelText: 'Feature Name',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) => value!.isEmpty ? 'Name is required.' : null,
                onSaved: (value) => _name = value!,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _description,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onSaved: (value) => _description = value!,
                minLines: 2,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _featureType,
                decoration: const InputDecoration(
                  labelText: 'Feature Type',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: _featureTypes.map((type) =>
                    DropdownMenuItem(value: type, child: Text(type))
                ).toList(),
                onChanged: (newValue) => setState(() => _featureType = newValue!),
                onSaved: (value) => _featureType = value!,
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                title: const Text('Set as Active'),
                subtitle: const Text('Feature will be visible in packages'),
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel')
        ),
        ElevatedButton(
            onPressed: _saveForm,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
            child: const Text('Save')
        ),
      ],
    );
  }
}