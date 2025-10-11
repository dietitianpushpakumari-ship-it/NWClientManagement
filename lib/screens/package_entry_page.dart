import 'package:flutter/material.dart';
import 'package:nutricare_client_management/models/programme_feature_model.dart';
import 'package:provider/provider.dart';
import '../../models/package_model.dart';
import '../../services/program_feature_service.dart'; // 🎯 NEW
import '../../services/package_payment_service.dart';
import '../services/package_Service.dart';

class PackageEntryPage extends StatefulWidget {
  final PackageModel? packageToEdit; // Optional package for editing

  const PackageEntryPage({super.key, this.packageToEdit});

  @override
  State<PackageEntryPage> createState() => _PackageEntryPageState();
}

class _PackageEntryPageState extends State<PackageEntryPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();
  final _inclusionsController = TextEditingController();

  bool _isActive = true;
  bool _isLoading = false;

  // 🎯 NEW: State variables for new fields
  late PackageCategory _selectedCategory;
  late List<String> _selectedFeatureIds;
  late Future<List<ProgramFeatureModel>> _programFeaturesFuture;

  @override
  void initState() {
    super.initState();
    _programFeaturesFuture = ProgramFeatureService().streamAllFeatures().first; // Get list once
    _selectedCategory = PackageCategory.basic;
    _selectedFeatureIds = [];

    if (widget.packageToEdit != null) {
      _initializeForEdit(widget.packageToEdit!);
    }
  }

  void _initializeForEdit(PackageModel package) {
    _nameController.text = package.name;
    _descController.text = package.description;
    _priceController.text = package.price.toString();
    _durationController.text = package.durationDays.toString();
    _inclusionsController.text = package.inclusions.join(', ');
    _isActive = package.isActive;

    // 🎯 INITIALIZE NEW FIELDS
    _selectedCategory = package.category;
    _selectedFeatureIds = List.from(package.programFeatureIds);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    _inclusionsController.dispose();
    super.dispose();
  }

  Future<void> _savePackage() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final packageService = Provider.of<PackageService>(context, listen: false);

    final inclusionsList = _inclusionsController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final newPackage = PackageModel(
      id: widget.packageToEdit?.id ?? '', // ID only if editing
      name: _nameController.text.trim(),
      description: _descController.text.trim(),
      price: double.parse(_priceController.text),
      durationDays: int.parse(_durationController.text),
      inclusions: inclusionsList,
      isActive: _isActive,
      // 🎯 SAVE NEW FIELDS
      category: _selectedCategory,
      programFeatureIds: _selectedFeatureIds,
    );

    try {
      if (widget.packageToEdit == null) {
        await packageService.addPackage(newPackage);
      } else {
        await packageService.updatePackage(newPackage);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save package: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.packageToEdit == null ? 'Create New Package' : 'Edit Package'),
        backgroundColor: Colors.blueGrey,
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _savePackage,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 15),
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
          ),
          child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Save Package'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // 🎯 NEW: Category Dropdown
              DropdownButtonFormField<PackageCategory>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Package Category',
                  border: OutlineInputBorder(),
                ),
                items: PackageCategory.values.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category.displayName),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedCategory = val!;
                  });
                },
              ),
              const SizedBox(height: 15),

              // Feature Multi-Select
              FutureBuilder<List<ProgramFeatureModel>>(
                future: _programFeaturesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: LinearProgressIndicator());
                  }
                  if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Text('No Program Features available. Define them first.');
                  }

                  final allFeatures = snapshot.data!;

                  // 🎯 Multi-select Chip display
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: Text('Program Features', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                      ),
                      Wrap(
                        spacing: 8.0,
                        children: allFeatures.map((feature) {
                          final isSelected = _selectedFeatureIds.contains(feature.id);
                          return FilterChip(
                            label: Text(feature.name),
                            selected: isSelected,
                            onSelected: (bool selected) {
                              setState(() {
                                if (selected) {
                                  _selectedFeatureIds.add(feature.id);
                                } else {
                                  _selectedFeatureIds.remove(feature.id);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 15),
                    ],
                  );
                },
              ),

              // Existing Fields
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Package Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) => value!.isEmpty ? 'Description is required' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Price (₹)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty || double.tryParse(value!) == null ? 'Valid price required' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Duration (Days)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty || int.tryParse(value!) == null ? 'Valid duration (days) required' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _inclusionsController,
                decoration: const InputDecoration(
                  labelText: 'Inclusions (Comma Separated)',
                  hintText: 'e.g., diet chart, workout plan, weekly call',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 15),

              SwitchListTile(
                title: const Text('Is Active (Allows assignment to new clients)'),
                value: _isActive,
                onChanged: (val) {
                  setState(() {
                    _isActive = val;
                  });
                },
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}