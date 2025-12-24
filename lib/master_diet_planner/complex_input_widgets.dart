import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Constants moved from main sheet
const List<String> _timeUnits = ['Day', 'Week', 'Month'];
const List<String> _durationUnits = ['years', 'months'];
const List<String> _frequencyOptions = [
  'Once a Day',
  'Twice a Day',
  'Thrice a Day',
  'Once a Week',
  'Twice a Week',
  'As Needed (PRN)',
];

// --- Utility Mixin ---

mixin DetailParser {
  (String, String) parseValueAndUnit(String detail, List<String> availableUnits) {
    if (detail.isEmpty || detail == 'Not specified') return ('', availableUnits.first);
    final parts = detail.split(RegExp(r'[\s]')).where((s) => s.isNotEmpty).toList();
    if (parts.length >= 2 && double.tryParse(parts.first) != null && availableUnits.contains(parts.last)) {
      return (parts.first, parts.last);
    }
    return ('', availableUnits.first);
  }

  (String, String) parseMedicationDetail(String detail) {
    if (detail.isEmpty || detail == 'Not specified') {
      return ('', _frequencyOptions.first);
    }
    final parts = detail.split(',').map((s) => s.trim()).toList();
    final dosage = parts.first;
    final frequency = parts.length > 1 && _frequencyOptions.contains(parts[1]) ? parts[1] : _frequencyOptions.first;
    return (dosage, frequency);
  }
}

// --- ISOLATED INPUT WIDGETS ---

// 1. Medical Condition Duration Input
class MedicalDurationInput extends ConsumerStatefulWidget {
  final String condition;
  final String initialDetail;
  final Function(Map<String, String>) onChanged;
  final VoidCallback? onDelete; // 🎯 FIX: Made nullable

  const MedicalDurationInput({
    required Key key,
    required this.condition,
    required this.initialDetail,
    required this.onChanged,
    this.onDelete, // 🎯 FIX: Not required
  }) : super(key: key);

  @override
  _MedicalDurationInputState createState() => _MedicalDurationInputState();
}

class _MedicalDurationInputState extends ConsumerState<MedicalDurationInput> with DetailParser {
  late TextEditingController _controller;
  late String _unit;

  @override
  void initState() {
    super.initState();
    final (value, unit) = parseValueAndUnit(widget.initialDetail, _durationUnits);
    _controller = TextEditingController(text: value);
    _unit = unit;
    _controller.addListener(_updateParent);
  }

  @override
  void dispose() {
    _controller.removeListener(_updateParent);
    _controller.dispose();
    super.dispose();
  }

  void _updateParent() {
    final number = _controller.text.trim();
    if (number.isNotEmpty && double.tryParse(number) != null) {
      widget.onChanged({widget.condition: '$number $_unit'});
    } else if (number.isEmpty) {
      widget.onChanged({widget.condition: 'Not specified'});
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🎯 Note: Chip handles null onDeleted by hiding the icon automatically
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade300)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Chip(
              label: Text(widget.condition, style: const TextStyle(fontWeight: FontWeight.bold)),
              onDeleted: widget.onDelete, // Null safe
              deleteIcon: const Icon(Icons.close, size: 18),
              backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
            ),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: TextFormField(controller: _controller, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Duration (Number)', isDense: true, border: OutlineInputBorder()), validator: (v) => (_controller.text.isNotEmpty && double.tryParse(v ?? '') == null) ? 'Invalid number' : null)),
            const SizedBox(width: 8),
            Container(padding: const EdgeInsets.symmetric(horizontal: 8), decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(5)), child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: _unit, items: _durationUnits.map((unit) => DropdownMenuItem(value: unit, child: Text(unit))).toList(), onChanged: (String? newValue) { if (newValue != null) { setState(() { _unit = newValue; _updateParent(); }); } }))),
          ]),
        ]),
      ),
    );
  }
}

// 2. Medication Dosage/Frequency Input
class MedicationDosageInput extends ConsumerStatefulWidget {
  final String medication;
  final String initialDetail;
  final Function(Map<String, String>) onChanged;
  final VoidCallback? onDelete; // 🎯 FIX: Made nullable

  const MedicationDosageInput({
    required Key key,
    required this.medication,
    required this.initialDetail,
    required this.onChanged,
    this.onDelete, // 🎯 FIX: Not required
  }) : super(key: key);

  @override
  _MedicationDosageInputState createState() => _MedicationDosageInputState();
}

class _MedicationDosageInputState extends ConsumerState<MedicationDosageInput> with DetailParser {
  late TextEditingController _controller;
  late String _frequency;

