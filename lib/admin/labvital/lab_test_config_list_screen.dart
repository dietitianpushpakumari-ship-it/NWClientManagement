import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutricare_client_management/admin/lab_category_migrator.dart';
import 'package:nutricare_client_management/admin/lab_test_config_entry_page.dart';
import 'package:nutricare_client_management/admin/lab_test_config_model.dart';
import 'package:nutricare_client_management/admin/lab_test_config_service.dart';
import 'package:nutricare_client_management/admin/lab_vitals_migrator.dart';
import 'dart:ui';

// 🎯 Helper for Categories and initial data
import 'package:nutricare_client_management/helper/lab_vitals_data.dart';
// 🎯 NEW IMPORTS
import 'package:nutricare_client_management/master/model/master_constants.dart';
import 'package:nutricare_client_management/admin/services/master_data_service.dart';


// NEW PROVIDER: Fetches list of category names (Strings) from Firestore
final labCategoryNamesProvider = StreamProvider.autoDispose<List<String>>((ref) {
  final service = ref.watch(masterDataServiceProvider);
  final collectionPath = MasterCollectionMapper.getPath(MasterEntity.entity_labTestCategory);

  // fetchMasterStream returns Stream<Map<name, id>>, we map it to just the list of names (keys)
  return service.fetchMasterStream(collectionPath).map((map) => map.keys.toList());
});


class LabTestConfigListScreen extends ConsumerStatefulWidget {
  const LabTestConfigListScreen({super.key});

  @override
  ConsumerState<LabTestConfigListScreen> createState() => _LabTestConfigListScreenState();
}

class _LabTestConfigListScreenState extends ConsumerState<LabTestConfigListScreen> {
  String? _selectedCategoryFilter;

