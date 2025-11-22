// lib/screens/feature_config_master_screen.dart
import 'package:flutter/material.dart';
import 'package:nutricare_client_management/screens/feature_config_form.dart';
import '../helper/config_service.dart';
import '../models/feature_config_model.dart';
import 'package:nutricare_client_management/admin/custom_gradient_app_bar.dart';


class FeatureConfigMasterScreen extends StatelessWidget {
   FeatureConfigMasterScreen({super.key});

  final ConfigService _configService =  ConfigService();

  // Helper to show the Add/Edit Dialog
  void _showFeatureForm(BuildContext context, {FeatureConfigModel? feature}) {
    showDialog(
      context: context,
      builder: (ctx) => FeatureConfigForm(featureToEdit: feature),
    );
  }

  // Helper to confirm and delete a feature
  Future<void> _deleteFeature(BuildContext context, FeatureConfigModel feature) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Are you sure you want to permanently delete the feature: ${feature.title}?'),
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
        await _configService.deleteFeature(feature.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Feature deleted successfully.')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete feature: ${e.toString()}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: CustomGradientAppBar(
          title: const Text('Feature Configuration Master'),
        ),
        body: StreamBuilder<Map<String, List<FeatureConfigModel>>>(
          // Stream grouped by SCOPE now
          stream: _configService.streamAllFeatures(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error loading features: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No feature configurations found.'));
            }
      
            final groupedFeatures = snapshot.data!;
            final scopes = groupedFeatures.keys.toList();
      
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: scopes.length,
              itemBuilder: (context, scopeIndex) {
                final scope = scopes[scopeIndex];
                final features = groupedFeatures[scope]!;
      
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Scope Header ---
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                      child: Text(
                        '${scope.toUpperCase()} SCOPE FEATURES',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: scope == 'global' ? Colors.purple : Colors.teal,
                        ),
                      ),
                    ),
                    const Divider(height: 1),
      
                    // --- Feature List ---
                    ...features.map((feature) {
                      return _buildFeatureListTile(context, feature);
                    }).toList(),
      
                    if (scopeIndex < scopes.length - 1)
                      const SizedBox(height: 16),
                  ],
                );
              },
            );
          },
        ),
        // Floating Action Button for Adding New Feature
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showFeatureForm(context),
          backgroundColor: Colors.indigo,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildFeatureListTile(BuildContext context, FeatureConfigModel feature) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Text(feature.title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text('Section: ${feature.section} | Status: ${feature.isEnabled ? 'Active' : 'Inactive'}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Edit Button
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _showFeatureForm(context, feature: feature),
            ),
            // Delete Button
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteFeature(context, feature),
            ),
          ],
        ),
      ),
    );
  }
}