  @override
  void initState() {
    super.initState();
    final (dosage, frequency) = parseMedicationDetail(widget.initialDetail);
    _controller = TextEditingController(text: dosage);
    _frequency = frequency;
    _controller.addListener(_updateParent);
  }

  @override
  void dispose() {
    _controller.removeListener(_updateParent);
    _controller.dispose();
    super.dispose();
  }

  void _updateParent() {
    widget.onChanged({widget.medication: '${_controller.text.trim()}, $_frequency'});
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade300)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Chip(
            label: Text(widget.medication, style: const TextStyle(fontWeight: FontWeight.bold)),
            onDeleted: widget.onDelete, // Null safe
            deleteIcon: const Icon(Icons.close, size: 18),
            backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
          ),
          const SizedBox(height: 8),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(flex: 3, child: TextFormField(controller: _controller, decoration: const InputDecoration(labelText: 'Dosage (e.g., 500mg)', isDense: true, border: OutlineInputBorder()), validator: (v) => (v == null || v.isEmpty) ? 'Required' : null)),
            const SizedBox(width: 8),
            Expanded(flex: 2, child: DropdownButtonFormField<String>(value: _frequency, items: _frequencyOptions.map((freq) => DropdownMenuItem(value: freq, child: Text(freq))).toList(), onChanged: (v) { if (v != null) { setState(() { _frequency = v; _updateParent(); }); } }, decoration: const InputDecoration(labelText: 'Frequency', isDense: true, border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12)))),
          ]),
        ]),
      ),
    );
  }
}

// 3. GI Details Input
class GIDetailInput extends ConsumerStatefulWidget {
  final String detail;
  final String initialDetail;
  final Function(Map<String, String>) onChanged;
  final VoidCallback? onDelete; // 🎯 FIX

  const GIDetailInput({
    required Key key,
    required this.detail,
    required this.initialDetail,
    required this.onChanged,
    this.onDelete, // 🎯 FIX
  }) : super(key: key);

  @override
  _GIDetailInputState createState() => _GIDetailInputState();
}

class _GIDetailInputState extends ConsumerState<GIDetailInput> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialDetail == 'Not specified' ? '' : widget.initialDetail);
    _controller.addListener(_updateParent);
  }

  @override
  void dispose() {
    _controller.removeListener(_updateParent);
    _controller.dispose();
    super.dispose();
  }

  void _updateParent() {
    final detail = _controller.text.trim();
    widget.onChanged({widget.detail: detail.isEmpty ? 'Not specified' : detail});
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade300)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Chip(
            label: Text(widget.detail, style: const TextStyle(fontWeight: FontWeight.bold)),
            onDeleted: widget.onDelete, // Null safe
            deleteIcon: const Icon(Icons.close, size: 18),
            backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
          ),
          const SizedBox(height: 8),
          TextFormField(controller: _controller, decoration: const InputDecoration(labelText: 'Details/Severity (Optional)', isDense: true, border: OutlineInputBorder())),
        ]),
      ),
    );
  }
}

// 4. Caffeine Input
class CaffeineInput extends ConsumerStatefulWidget {
  final String source;
  final String initialDetail;
  final Function(Map<String, String>) onChanged;
  final VoidCallback? onDelete; // 🎯 FIX

  const CaffeineInput({
    required Key key,
    required this.source,
    required this.initialDetail,
    required this.onChanged,
    this.onDelete, // 🎯 FIX
  }) : super(key: key);

  @override
  _CaffeineInputState createState() => _CaffeineInputState();
}

class _CaffeineInputState extends ConsumerState<CaffeineInput> with DetailParser {
  late TextEditingController _controller;
  late String _unit;

  @override
  void initState() {
    super.initState();
    final (value, unit) = parseValueAndUnit(widget.initialDetail, _timeUnits);
    _controller = TextEditingController(text: value);
    _unit = unit;
    _controller.addListener(_updateParent);
  }

  @override
  void dispose() {
    _controller.removeListener(_updateParent);
    _controller.dispose();
    super.dispose();
  }

  void _updateParent() {
    final quantity = _controller.text.trim();
    if (quantity.isNotEmpty && double.tryParse(quantity) != null) {
      widget.onChanged({widget.source: '$quantity per $_unit'});
    } else if (quantity.isEmpty) {
      widget.onChanged({widget.source: 'Not specified'});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade300)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Chip(
            label: Text(widget.source, style: const TextStyle(fontWeight: FontWeight.bold)),
            onDeleted: widget.onDelete, // Null safe
            deleteIcon: const Icon(Icons.close, size: 18),
            backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
          ),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: TextFormField(controller: _controller, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quantity', isDense: true, border: OutlineInputBorder()), validator: (v) => (_controller.text.isNotEmpty && double.tryParse(v ?? '') == null) ? 'Num. Required' : null)),
            const SizedBox(width: 8),
            Container(padding: const EdgeInsets.symmetric(horizontal: 8), decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(5)), child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: _unit, items: _timeUnits.map((unit) => DropdownMenuItem(value: unit, child: Text(unit))).toList(), onChanged: (String? newValue) { if (newValue != null) { setState(() { _unit = newValue; _updateParent(); }); } }))),
          ]),
        ]),
      ),
    );
  }
}

