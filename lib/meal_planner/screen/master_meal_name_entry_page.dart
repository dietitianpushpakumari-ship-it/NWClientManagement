import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:nutricare_client_management/helper/language_config.dart';
import 'package:nutricare_client_management/modules/master/model/meal_master_name.dart';
import 'package:nutricare_client_management/modules/master/service/master_meal_name_service.dart';
import 'package:provider/provider.dart';

class MasterMealNameEntryPage extends StatefulWidget {
  final MasterMealName? itemToEdit;
  const MasterMealNameEntryPage({super.key, this.itemToEdit});
  @override
  State<MasterMealNameEntryPage> createState() => _MasterMealNameEntryPageState();
}

class _MasterMealNameEntryPageState extends State<MasterMealNameEntryPage> {
  final _formKey = GlobalKey<FormState>();
  final _enNameController = TextEditingController();
  final _orderController = TextEditingController(text: '1');
  final Map<String, TextEditingController> _localizedControllers = {};
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    for (var code in supportedLanguageCodes) { if (code != 'en') _localizedControllers[code] = TextEditingController(); }
    if (widget.itemToEdit != null) {
      _enNameController.text = widget.itemToEdit!.enName;
      _orderController.text = widget.itemToEdit!.order.toString();
      if(widget.itemToEdit!.startTime != null) _startTime = _stringToTime(widget.itemToEdit!.startTime!);
      if(widget.itemToEdit!.endTime != null) _endTime = _stringToTime(widget.itemToEdit!.endTime!);
      widget.itemToEdit!.nameLocalized.forEach((k, v) { if (_localizedControllers.containsKey(k)) _localizedControllers[k]!.text = v; });
    }
  }

  TimeOfDay? _stringToTime(String s) {
    final p = s.split(':'); return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
  }
  String _timeToString(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final service = Provider.of<MasterMealNameService>(context, listen: false);
    final Map<String, String> loc = {};
    _localizedControllers.forEach((k, v) { if (v.text.isNotEmpty) loc[k] = v.text; });

    await service.save(MasterMealName(
      id: widget.itemToEdit?.id ?? '',
      enName: _enNameController.text.trim(),
      order: int.tryParse(_orderController.text) ?? 99,
      nameLocalized: loc,
      startTime: _startTime != null ? _timeToString(_startTime!) : null,
      endTime: _endTime != null ? _timeToString(_endTime!) : null,
    ));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: Stack(
        children: [
          Positioned(top: -100, right: -100, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.1), blurRadius: 80, spreadRadius: 30)]))),
          Column(
            children: [
              _buildHeader(widget.itemToEdit == null ? "New Meal Name" : "Edit Meal", onSave: _save, isLoading: _isLoading),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildCard("Meal Details", Icons.restaurant, Colors.blue, Column(children: [
                          _buildField(_enNameController, "English Name", Icons.label),
                          const SizedBox(height: 12),
                          _buildField(_orderController, "Sorting Order", Icons.sort, isNum: true),
                        ])),
                        _buildCard("Timing", Icons.access_time, Colors.orange, Row(children: [
                          Expanded(child: _buildTimePicker("Start", _startTime, (t) => setState(() => _startTime = t))),
                          const SizedBox(width: 12),
                          Expanded(child: _buildTimePicker("End", _endTime, (t) => setState(() => _endTime = t))),
                        ])),
                        _buildCard("Translations", Icons.translate, Colors.purple, Column(children: supportedLanguageCodes.where((c)=>c!='en').map((code) => Padding(padding: const EdgeInsets.only(bottom: 12), child: _buildField(_localizedControllers[code]!, "Name in ${supportedLanguages[code]}", Icons.language))).toList()))
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

  // --- HELPERS ---
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
            IconButton(onPressed: isLoading ? null : onSave, icon: isLoading ? const CircularProgressIndicator() : const Icon(Icons.check_circle, color: Colors.blue, size: 28))
          ]),
        ),
      ),
    );
  }
  Widget _buildCard(String title, IconData icon, Color color, Widget child) {
    return Container(margin: const EdgeInsets.only(bottom: 20), padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.1))), child: Column(children: [Row(children: [Icon(icon, color: color), const SizedBox(width: 10), Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color))]), const SizedBox(height: 16), child]));
  }
  Widget _buildField(TextEditingController c, String l, IconData i, {bool isNum = false}) => TextFormField(controller: c, keyboardType: isNum ? TextInputType.number : TextInputType.text, decoration: InputDecoration(labelText: l, prefixIcon: Icon(i, size: 18), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: Colors.grey.shade50), validator: (v) => v!.isEmpty ? "Required" : null);

  Widget _buildTimePicker(String label, TimeOfDay? time, Function(TimeOfDay) onSelect) {
    return InkWell(
      onTap: () async { final t = await showTimePicker(context: context, initialTime: time ?? TimeOfDay.now()); if (t != null) onSelect(t); },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(color: Colors.grey)), Text(time?.format(context) ?? "Select", style: const TextStyle(fontWeight: FontWeight.bold))]),
      ),
    );
  }
}