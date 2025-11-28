import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:nutricare_client_management/helper/language_config.dart';
import 'package:nutricare_client_management/modules/master/model/ServingUnit.dart';
import 'package:nutricare_client_management/modules/master/service/serving_unit_service.dart';
import 'package:provider/provider.dart';

class ServingUnitEntryPage extends StatefulWidget {
  final ServingUnit? unitToEdit;
  const ServingUnitEntryPage({super.key, this.unitToEdit});
  @override
  State<ServingUnitEntryPage> createState() => _ServingUnitEntryPageState();
}

class _ServingUnitEntryPageState extends State<ServingUnitEntryPage> {
  final _formKey = GlobalKey<FormState>();
  final _enNameController = TextEditingController();
  final _abbreviationController = TextEditingController();
  String _baseUnit = 'mass';
  final Map<String, TextEditingController> _localizedControllers = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    for (var code in supportedLanguageCodes) { if (code != 'en') _localizedControllers[code] = TextEditingController(); }
    if (widget.unitToEdit != null) {
      _enNameController.text = widget.unitToEdit!.enName;
      _abbreviationController.text = widget.unitToEdit!.abbreviation;
      _baseUnit = widget.unitToEdit!.baseUnit;
      widget.unitToEdit!.nameLocalized.forEach((code, name) { if (_localizedControllers.containsKey(code)) _localizedControllers[code]!.text = name; });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final service = Provider.of<ServingUnitService>(context, listen: false);
    final Map<String, String> localizedNames = {};
    _localizedControllers.forEach((k, v) { if (v.text.isNotEmpty) localizedNames[k] = v.text; });

    await service.saveUnit(ServingUnit(
      id: widget.unitToEdit?.id ?? '',
      enName: _enNameController.text.trim(),
      abbreviation: _abbreviationController.text.trim(),
      baseUnit: _baseUnit,
      nameLocalized: localizedNames,
    ));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: Stack(
        children: [
          Positioned(top: -100, right: -100, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.teal.withOpacity(0.1), blurRadius: 80, spreadRadius: 30)]))),
          Column(
            children: [
              _buildHeader(widget.unitToEdit == null ? "New Serving Unit" : "Edit Unit", onSave: _save, isLoading: _isLoading),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildCard("Unit Details", Icons.scale, Colors.teal, Column(children: [
                          _buildField(_enNameController, "Unit Name", Icons.label),
                          const SizedBox(height: 12),
                          _buildField(_abbreviationController, "Abbreviation (e.g. g, ml)", Icons.short_text),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _baseUnit,
                            decoration: InputDecoration(labelText: "Base Type", prefixIcon: const Icon(Icons.science, size: 18), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: Colors.grey.shade50),
                            items: ['mass', 'volume'].map((e) => DropdownMenuItem(value: e, child: Text(e.toUpperCase()))).toList(),
                            onChanged: (v) => setState(() => _baseUnit = v!),
                          )
                        ])),
                        _buildCard("Translations", Icons.translate, Colors.blue, Column(children: supportedLanguageCodes.where((c)=>c!='en').map((code) => Padding(padding: const EdgeInsets.only(bottom: 12), child: _buildField(_localizedControllers[code]!, "Name in ${supportedLanguages[code]}", Icons.language))).toList()))
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

  // --- REUSING HELPERS ---
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
            IconButton(onPressed: isLoading ? null : onSave, icon: isLoading ? const CircularProgressIndicator() : const Icon(Icons.check_circle, color: Colors.teal, size: 28))
          ]),
        ),
      ),
    );
  }
  Widget _buildCard(String title, IconData icon, Color color, Widget child) {
    return Container(margin: const EdgeInsets.only(bottom: 20), padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.1))), child: Column(children: [Row(children: [Icon(icon, color: color), const SizedBox(width: 10), Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color))]), const SizedBox(height: 16), child]));
  }
  Widget _buildField(TextEditingController c, String l, IconData i) => TextFormField(controller: c, decoration: InputDecoration(labelText: l, prefixIcon: Icon(i, size: 18), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: Colors.grey.shade50), validator: (v) => v!.isEmpty ? "Required" : null);
}