// 5. Habit Frequency Input
class HabitFrequencyInput extends StatefulWidget {
  final String habit;
  final String initialDetail;
  final ValueChanged<Map<String, String>> onChanged;
  final VoidCallback? onDelete; // 🎯 FIX

  const HabitFrequencyInput({
    super.key,
    required this.habit,
    required this.initialDetail,
    required this.onChanged,
    this.onDelete, // 🎯 FIX
  });

  @override
  State<HabitFrequencyInput> createState() => _HabitFrequencyInputState();
}

class _HabitFrequencyInputState extends State<HabitFrequencyInput> {
  final TextEditingController _countController = TextEditingController();
  String _frequencyUnit = 'Day';
  final List<String> _units = ['Day', 'Week', 'Month'];

  @override
  void initState() {
    super.initState();
    _parseInitialDetail(widget.initialDetail);
  }

  void _parseInitialDetail(String detail) {
    if (detail.isNotEmpty) {
      final parts = detail.split('|');
      if (parts.length == 2) {
        _countController.text = parts[0];
        _frequencyUnit = _units.contains(parts[1]) ? parts[1] : 'Day';
      } else {
        _countController.text = '1';
        _frequencyUnit = 'Day';
      }
    } else {
      _countController.text = '1';
      _frequencyUnit = 'Day';
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateParent());
  }

  void _updateParent() {
    final count = int.tryParse(_countController.text) ?? 0;
    if(count > 0){
      widget.onChanged({widget.habit: '$count|$_frequencyUnit'});
    }
  }

  @override
  void dispose() {
    _countController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(widget.habit, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)))),
              // 🎯 FIX: Check for null before showing button
              if (widget.onDelete != null)
                IconButton(icon: const Icon(Icons.close, size: 20, color: Colors.red), onPressed: widget.onDelete),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade300)),
            child: Row(
              children: [
                Expanded(flex: 3, child: TextFormField(controller: _countController, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: const InputDecoration(labelText: 'Count', border: InputBorder.none, contentPadding: EdgeInsets.zero), onChanged: (_) => _updateParent())),
                const SizedBox(width: 10),
                const Text("times per"),
                const SizedBox(width: 10),
                Expanded(flex: 2, child: DropdownButtonFormField<String>(value: _frequencyUnit, items: _units.map((unit) => DropdownMenuItem(value: unit, child: Text(unit))).toList(), decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 0)), onChanged: (v) { setState(() => _frequencyUnit = v!); _updateParent(); })),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 6. Complaint Detail Input
class ComplaintDetailInput extends ConsumerStatefulWidget {
  final String complaint;
  final String initialDetail;
  final Function(Map<String, String>) onChanged;
  final VoidCallback? onDelete; // 🎯 FIX

  const ComplaintDetailInput({
    required Key key,
    required this.complaint,
    required this.initialDetail,
    required this.onChanged,
    this.onDelete, // 🎯 FIX
  }) : super(key: key);

  @override
  _ComplaintDetailInputState createState() => _ComplaintDetailInputState();
}

class _ComplaintDetailInputState extends ConsumerState<ComplaintDetailInput> {
  late TextEditingController _controller;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initialDetail != 'Not specified' && widget.initialDetail.isNotEmpty;
    _controller = TextEditingController(text: widget.initialDetail == 'Not specified' ? '' : widget.initialDetail);
    _controller.addListener(_updateParent);
  }

  @override
  void dispose() {
    _controller.removeListener(_updateParent);
    _controller.dispose();
    super.dispose();
  }

  void _updateParent() {
    final detail = _controller.text.trim();
    widget.onChanged({widget.complaint: detail.isEmpty ? 'Not specified' : detail});
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.purple.shade200)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
              Chip(
                label: Text(widget.complaint, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                onDeleted: widget.onDelete, // Null safe
                deleteIcon: const Icon(Icons.close, size: 18),
                backgroundColor: Colors.purple.shade100.withOpacity(0.5),
              ),
              if (!_isExpanded && widget.onDelete != null) // Only show Add if editable
                Padding(padding: const EdgeInsets.only(left: 8.0), child: TextButton.icon(icon: const Icon(Icons.add, size: 16), label: const Text("Add Details", style: TextStyle(fontSize: 12)), onPressed: () => setState(() => _isExpanded = true))),
            ])),
            if (_isExpanded && widget.onDelete != null)
              IconButton(icon: const Icon(Icons.remove_circle_outline, size: 20, color: Colors.grey), tooltip: "Hide Details", onPressed: () { _controller.clear(); setState(() => _isExpanded = false); }),
          ]),
          if (_isExpanded) ...[
            const SizedBox(height: 8),
            TextFormField(controller: _controller, decoration: const InputDecoration(labelText: 'Detail, Duration, or Severity', isDense: true, border: OutlineInputBorder(), fillColor: Colors.white, filled: true), maxLines: 2),
          ],
        ]),
      ),
    );
  }
}

