import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutricare_client_management/master/model/ServingUnit.dart';
import 'package:nutricare_client_management/master/screen/serving_unit_entry_page.dart';
import 'package:nutricare_client_management/modules/master/service/serving_unit_service.dart';
import 'package:nutricare_client_management/admin/labvital/global_service_provider.dart';


class ServingUnitListPage extends ConsumerWidget {
  const ServingUnitListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FE),
        body: Stack(
          children: [
            Positioned(top: -100, right: -100, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.pink.withOpacity(0.1), blurRadius: 80, spreadRadius: 30)]))),
            SafeArea(
              child: Column(
                children: [
                  // 🎯 ULTRA PREMIUM HEADER
                  _buildHeader(context),
                  Expanded(
                    child: StreamBuilder<List<ServingUnit>>(
                      stream: ref.watch(servingUnitServiceProvider).streamAllActiveUnits(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));

                        final items = snapshot.data ?? [];

                        if(items.isEmpty) return const Center(child: Text("No serving units found."));

                        return ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
                          itemCount: items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return _buildUnitCard(context, item);
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
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ServingUnitEntryPage())),
          backgroundColor: Colors.pink,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text("New Unit", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  // 🎯 FIX 5: Updated to use wider container for abbreviation
  Widget _buildUnitCard(BuildContext context, ServingUnit item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border(left: BorderSide(color: Colors.pink.withOpacity(0.5), width: 4)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          // 🎯 Increased width to fit longer abbreviations
          width: 80,
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
              color: Colors.pink.shade50,
              borderRadius: BorderRadius.circular(10)
          ),
          child: Center(
            child: Text(
              item.abbreviation,
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.pink.shade800, fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        // Show base unit if available, otherwise just ID
        subtitle: Text('Base Unit: ${item.baseUnit ?? 'N/A'}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        trailing: IconButton(
          icon: Icon(Icons.edit_outlined, color: Theme.of(context).colorScheme.primary),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ServingUnitEntryPage(itemToEdit: item))),
        ),
      ),
    );
  }

  // 🎯 CUSTOM HEADER (Ultra Premium Glassmorphic)
  Widget _buildHeader(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 10, 20, 16),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1)))),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
                    child: const Icon(Icons.arrow_back, size: 20)),
              ),
              const SizedBox(width: 16),
              const Expanded(child: Text("Serving Units", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)))),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.pink.withOpacity(.1), shape: BoxShape.circle),
                child: const Icon(Icons.scale, color: Colors.pink),
              )
            ],
          ),
        ),
      ),
    );
  }
}