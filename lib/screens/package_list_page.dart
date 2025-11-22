import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../modules/package/model/package_model.dart';
import '../modules/package/service/package_Service.dart';
import 'package_entry_page.dart';
import 'package:nutricare_client_management/admin/custom_gradient_app_bar.dart';

class PackageListPage extends StatefulWidget {
  const PackageListPage({super.key});

  @override
  State<PackageListPage> createState() => _PackageListPageState();
}

class _PackageListPageState extends State<PackageListPage> {
  late Future<List<PackageModel>> _packagesFuture;

  @override
  void initState() {
    super.initState();
    _packagesFuture = _loadPackages();
  }

  Future<List<PackageModel>> _loadPackages() {
    final packageService = Provider.of<PackageService>(context, listen: false);
    return packageService.getAllActivePackages();
  }

  void _navigateAndRefresh(Widget page) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (context) => page));
    setState(() {
      _packagesFuture = _loadPackages();
    });
  }

  void _editPackage(PackageModel package) {
    _navigateAndRefresh(
      PackageEntryPage(packageToEdit: package),
    );
  }

  void _deletePackage(PackageModel package) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete package "${package.name}"?'),
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

    if (confirmed == true) {
      try {
        final packageService = Provider.of<PackageService>(context, listen: false);
        await packageService.deletePackage(package.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Package deleted successfully.')));
          setState(() {
            _packagesFuture = _loadPackages(); // Refresh list
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete package: $e')));
        }
      }
    }
  }

  // 🎯 NEW: Revamped Card Builder
  Widget _buildPackageCard(PackageModel package) {
    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final bool isActive = package.isActive;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isActive ? Colors.green.withOpacity(0.3) : Colors.grey.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- HEADER (Name, Price, Status) ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isActive ? Colors.green.shade50 : Colors.grey.shade100,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5),
                    ],
                  ),
                  child: Icon(
                    Icons.inventory_2_rounded,
                    color: isActive ? Colors.green.shade700 : Colors.grey,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        package.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currencyFormatter.format(package.price),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.indigo.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green : Colors.grey,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isActive ? 'ACTIVE' : 'INACTIVE',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- BODY (Details & Tags) ---
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description
                if (package.description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Text(
                      package.description,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                // Tags Row (Category, Duration, Features Count)
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: [
                    _buildInfoChip(Icons.category_outlined, package.category.displayName, Colors.blue),
                    _buildInfoChip(Icons.timer_outlined, '${package.durationDays} Days', Colors.orange),
                    if (package.programFeatureIds.isNotEmpty)
                      _buildInfoChip(Icons.star_outline, '${package.programFeatureIds.length} Features', Colors.purple),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // --- FOOTER (Actions) ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _editPackage(package),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(foregroundColor: Colors.indigo),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _deletePackage(package),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: CustomGradientAppBar(
        title: const Text('Service Packages Master'),
      ),
      body: SafeArea(
        child: FutureBuilder<List<PackageModel>>(
          future: _packagesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            final packages = snapshot.data ?? [];

            if (packages.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 60, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    const Text(
                      'No packages available.',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => _navigateAndRefresh(const PackageEntryPage()),
                      icon: const Icon(Icons.add),
                      label: const Text('Create First Package'),
                      style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: Colors.white),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: packages.length,
              itemBuilder: (context, index) {
                return _buildPackageCard(packages[index]);
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _navigateAndRefresh(const PackageEntryPage());
        },
        backgroundColor: colorScheme.primary,
        tooltip: 'Create New Package',
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}