  // --- Bulk Upload Logic (Retained) ---
  void _confirmBulkUpload(BuildContext context) async {
    final testsCount = LabVitalsData.allLabTests1.length;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Bulk Upload"),
        content: Text("This will attempt to upload $testsCount default lab test configurations from the local Dart file. This should only be used ONCE for initial database migration. Continue?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("UPLOAD NOW"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // FIX: duration passed to SnackBar, not showSnackBar
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Starting bulk upload..."),
          duration: Duration(seconds: 1)
      ));
      try {
        final uploadedCount = await LabVitalsMigrator.runBulkMigration(ref);

        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Bulk upload complete! $uploadedCount tests added.")));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Upload failed: $e")));
      }
    }
  }

  void _confirmCategoryBulkUpload(BuildContext context) async {
    final categoriesCount = LabVitalsData.labCategories1.length;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Category Bulk Upload"),
        content: Text("This will attempt to upload $categoriesCount default Lab Categories from the local Dart file. This should only be used ONCE for initial database migration. Continue?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("UPLOAD NOW"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // FIX: duration passed to SnackBar, not showSnackBar
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Starting category bulk upload..."),
          duration: Duration(seconds: 1)
      ));
      try {
        final uploadedCount = await LabCategoryMigrator.runBulkMigration(ref);

        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Category bulk upload complete! $uploadedCount categories added.")));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Category upload failed: $e")));
      }
    }
  }


  // --- Header/UI Builders (Retained) ---

  Widget _buildCustomHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 10, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.blue), onPressed: () => Navigator.pop(context), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
          const SizedBox(width: 10),
          const Expanded(child: Text("Lab Test Configuration", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)))),

          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.grey),
            onSelected: (value) {
              if (value == 'bulk_upload_tests') {
                _confirmBulkUpload(context);
              } else if (value == 'bulk_upload_categories') {
                _confirmCategoryBulkUpload(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'bulk_upload_tests', child: Text("Bulk Upload Default Tests")),
              const PopupMenuItem(value: 'bulk_upload_categories', child: Text("Bulk Upload Default Categories")),
            ],
          ),
        ],
      ),
    );
  }

  // 🎯 MODIFIED: Replaced Row of IconButtons with a single PopupMenuButton
  Widget _buildTestCard(BuildContext context, LabTestConfigModel test) {
    final rangeText = (test.minRange != null && test.maxRange != null)
        ? "${test.minRange} - ${test.maxRange} ${test.unit}"
        : (test.minRange != null ? "> ${test.minRange} ${test.unit}" : (test.maxRange != null ? "< ${test.maxRange} ${test.unit}" : "N/A"));

    return Card(
      elevation: 1, margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(test.isReverseLogic ? Icons.south_west : Icons.north_east, color: test.isReverseLogic ? Colors.green : Colors.red),
        title: Text(test.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Category: ${test.category}"),
            Text("Range: $rangeText", style: const TextStyle(fontSize: 12)),
          ],
        ),
        // 🎯 NEW: Menu for Edit and Delete
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              Navigator.push(context, MaterialPageRoute(builder: (_) => LabTestConfigEntryPage(initialTest: test)));
            } else if (value == 'delete') {
              _confirmDelete(test.id, test.displayName);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem<String>(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_forever, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete'),
                ],
              ),
            ),
          ],
          icon: const Icon(Icons.more_vert),
        ),
      ),
    );
  }

  void _confirmDelete(String id, String name) async {
    final service = ref.read(labTestConfigServiceProvider);
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: Text("Are you sure you want to delete test: '$name'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              await service.deleteLabTest(id);
              ref.invalidate(allLabTestsStreamProvider);
              if (mounted) Navigator.pop(ctx, true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$name deleted.")));
    }
  }


  @override
  Widget build(BuildContext context) {
    final testsAsyncValue = ref.watch(allLabTestsStreamProvider);
    // Use the new provider for categories instead of the hardcoded list
    final categoriesAsync = ref.watch(labCategoryNamesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Determine the initial category for the new entry page
          // Safely check the loaded categories before assigning.
          final initialCategory = categoriesAsync.maybeWhen(
            data: (cats) => cats.isNotEmpty ? cats.first : '',
            orElse: () => '',
          );

          Navigator.push(context, MaterialPageRoute(builder: (_) => LabTestConfigEntryPage(initialCategory: _selectedCategoryFilter ?? initialCategory)));
        },
        label: const Text("Add New Test"),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.blue,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildCustomHeader(context),

            // CATEGORY FILTER DROPDOWN (Now driven by Firestore data)
            categoriesAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(20),
                child: LinearProgressIndicator(),
              ),
              error: (err, stack) => Padding(
                padding: const EdgeInsets.all(20),
                child: Text("Error loading categories: $err"),
              ),
              data: (categories) {
                // Ensure categories include the 'All Categories' option
                final dropdownItems = [
                  const DropdownMenuItem<String>(value: null, child: Text("All Categories")),
                  ...categories.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                ];

                // If the previously selected filter value no longer exists, reset it.
                if (_selectedCategoryFilter != null && !categories.contains(_selectedCategoryFilter)) {
                  // Use addPostFrameCallback to avoid calling setState during build
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    setState(() {
                      _selectedCategoryFilter = null;
                    });
                  });
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: DropdownButtonFormField<String>(
                    value: _selectedCategoryFilter,
                    decoration: const InputDecoration(labelText: "Filter by Category", border: OutlineInputBorder()),
                    items: dropdownItems,
                    onChanged: (val) => setState(() => _selectedCategoryFilter = val),
                  ),
                );
              },
            ),

            Expanded(
              child: testsAsyncValue.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text("Error loading tests: $err")),
                data: (tests) {
                  final filteredTests = tests.where((test) {
                    return _selectedCategoryFilter == null || test.category == _selectedCategoryFilter;
                  }).toList();

                  if (filteredTests.isEmpty) {
                    return Center(child: Text("No tests found for ${(_selectedCategoryFilter?.isEmpty ?? true || _selectedCategoryFilter == null) ? 'all categories' : _selectedCategoryFilter}."));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: filteredTests.length,
                    itemBuilder: (context, index) {
                      return _buildTestCard(context, filteredTests[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}