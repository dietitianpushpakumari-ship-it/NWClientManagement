import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nutricare_client_management/admin/labvital/global_service_provider.dart';
import 'package:nutricare_client_management/admin/package_details_screen.dart';
import 'package:nutricare_client_management/modules/package/model/package_model.dart';
import 'package:nutricare_client_management/modules/package/service/package_Service.dart';
import 'package:nutricare_client_management/screens/package_entry_page.dart';

class PackageListPage extends ConsumerStatefulWidget {
  const PackageListPage({super.key});

  @override
  ConsumerState<PackageListPage> createState() => _PackageListPageState();
}

class _PackageListPageState extends ConsumerState<PackageListPage> {

  // 🎯 ACTIONS
  Future<void> _handleDuplicate(PackageModel pkg) async {
    await ref.read(packageServiceProvider).duplicatePackage(pkg);
    if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Package Duplicated to Drafts")));
  }

  Future<void> _handleDelete(PackageModel pkg) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Draft?"),
        content: Text("Are you sure you want to delete '${pkg.name}'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete"),
          )
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(packageServiceProvider).deletePackage(pkg);
    }
  }

  Future<void> _handleFinalize(PackageModel pkg) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Finalize Package?"),
        content: const Text("Once finalized, this package CANNOT be edited or deleted.\n\nIt will become available for assignment."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Finalize & Lock"),
          )
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(packageServiceProvider).finalizePackage(pkg.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(packageServiceProvider);
    final currency = NumberFormat.currency(symbol: '₹', decimalDigits: 0, locale: 'en_IN');

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PackageEntryPage())),
        backgroundColor: Colors.purple,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Create Draft", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Stack(
        children: [
          Positioned(top: -100, right: -100, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.purple.withOpacity(0.1), blurRadius: 80, spreadRadius: 30)]))),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, "Service Packages"),
                Expanded(
                  child: StreamBuilder<List<PackageModel>>(
                    // 🎯 Note: Ensure streamPackages() returns both active AND inactive (drafts) if needed.
                    // If streamPackages() filters by isActive=true, you might need a new method like `streamAllPackages()`
                    stream: service.streamPackages(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                      final list = snapshot.data ?? [];
                      if (list.isEmpty) return const Center(child: Text("No packages found."));

                      return ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: list.length,
                        itemBuilder: (context, index) {
                          final pkg = list[index];
                          final bool isLocked = pkg.isFinalized;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))],
                              border: isLocked ? null : Border.all(color: Colors.orange.withOpacity(0.5), width: 1), // Orange border for drafts
                            ),
                            child: Row(
                              children: [
                                // Icon Box
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                      color: isLocked ? Colors.purple.shade50 : Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(12)
                                  ),
                                  child: Icon(
                                      isLocked ? Icons.check_circle : Icons.edit_note,
                                      color: isLocked ? Colors.purple : Colors.orange,
                                      size: 28
                                  ),
                                ),
                                const SizedBox(width: 16),

                                // Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(child: Text(pkg.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                          if (!isLocked)
                                            Container(
                                              margin: const EdgeInsets.only(left: 8),
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(4)),
                                              child: const Text("DRAFT", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                            )
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text("${pkg.durationDays} Days • ${pkg.category.displayName}", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                    ],
                                  ),
                                ),

                                // Price & Menu
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(currency.format(pkg.price), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                                    const SizedBox(height: 4),

                                    // 🎯 ACTIONS MENU
                                    PopupMenuButton<String>(
                                      icon: Icon(Icons.more_horiz, color: Colors.grey.shade400),
                                      onSelected: (val) {
                                        if (val == 'copy') _handleDuplicate(pkg);

                                        // 🎯 Logic: If Edit/View is clicked
                                        if (val == 'edit') {
                                          Navigator.push(context, MaterialPageRoute(builder: (_) => PackageEntryPage(packageToEdit: pkg)));
                                        }
                                        if (val == 'view') {
                                          // 🎯 Navigate to Detail Screen
                                          Navigator.push(context, MaterialPageRoute(builder: (_) => PackageDetailScreen(package: pkg)));
                                        }

                                        if (val == 'delete') _handleDelete(pkg);
                                        if (val == 'finalize') _handleFinalize(pkg);
                                      },
                                      itemBuilder: (ctx) => [
                                        const PopupMenuItem(value: 'copy', child: Row(children: [Icon(Icons.copy, size: 18), SizedBox(width: 8), Text("Duplicate")])),

                                        //if (!isLocked) ...[
                                          const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text("Edit Draft")])),
                                          const PopupMenuItem(value: 'finalize', child: Row(children: [Icon(Icons.lock_outline, size: 18, color: Colors.green), SizedBox(width: 8), Text("Finalize", style: TextStyle(color: Colors.green))])),
                                          const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 8), Text("Delete", style: TextStyle(color: Colors.red))])),
                                      //  ] else ...[
                                          // 🎯 For Finalized Packages: Show "View Details"
                                          const PopupMenuItem(value: 'view', child: Row(children: [Icon(Icons.visibility, size: 18), SizedBox(width: 8), Text("View Details")])),
                                        //]
                                      ],
                                    )
                                  ],
                                )
                              ],
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
    // ... same as before ...
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Row(
        children: [
          GestureDetector(onTap: () => Navigator.pop(context), child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]), child: const Icon(Icons.arrow_back, size: 20))),
          const SizedBox(width: 16),
          Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
        ],
      ),
    );
  }
}