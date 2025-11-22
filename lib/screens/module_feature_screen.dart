// lib/screens/module_feature_screen.dart
import 'package:flutter/material.dart';
import 'package:nutricare_client_management/models/feature_config_model.dart';
import 'package:nutricare_client_management/helper/config_service.dart';
import 'package:nutricare_client_management/admin/custom_gradient_app_bar.dart';



class ModuleFeatureScreen extends StatelessWidget {
  const ModuleFeatureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ConfigService configService = ConfigService();
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: CustomGradientAppBar(
        title: const Text('Module Feature Toggles'),
      ),
      body: SafeArea(
        child: StreamBuilder<Map<String, List<FeatureConfigModel>>>(
          stream: configService.streamAllFeatures(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error loading features: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No feature modules defined.'));
            }

            final groupedFeatures = snapshot.data!;
            final sections = groupedFeatures.keys.toList();

            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: sections.length,
              itemBuilder: (context, sectionIndex) {
                final section = sections[sectionIndex];
                final features = groupedFeatures[section]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Section Header ---
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                      child: Text(
                        section,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                    const Divider(height: 1),

                    // --- Feature List ---
                    ...features.map((feature) {
                      return _buildFeatureTile(service: configService, feature: feature, context: context);
                    }).toList(),

                    if (sectionIndex < sections.length - 1)
                      const SizedBox(height: 16),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildFeatureTile({required BuildContext context, required ConfigService service, required FeatureConfigModel feature}) {
    // Determine icon and color based on scope
    final IconData scopeIcon = feature.scope == FeatureScope.global ? Icons.public : Icons.person;
    final String scopeText = feature.scope == FeatureScope.global ? 'Global' : 'Client-Specific';
    final Color scopeColor = feature.scope == FeatureScope.global ? Colors.purple : Colors.teal;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
        leading: Icon(scopeIcon, color: scopeColor),
        title: Text(
          feature.title,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(feature.description),
            Text(
              'Scope: $scopeText',
              style: TextStyle(fontSize: 11, color: scopeColor, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        trailing: Switch(
          value: feature.isEnabled,
          onChanged: (bool newValue) {
            // Update the status in Firestore
            service.updateFeatureStatus(feature.id, newValue);
          },
          activeColor: Colors.green,
        ),
      ),
    );
  }
}