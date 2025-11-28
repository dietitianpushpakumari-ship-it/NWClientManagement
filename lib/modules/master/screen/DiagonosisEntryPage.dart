import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:nutricare_client_management/helper/language_config.dart';
import 'package:nutricare_client_management/modules/master/model/diagonosis_master.dart';
import 'package:nutricare_client_management/modules/master/service/diagonosis_master_service.dart';
import 'package:provider/provider.dart';

class DiagnosisEntryPage extends StatefulWidget {
  final DiagnosisMasterModel? diagnosisToEdit;
  const DiagnosisEntryPage({super.key, this.diagnosisToEdit});
  @override
  State<DiagnosisEntryPage> createState() => _DiagnosisEntryPageState();
}

class _DiagnosisEntryPageState extends State<DiagnosisEntryPage> {
  final _formKey = GlobalKey<FormState>();
  final _enNameController = TextEditingController();
  final Map<String, TextEditingController> _localizedControllers = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    for (var code in supportedLanguageCodes) { if (code != 'en') _localizedControllers[code] = TextEditingController(); }
    if (widget.diagnosisToEdit != null) {
      _enNameController.text = widget.diagnosisToEdit!.enName;
      widget.diagnosisToEdit!.nameLocalized.forEach((k, v) { if (_localizedControllers.containsKey(k)) _localizedControllers[k]!.text = v; });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final service = Provider.of<DiagnosisMasterService>(context, listen: false);
    final Map<String, String> loc = {};
    _localizedControllers.forEach((k, v) { if (v.text.isNotEmpty) loc[k] = v.text; });

    await service.addOrUpdateDiagnosis(DiagnosisMasterModel(
      id: widget.diagnosisToEdit?.id ?? '',
      enName: _enNameController.text.trim(),
      nameLocalized: loc,
    ));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: Stack(
        children: [
          Positioned(top: -100, right: -100, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.1), blurRadius: 80, spreadRadius: 30)]))),
          Column(
            children: [
              _buildHeader(widget.diagnosisToEdit == null ? "New Diagnosis" : "Edit Diagnosis", onSave: _save, isLoading: _isLoading),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildCard("Condition Details", Icons.local_hospital, Colors.red, _buildField(_enNameController, "Diagnosis Name", Icons.edit_note)),
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

  // --- HELPERS (Reuse) ---
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
            IconButton(onPressed: isLoading ? null : onSave, icon: isLoading ? const CircularProgressIndicator() : const Icon(Icons.check_circle, color: Colors.red, size: 28))
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