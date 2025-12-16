import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutricare_client_management/admin/labvital/global_service_provider.dart';
import 'package:nutricare_client_management/models/programme_feature_model.dart';
import 'package:nutricare_client_management/modules/package/service/program_feature_service.dart';
import 'package:nutricare_client_management/screens/dash/program_feature_entry_form.dart';

class ProgramFeatureMasterScreen extends ConsumerStatefulWidget {
  const ProgramFeatureMasterScreen({super.key});

  @override
  ConsumerState<ProgramFeatureMasterScreen> createState() => _ProgramFeatureMasterScreenState();
}

class _ProgramFeatureMasterScreenState extends ConsumerState<ProgramFeatureMasterScreen> {


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProgramFeatureEntryForm())),
        backgroundColor: Theme.of(context).colorScheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("New Feature", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Stack(
        children: [
          // 1. Ambient Glow
          Positioned(top: -100, right: -100, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.1), blurRadius: 80, spreadRadius: 30)]))),

          Column(
            children: [
              // 2. 🎯 ULTRA PREMIUM HEADER (Glassmorphism)
              _buildCustomHeader(context, "Program Features"),

              // 3. Content List
              Expanded(
                child: StreamBuilder<List<ProgramFeatureModel>>(
                  // 🎯 Riverpod access remains correct
                  stream: ref.watch(programFeatureServiceProvider).streamAllFeatures(),
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
                        return _buildFeatureCard(context, feature); // Use helper for card design
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 🎯 NEW: CUSTOM HEADER IMPLEMENTATION (Replaces old _buildHeader)
  Widget _buildCustomHeader(BuildContext context, String title) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 20, // Account for notch
            bottom: 20,
            left: 20,
            right: 20,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1))),
          ),
          child: Row(
            children: [
              // Back Button
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
                  child: const Icon(Icons.arrow_back, size: 20, color: Colors.black87),
                ),
              ),
              const SizedBox(width: 16),
              // Title
              Expanded(child: Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)))),
              // Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.purple.withOpacity(.1), shape: BoxShape.circle),
                child: const Icon(Icons.star_outline, color: Colors.purple),
              )
            ],
          ),
        ),
      ),
    );
  }

  // 🎯 NEW: REFACTORED LIST ITEM CARD
  Widget _buildFeatureCard(BuildContext context, ProgramFeatureModel feature) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))],
          // Left border to show category
          border: Border(left: BorderSide(color: feature.featureType == 'Dietary' ? Colors.teal : (feature.featureType == 'Workout' ? Colors.orange : Colors.blue), width: 4))
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.star, color: Colors.purple, size: 24),
        ),
        title: Text(feature.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(feature.description.isEmpty ? feature.featureType : feature.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        trailing: IconButton(
          icon: Icon(Icons.edit_outlined, color: Theme.of(context).colorScheme.primary),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProgramFeatureEntryForm(featureToEdit: feature))),
        ),
      ),
    );
  }
}