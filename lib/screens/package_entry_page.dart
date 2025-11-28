import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:nutricare_client_management/models/programme_feature_model.dart';
import 'package:provider/provider.dart';
import '../modules/package/model/package_model.dart';
import '../modules/package/service/program_feature_service.dart';
import '../modules/package/service/package_Service.dart';

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

  late PackageCategory _selectedCategory;
  late List<String> _selectedFeatureIds;
  late Future<List<ProgramFeatureModel>> _programFeaturesFuture;

  @override
  void initState() {
    super.initState();
    _programFeaturesFuture = ProgramFeatureService().streamAllFeatures().first;
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
      id: widget.packageToEdit?.id ?? '',
      name: _nameController.text.trim(),
      description: _descController.text.trim(),
      price: double.parse(_priceController.text),
      durationDays: int.parse(_durationController.text),
      inclusions: inclusionsList,
      isActive: _isActive,
      category: _selectedCategory,
      programFeatureIds: _selectedFeatureIds,
    );

    try {
      if (widget.packageToEdit == null) {
        await packageService.addPackage(newPackage);
      } else {
        await packageService.updatePackage(newPackage);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Package saved successfully!')));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save package: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: Stack(
        children: [
          // Ambient Glow
          Positioned(top: -100, right: -100, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.deepPurple.withOpacity(0.1), blurRadius: 80, spreadRadius: 30)]))),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(widget.packageToEdit == null ? 'New Package' : 'Edit Package', onSave: _savePackage, isLoading: _isLoading),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          // --- CARD 1: Basic Info ---
                          _buildPremiumCard(
                              title: "Basic Info",
                              icon: Icons.inventory_2,
                              color: Colors.deepPurple,
                              child: Column(
                                children: [
                                  _buildTextField(_nameController, "Package Name", Icons.label),
                                  const SizedBox(height: 12),
                                  DropdownButtonFormField<PackageCategory>(
                                    value: _selectedCategory,
                                    decoration: _inputDec("Category", Icons.category),
                                    items: PackageCategory.values.map((category) {
                                      return DropdownMenuItem(value: category, child: Text(category.displayName));
                                    }).toList(),
                                    onChanged: (val) => setState(() => _selectedCategory = val!),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildTextField(_descController, "Description", Icons.description, maxLines: 3),
                                ],
                              )
                          ),

                          // --- CARD 2: Pricing & Duration ---
                          _buildPremiumCard(
                              title: "Pricing & Terms",
                              icon: Icons.currency_rupee,
                              color: Colors.green,
                              child: Row(
                                children: [
                                  Expanded(child: _buildTextField(_priceController, "Price (₹)", Icons.attach_money, isNumber: true)),
                                  const SizedBox(width: 12),
                                  Expanded(child: _buildTextField(_durationController, "Duration (Days)", Icons.timer, isNumber: true)),
                                ],
                              )
                          ),

                          // --- CARD 3: Configuration ---
                          _buildPremiumCard(
                              title: "Configuration",
                              icon: Icons.settings,
                              color: Colors.orange,
                              child: Column(
                                children: [
                                  _buildTextField(_inclusionsController, "Inclusions (comma separated)", Icons.list, maxLines: 2),
                                  const SizedBox(height: 16),
                                  SwitchListTile(
                                    title: const Text('Active Status', style: TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text(_isActive ? 'Available for assignment' : 'Hidden from list'),
                                    value: _isActive,
                                    activeColor: Colors.green,
                                    onChanged: (val) => setState(() => _isActive = val),
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ],
                              )
                          ),

                          // --- CARD 4: Features ---
                          _buildPremiumCard(
                              title: "Program Features",
                              icon: Icons.star,
                              color: Theme.of(context).colorScheme.primary,
                              child: FutureBuilder<List<ProgramFeatureModel>>(
                                future: _programFeaturesFuture,
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) return const LinearProgressIndicator();
                                  final allFeatures = snapshot.data!;
                                  if (allFeatures.isEmpty) return const Text("No features defined in master.");

                                  return Wrap(
                                    spacing: 8.0,
                                    runSpacing: 8.0,
                                    children: allFeatures.map((feature) {
                                      final isSelected = _selectedFeatureIds.contains(feature.id);
                                      return FilterChip(
                                        label: Text(feature.name),
                                        selected: isSelected,
                                        onSelected: (bool selected) {
                                          setState(() {
                                            if (selected) _selectedFeatureIds.add(feature.id);
                                            else _selectedFeatureIds.remove(feature.id);
                                          });
                                        },
                                        selectedColor: Theme.of(context).colorScheme.primary..withOpacity(.15),
                                        checkmarkColor: Theme.of(context).colorScheme.primary,
                                      );
                                    }).toList(),
                                  );
                                },
                              )
                          ),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- HELPERS ---

  Widget _buildHeader(String title, {required VoidCallback onSave, required bool isLoading}) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1)))),
          child: Row(children: [
            GestureDetector(onTap: () => Navigator.pop(context), child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]), child: const Icon(Icons.arrow_back, size: 20))),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
            IconButton(onPressed: isLoading ? null : onSave, icon: isLoading ? const CircularProgressIndicator() : const Icon(Icons.check_circle, color: Colors.deepPurple, size: 28))
          ]),
        ),
      ),
    );
  }

  Widget _buildPremiumCard({required String title, required IconData icon, required Color color, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))], border: Border.all(color: color.withOpacity(0.1))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 20)), const SizedBox(width: 12), Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color))]),
        const SizedBox(height: 16),
        child,
      ]),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label, IconData icon, {bool isNumber = false, int maxLines = 1}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      maxLines: maxLines,
      decoration: _inputDec(label, icon),
      validator: (v) => v!.isEmpty ? "Required" : null,
    );
  }

  InputDecoration _inputDec(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20, color: Colors.grey),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}