// 7. Nutrition Diagnosis Input
class DiagnosisDetailInput extends ConsumerStatefulWidget {
  final String diagnosis;
  final String initialDetail;
  final Function(Map<String, String>) onChanged;
  final VoidCallback? onDelete; // 🎯 FIX

  const DiagnosisDetailInput({
    required Key key,
    required this.diagnosis,
    required this.initialDetail,
    required this.onChanged,
    this.onDelete, // 🎯 FIX
  }) : super(key: key);

  @override
  _DiagnosisDetailInputState createState() => _DiagnosisDetailInputState();
}

class _DiagnosisDetailInputState extends ConsumerState<DiagnosisDetailInput> {
  late TextEditingController _controller;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initialDetail != 'Not specified' && widget.initialDetail.isNotEmpty;
    _controller = TextEditingController(text: widget.initialDetail == 'Not specified' ? '' : widget.initialDetail);
    _controller.addListener(_updateParent);
  }

  @override
  void dispose() {
    _controller.removeListener(_updateParent);
    _controller.dispose();
    super.dispose();
  }

  void _updateParent() {
    final detail = _controller.text.trim();
    widget.onChanged({widget.diagnosis: detail.isEmpty ? 'Not specified' : detail});
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.purple.shade200)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
              Chip(
                label: Text(widget.diagnosis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                onDeleted: widget.onDelete, // Null safe
                deleteIcon: const Icon(Icons.close, size: 18),
                backgroundColor: Colors.purple.shade100.withOpacity(0.5),
              ),
              if (!_isExpanded && widget.onDelete != null)
                Padding(padding: const EdgeInsets.only(left: 8.0), child: TextButton.icon(icon: const Icon(Icons.add, size: 16), label: const Text("Add Etiology", style: TextStyle(fontSize: 12)), onPressed: () => setState(() => _isExpanded = true))),
            ])),
            if (_isExpanded && widget.onDelete != null)
              IconButton(icon: const Icon(Icons.remove_circle_outline, size: 20, color: Colors.grey), tooltip: "Hide Etiology", onPressed: () { _controller.clear(); setState(() => _isExpanded = false); }),
          ]),
          if (_isExpanded) ...[
            const SizedBox(height: 8),
            TextFormField(controller: _controller, decoration: const InputDecoration(labelText: 'Related Factor / Etiology', isDense: true, border: OutlineInputBorder(), fillColor: Colors.white, filled: true), maxLines: 3),
          ],
        ]),
      ),
    );
  }
}

// 8. Note Category Input
class NoteCategoryInput extends ConsumerStatefulWidget {
  final String category;
  final TextEditingController controller;
  final Function(String, String) onChanged;
  final VoidCallback? onDelete; // 🎯 FIX

  const NoteCategoryInput({
    required Key key,
    required this.category,
    required this.controller,
    required this.onChanged,
    this.onDelete, // 🎯 FIX
  }) : super(key: key);

  @override
  _NoteCategoryInputState createState() => _NoteCategoryInputState();
}

class _NoteCategoryInputState extends ConsumerState<NoteCategoryInput> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.blueGrey.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.blueGrey.shade200)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(widget.category.toUpperCase(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.blueGrey)),
            // 🎯 FIX: Check for null
            if (widget.onDelete != null)
              IconButton(icon: const Icon(Icons.close, size: 18, color: Colors.blueGrey), onPressed: widget.onDelete, tooltip: 'Remove Note Section'),
          ]),
          const Divider(height: 10, thickness: 1),
          TextFormField(
            controller: widget.controller,
            onChanged: (v) => widget.onChanged(widget.category, v),
            decoration: InputDecoration(labelText: 'Enter ${widget.category} details', isDense: true, border: const OutlineInputBorder(), fillColor: Colors.white, filled: true),
            minLines: 4,
            maxLines: 6,
          ),
        ]),
      ),
    );
  }
}