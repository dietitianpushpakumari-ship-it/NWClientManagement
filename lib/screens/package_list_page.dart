import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../models/package_model.dart';
// Assuming the following models/services exist in your structure
import '../../services/package_payment_service.dart';
import '../services/package_Service.dart';
import 'package_entry_page.dart'; // Import for Create/Edit

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

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Packages Master'),
        backgroundColor: Colors.purple,
      ),
      body: FutureBuilder<List<PackageModel>>(
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
            return const Center(child: Text('No packages available. Tap "+" to create one.'));
          }

          return ListView.builder(
            itemCount: packages.length,
            itemBuilder: (context, index) {
              final package = packages[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  // 🎯 FIX: Set dense to true to reduce vertical spacing
                  dense: true,
                  leading: Icon(
                    package.isActive ? Icons.check_circle : Icons.cancel,
                    color: package.isActive ? Colors.green : Colors.red,
                  ),
                  title: Text(
                      package.name,
                      style: const TextStyle(fontWeight: FontWeight.bold)
                  ),

                  // Subtitle remains compact
                  subtitle: Text(
                    '${package.category.displayName}, ${package.durationDays} days, ${package.programFeatureIds.length} features',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),

                  // 🎯 FIX: Trailing is now only the price, removing height-consuming action buttons.
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        currencyFormatter.format(package.price),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                          fontSize: 14,
                        ),
                      ),
                      // Add a subtle indicator that tapping edits the item
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                        onPressed: () => _editPackage(package),
                      ),
                      // Provide quick delete access via a PopUpMenu for ultimate compactness
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'delete') _deletePackage(package);
                        },
                        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                          const PopupMenuItem<String>(
                            value: 'delete',
                            child: Text('Delete'),
                          ),
                        ],
                        icon: const Icon(Icons.more_vert, size: 20),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),

                  // Tap the item to edit (primary action)
                  onTap: () => _editPackage(package),
                ),
              );
            },
          );
        },
      ),

      // Floating button to CREATE a new package
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _navigateAndRefresh(const PackageEntryPage());
        },
        child: const Icon(Icons.add),
        backgroundColor: Colors.blueGrey,
        tooltip: 'Create New Package',
      ),
    );
  }
}