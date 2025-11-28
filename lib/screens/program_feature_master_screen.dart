import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:nutricare_client_management/models/programme_feature_model.dart';
import 'package:nutricare_client_management/modules/package/service/program_feature_service.dart';
import 'package:nutricare_client_management/screens/dash/program_feature_entry_form.dart';

class ProgramFeatureMasterScreen extends StatefulWidget {
  const ProgramFeatureMasterScreen({super.key});

  @override
  State<ProgramFeatureMasterScreen> createState() => _ProgramFeatureMasterScreenState();
}

class _ProgramFeatureMasterScreenState extends State<ProgramFeatureMasterScreen> {
  final ProgramFeatureService _service = ProgramFeatureService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      floatingActionButton: FloatingActionButton.extended(
        // 🎯 UPDATED: Opens ProgramFeatureEntryForm
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProgramFeatureEntryForm())),
        backgroundColor: Theme.of(context).colorScheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("New Feature", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Stack(
        children: [
          Positioned(top: -100, right: -100, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.1), blurRadius: 80, spreadRadius: 30)]))),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, "Program Features"),
                Expanded(
                  child: StreamBuilder<List<ProgramFeatureModel>>(
                    stream: _service.streamAllFeatures(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                      final features = snapshot.data ?? [];
                      if (features.isEmpty) return const Center(child: Text("No features defined."));

                      return ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: features.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final feature = features[index];
                          return Container(
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(12)),
                                child: const Icon(Icons.star, color: Colors.amber, size: 24),
                              ),
                              title: Text(feature.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              subtitle: Text(feature.description, maxLines: 1, overflow: TextOverflow.ellipsis),
                              trailing: IconButton(
                                icon: Icon(Icons.edit_outlined, color: Theme.of(context).colorScheme.primary),
                                // 🎯 UPDATED: Passes ProgramFeatureModel to the correct form
                                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProgramFeatureEntryForm(featureToEdit: feature))),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]), child: const Icon(Icons.arrow_back, size: 20)),
          ),
          const SizedBox(width: 16),
          Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
        ],
      ),
    );
  }
}