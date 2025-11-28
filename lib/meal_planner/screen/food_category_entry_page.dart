import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nutricare_client_management/helper/language_config.dart';
import 'package:nutricare_client_management/modules/master/model/food_category.dart';
import 'package:nutricare_client_management/modules/master/service/food_category_service.dart';
import 'package:provider/provider.dart';

class FoodCategoryEntryPage extends StatefulWidget {
  final FoodCategory? itemToEdit;
  const FoodCategoryEntryPage({super.key, this.itemToEdit});
  @override
  State<FoodCategoryEntryPage> createState() => _FoodCategoryEntryPageState();
}

class _FoodCategoryEntryPageState extends State<FoodCategoryEntryPage> {
  final _formKey = GlobalKey<FormState>();
  final _enNameController = TextEditingController();
  final _orderController = TextEditingController(text: '10');
  final Map<String, TextEditingController> _localizedControllers = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    for (var code in supportedLanguageCodes) { if (code != 'en') _localizedControllers[code] = TextEditingController(); }
    if (widget.itemToEdit != null) {
      _enNameController.text = widget.itemToEdit!.enName;
      _orderController.text = widget.itemToEdit!.displayOrder.toString();
      widget.itemToEdit!.nameLocalized.forEach((code, name) { if (_localizedControllers.containsKey(code)) _localizedControllers[code]!.text = name; });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final service = Provider.of<FoodCategoryService>(context, listen: false);
    final Map<String, String> localizedNames = {};
    _localizedControllers.forEach((k, v) { if (v.text.isNotEmpty) localizedNames[k] = v.text; });

    await service.save(FoodCategory(
      id: widget.itemToEdit?.id ?? '',
      enName: _enNameController.text.trim(),
      nameLocalized: localizedNames,
      displayOrder: int.tryParse(_orderController.text) ?? 0,
    ));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: Stack(
        children: [
          Positioned(top: -100, right: -100, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.1), blurRadius: 80, spreadRadius: 30)]))),
          Column(
            children: [
              _buildHeader(widget.itemToEdit == null ? "New Food Category" : "Edit Category", onSave: _save, isLoading: _isLoading),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildCard(
                            "Category Details", Icons.category, Colors.green,
                            Column(children: [
                              _buildField(_enNameController, "Category Name", Icons.label),
                              const SizedBox(height: 12),
                              _buildField(_orderController, "Display Order", Icons.sort, isNum: true),
                            ])
                        ),
                        _buildCard(
                            "Translations", Icons.translate, Colors.blue,
                            Column(children: supportedLanguageCodes.where((c)=>c!='en').map((code) => Padding(padding: const EdgeInsets.only(bottom: 12), child: _buildField(_localizedControllers[code]!, "Name in ${supportedLanguages[code]}", Icons.language))).toList())
                        )
                      ],
                    ),
                  ),
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  // --- Same Helpers (Condensed for brevity) ---
  Widget _buildHeader(String title, {required VoidCallback onSave, required bool isLoading}) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 10, 20, 16),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1)))),
          child: Row(children: [
            GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.arrow_back)),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
            IconButton(onPressed: isLoading ? null : onSave, icon: isLoading ? const CircularProgressIndicator() : const Icon(Icons.check_circle, color: Colors.green, size: 28))
          ]),
        ),
      ),
    );
  }
  Widget _buildCard(String title, IconData icon, Color color, Widget child) {
    return Container(margin: const EdgeInsets.only(bottom: 20), padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.1))), child: Column(children: [Row(children: [Icon(icon, color: color), const SizedBox(width: 10), Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color))]), const SizedBox(height: 16), child]));
  }
  Widget _buildField(TextEditingController c, String l, IconData i, {bool isNum = false}) => TextFormField(controller: c, keyboardType: isNum ? TextInputType.number : TextInputType.text, decoration: InputDecoration(labelText: l, prefixIcon: Icon(i, size: 18), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: Colors.grey.shade50), validator: (v) => v!.isEmpty ? "Required" : null);
}