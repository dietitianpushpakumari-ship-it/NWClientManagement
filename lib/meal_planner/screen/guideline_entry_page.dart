import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:nutricare_client_management/helper/language_config.dart';
import 'package:nutricare_client_management/modules/master/model/diet_plan_category.dart';
import 'package:nutricare_client_management/modules/master/model/guidelines.dart';
import 'package:nutricare_client_management/modules/master/service/guideline_service.dart';
import 'package:provider/provider.dart';
import '../service/Dependancy_service.dart';

class GuidelineEntryPage extends StatefulWidget {
  final Guideline? itemToEdit;
  const GuidelineEntryPage({super.key, this.itemToEdit});
  @override
  State<GuidelineEntryPage> createState() => _GuidelineEntryPageState();
}

class _GuidelineEntryPageState extends State<GuidelineEntryPage> {
  final _formKey = GlobalKey<FormState>();
  final _enTitleController = TextEditingController();
  Set<String> _selectedCats = {};
  bool _isLoading = false;
  late Future<List<DietPlanCategory>> _catsFuture;

  @override
  void initState() {
    super.initState();
    _catsFuture = DependencyService().fetchAllActiveDietPlanCategories();
    if (widget.itemToEdit != null) {
      _enTitleController.text = widget.itemToEdit!.enTitle;
      _selectedCats = Set.from(widget.itemToEdit!.dietPlanCategoryIds);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    await Provider.of<GuidelineService>(context, listen: false).save(Guideline(
      id: widget.itemToEdit?.id ?? '',
      enTitle: _enTitleController.text.trim(),
      dietPlanCategoryIds: _selectedCats.toList(),
    ));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: Stack(
        children: [
          Positioned(top: -100, right: -100, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.blueGrey.withOpacity(0.1), blurRadius: 80, spreadRadius: 30)]))),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(widget.itemToEdit == null ? "New Guideline" : "Edit Guideline", onSave: _save, isLoading: _isLoading),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildCard("Guideline Content", Icons.rule, Colors.blueGrey,
                              TextFormField(controller: _enTitleController, maxLines: 4, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: "Enter guideline text...", filled: true, fillColor: Colors.white), validator: (v) => v!.isEmpty ? "Req" : null)
                          ),
                          _buildCard("Applies To Categories", Icons.category, Colors.orange,
                              FutureBuilder<List<DietPlanCategory>>(
                                  future: _catsFuture,
                                  builder: (ctx, snap) {
                                    if (!snap.hasData) return const LinearProgressIndicator();
                                    return Wrap(spacing: 8, children: snap.data!.map((c) => FilterChip(label: Text(c.enName), selected: _selectedCats.contains(c.id), onSelected: (v) => setState(() => v ? _selectedCats.add(c.id) : _selectedCats.remove(c.id)))).toList());
                                  }
                              )
                          )
                        ],
                      ),
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

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
            IconButton(onPressed: isLoading ? null : onSave, icon: isLoading ? const CircularProgressIndicator() : const Icon(Icons.check_circle, color: Colors.blueGrey, size: 28))
          ]),
        ),
      ),
    );
  }
  Widget _buildCard(String title, IconData icon, Color color, Widget child) {
    return Container(margin: const EdgeInsets.only(bottom: 20), padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))]), child: Column(children: [Row(children: [Icon(icon, color: color), const SizedBox(width: 10), Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color))]), const SizedBox(height: 16), child]));
  }
}